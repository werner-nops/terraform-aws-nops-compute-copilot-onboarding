import boto3
import json
import os
import re
import http.client
from urllib.parse import urlparse

CLOUDFORMATION_VERSION = "{CLOUDFORMATION_VERSION}"


def send_onboarding_confirmation(cluster_arns):
    env = os.environ.get('Env', 'PROD')
    base_url = "https://app.nops.io/svc/karpenter_manager" if env == "PROD" else "https://uat.nops.io/svc/karpenter_manager"
    url = f"{base_url}/agents/cloudformation/onboarding-confirmation"

    # Parse URL for host and path
    parsed_url = urlparse(url)
    host = parsed_url.netloc
    path = parsed_url.path

    # Prepare payload
    payload = json.dumps({
        "cluster_arns": cluster_arns,
        "cloudformation_version": CLOUDFORMATION_VERSION,
        "stack_id": os.environ.get('STACK_ID'),
        "stack_name": os.environ.get('STACK_NAME'),
        "region_name": os.environ.get('AWS_REGION')
    })

    token = os.environ.get('Token')
    headers = {
        "Content-Type": "application/json",
        "X-Nops-Api-Key": token if token else "",
    }

    # Select connection type (HTTPS or HTTP)
    connection = http.client.HTTPSConnection(host) if parsed_url.scheme == "https" else http.client.HTTPConnection(host)

    try:
        # Send POST request
        connection.request("POST", path, body=payload, headers=headers)

        # Get the response
        response = connection.getresponse()
        if response.status == 200:
            print("Onboarding confirmation sent successfully.")
        else:
            print(f"Failed to send onboarding confirmation. Status code: {response.status}, reason: {response.reason}")

        # Read response data if needed
        response_data = response.read()
        print(response_data.decode('utf-8'))

    except http.client.HTTPException as e:
        print(f"HTTP error occurred: {e}")
    finally:
        connection.close()


def lambda_handler(event, context):
    # Use the IncludeRegions environment variable
    env = os.environ.get('Env', 'PROD')
    nops_account = "202279780353" if env == "PROD" else "844856862745"
    default_region = os.environ['AWS_REGION']
    default_regions = [default_region]
    included_regions = os.environ.get('IncludeRegions', '').split(',') if os.environ.get(
        'IncludeRegions') else default_regions
    print(f"These are the included regions: {included_regions}")

    # Initialize the STS client to get the account ID
    account_id = os.environ.get('AccountId')

    # Initialize the boto3 clients
    iam_client = boto3.client('iam')

    sqs_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sqs:SendMessage",
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage"
                ],
                "Resource": [
                    f"arn:aws:sqs:us-west-2:{nops_account}:nops-k8s-*"
                ]
            }
        ]
    }

    # A set to keep track of the required roles
    required_roles = set()

    # Iterate through each included region to find EKS clusters
    for region in included_regions:
        regional_eks = boto3.client('eks', region_name=region)
        try:
            clusters = regional_eks.list_clusters()['clusters']
        except Exception as e:
            print(f"Error retrieving clusters for region {region}: {e}")
            continue

        # Prepare the required role names based on the cluster names
        for cluster_name in clusters:
            required_roles.add(f"nops-ccost-{cluster_name}_{region}")

    # List existing IAM roles
    existing_roles = set()
    paginator = iam_client.get_paginator('list_roles')
    for page in paginator.paginate():
        for role in page['Roles']:
            role_name = role['RoleName']
            if role_name.startswith("nops-ccost-"):
                existing_roles.add(role_name)

    # Define the regex pattern to extract cluster name and region
    pattern = re.compile(r"^nops-ccost-(.+)_(.+)$")

    # For each existing role, attach the SQSPolicy if it does not already exist
    for role_name in existing_roles:
        try:
            # Check if the SQSPolicy is already attached
            existing_policies = iam_client.list_role_policies(RoleName=role_name)['PolicyNames']
            if 'SQSPolicy' not in existing_policies:
                # Attach the SQSPolicy
                iam_client.put_role_policy(
                    RoleName=role_name,
                    PolicyName='SQSPolicy',
                    PolicyDocument=json.dumps(sqs_policy)
                )
                print(f"Attached SQSPolicy to role {role_name}.")
            else:
                print(f"SQSPolicy already exists for role {role_name}.")
        except Exception as e:
            print(f"Error checking or attaching SQSPolicy for role {role_name}: {e}")

    # Process for creating new roles (missing roles)
    missing_roles = required_roles - existing_roles
    cluster_arns = []
    for role_name in missing_roles:
        try:
            # Use regex to match and capture cluster name and region
            match = pattern.match(role_name)
            if not match:
                print(f"Skipping malformed role name: {role_name}")
                continue

            cluster_name, region_to_use = match.groups()
            print(f"Creating role for cluster: {cluster_name} in region: {region_to_use}")

            # Validate the region against AWS known region names
            all_regions = [region_info['RegionName'] for region_info in
                           boto3.client('ec2').describe_regions()['Regions']]
            if region_to_use not in all_regions:
                print(f"Skipping unknown region: {region_to_use}")
                continue

            # Initialize the regional EKS client
            regional_eks = boto3.client('eks', region_name=region_to_use)
            cluster_info = regional_eks.describe_cluster(name=cluster_name)['cluster']

            oidc_issuer = cluster_info.get('identity', {}).get('oidc', {}).get('issuer')
            if oidc_issuer:
                # Extract the last segment of the OIDC URL to form the correct ARN
                oidc_id = oidc_issuer.split('/')[-1]
                oidc_arn = f"arn:aws:iam::{account_id}:oidc-provider/oidc.eks.{region_to_use}.amazonaws.com/id/{oidc_id}"

                # Construct the trust relationship document
                assume_role_policy = json.dumps({
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Effect": "Allow",
                        "Principal": {"Federated": oidc_arn},
                        "Action": "sts:AssumeRoleWithWebIdentity",
                        "Condition": {"StringEquals": {
                            f"oidc.eks.{region_to_use}.amazonaws.com/id/{oidc_id}:sub": "system:serviceaccount:nops:nops-container-insights"}}
                    }]
                })

                inline_policy = {
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Effect": "Allow",
                        "Action": [
                            "s3:PutObject",
                            "s3:GetObject",
                            "s3:ListBucket"
                        ],
                        "Resource": [
                            f"arn:aws:s3:::nops-container-cost-{account_id}",
                            f"arn:aws:s3:::nops-container-cost-{account_id}/*"
                        ]
                    }]
                }

                # Create the IAM role and attach the policies
                iam_client.create_role(
                    RoleName=role_name,
                    AssumeRolePolicyDocument=assume_role_policy
                )
                iam_client.put_role_policy(
                    RoleName=role_name,
                    PolicyName='S3Policy',
                    PolicyDocument=json.dumps(inline_policy)
                )
                iam_client.put_role_policy(
                    RoleName=role_name,
                    PolicyName='SQSPolicy',
                    PolicyDocument=json.dumps(sqs_policy)
                )
                print(f"Created role {role_name} with S3 and SQS policies.")
                cluster_arns.append(cluster_info['arn'])
        except Exception as e:
            print(f"Error creating role {role_name}: {e}")
    if cluster_arns:
        send_onboarding_confirmation(cluster_arns)
