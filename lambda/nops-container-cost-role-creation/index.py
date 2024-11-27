import boto3
import json
import cfnresponse
import os
import http.client
from urllib.parse import urlparse

CLOUDFORMATION_VERSION = "{CLOUDFORMATION_VERSION}"


def send_onboarding_confirmation(cluster_arns):
    env = os.environ.get('Env', 'PROD')
    base_url = "https://app.nops.io/svc/karpenter_manager" if env == "PROD" else "https://uat.nops.io/svc/karpenter_manager"
    url = f"{base_url}/agents/cloudformation/onboarding-confirmation"

    # Parse URL to extract components for HTTP connection
    parsed_url = urlparse(url)
    host = parsed_url.netloc
    path = parsed_url.path

    # Prepare payload and headers
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
        "X-Nops-Api-Key": token if token else ""
    }

    # Select connection type based on URL scheme
    connection = http.client.HTTPSConnection(host) if parsed_url.scheme == "https" else http.client.HTTPConnection(host)

    try:
        # Send POST request
        connection.request("POST", path, body=payload, headers=headers)

        # Get and check the response
        response = connection.getresponse()
        if response.status == 200:
            print("Onboarding confirmation sent successfully.")
        else:
            print(f"Failed to send onboarding confirmation. Status code: {response.status}, reason: {response.reason}")

        # Optionally, read the response data if needed
        response_data = response.read()
        print(response_data.decode('utf-8'))

    except http.client.HTTPException as e:
        print(f"HTTP error occurred: {e}")
    finally:
        connection.close()


def lambda_handler(event, context):
    response_data = {}
    try:
        if event['RequestType'] in ['Create', 'Update']:
            cluster_arns = manage_iam_roles_for_all_clusters(event['RequestType'])
            if cluster_arns:
                send_onboarding_confirmation(cluster_arns)
        elif event['RequestType'] == 'Delete':
            delete_iam_roles()

        cfnresponse.send(event, context, cfnresponse.SUCCESS, response_data)
    except Exception as e:
        response_data['Error'] = str(e)
        cfnresponse.send(event, context, cfnresponse.FAILED, response_data)


def manage_iam_roles_for_all_clusters(request_type):
    eks = boto3.client('eks')
    iam = boto3.client('iam')
    sts = boto3.client('sts')

    env = os.environ.get('Env', 'PROD')
    nops_account = "202279780353" if env == "PROD" else "844856862745"
    account_id = sts.get_caller_identity()['Account']
    default_region = os.environ['AWS_REGION']
    default_regions = [default_region]
    included_regions = os.environ.get('IncludeRegions', '').split(',') if os.environ.get(
        'IncludeRegions') else default_regions
    print(included_regions)

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
    cluster_arns = []
    for region in included_regions:
        try:
            eks_client = boto3.client('eks', region_name=region)
            clusters = eks_client.list_clusters()['clusters']

            for cluster_name in clusters:
                try:
                    cluster_info = eks_client.describe_cluster(name=cluster_name)
                    oidc_id = cluster_info['cluster']['identity']['oidc']['issuer'].split('/')[-1]
                    role_name = f"nops-ccost-{cluster_name}_{region}"
                    oidc_arn = f"arn:aws:iam::{account_id}:oidc-provider/oidc.eks.{region}.amazonaws.com/id/{oidc_id}"

                    assume_role_policy = json.dumps({
                        "Version": "2012-10-17",
                        "Statement": [{
                            "Effect": "Allow",
                            "Principal": {"Federated": oidc_arn},
                            "Action": "sts:AssumeRoleWithWebIdentity",
                            "Condition": {"StringEquals": {
                                f"oidc.eks.{region}.amazonaws.com/id/{oidc_id}:sub": "system:serviceaccount:nops:nops-container-insights"}}
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

                    if request_type in ['Create', 'Update']:
                        create_or_update_role(iam, role_name, assume_role_policy, inline_policy, sqs_policy, region)
                    cluster_arns.append(cluster_info['cluster']['arn'])
                except Exception as e:
                    print(f"Error managing role for cluster {cluster_name} in region {region}: {str(e)}", exc_info=True)
        except Exception as e:
            print(f"Error managing roles in region {region}: {str(e)}", exc_info=True)
    return cluster_arns


def create_or_update_role(iam, role_name, assume_role_policy, inline_policy, sqs_policy, region):
    try:
        # Check if the role exists
        role = iam.get_role(RoleName=role_name)
        current_assume_role_policy = role['Role']['AssumeRolePolicyDocument']

        # Update the trust relationship if necessary
        for statement in current_assume_role_policy['Statement']:
            if 'Condition' in statement and 'StringEquals' in statement['Condition']:
                condition_key = list(statement['Condition']['StringEquals'].keys())[0]
                if statement['Condition']['StringEquals'][
                    condition_key] == 'system:serviceaccount:nops-k8s-agent:nops-k8s-agent':
                    statement['Condition']['StringEquals'][
                        condition_key] = 'system:serviceaccount:nops:nops-container-insights'
                    iam.update_assume_role_policy(RoleName=role_name,
                                                  PolicyDocument=json.dumps(current_assume_role_policy))
                    print(f"Updated trust relationship for role {role_name}.")

        # Update S3 inline policy
        iam.put_role_policy(RoleName=role_name, PolicyName='S3Policy', PolicyDocument=json.dumps(inline_policy))
        print(f"Updated role {role_name} with S3 policy.")

        # Check if SQSPolicy exists
        existing_policies = iam.list_role_policies(RoleName=role_name)['PolicyNames']
        if 'SQSPolicy' not in existing_policies:
            # Create and attach SQSPolicy if it doesn't exist
            iam.put_role_policy(RoleName=role_name, PolicyName='SQSPolicy', PolicyDocument=json.dumps(sqs_policy))
            print(f"Attached SQSPolicy to role {role_name}.")
        else:
            print(f"SQSPolicy already exists for role {role_name}.")

    except iam.exceptions.NoSuchEntityException:
        # Role does not exist, create it and attach policies
        iam.create_role(RoleName=role_name, AssumeRolePolicyDocument=assume_role_policy)
        iam.put_role_policy(RoleName=role_name, PolicyName='S3Policy', PolicyDocument=json.dumps(inline_policy))
        iam.put_role_policy(RoleName=role_name, PolicyName='SQSPolicy', PolicyDocument=json.dumps(sqs_policy))
        print(f"Created role {role_name} and attached S3 and SQS policies.")


def delete_iam_roles():
    iam = boto3.client('iam')

    # Use the IncludeRegions environment variable
    default_region = os.environ['AWS_REGION']
    default_regions = [default_region]
    included_regions = os.environ.get('IncludeRegions', '').split(',') if os.environ.get(
        'IncludeRegions') else default_regions

    # Deleting IAM roles with the "nops-ccost" suffix
    paginator = iam.get_paginator('list_roles')
    for page in paginator.paginate():
        for role in page['Roles']:
            if 'nops-ccost' in role['RoleName']:
                detach_all_policies(iam, role['RoleName'])
                delete_all_inline_policies(iam, role['RoleName'])
                iam.delete_role(RoleName=role['RoleName'])


def detach_all_policies(iam, role_name):
    # Detach all managed policies from the role
    attached_policies = iam.list_attached_role_policies(RoleName=role_name)['AttachedPolicies']
    for policy in attached_policies:
        iam.detach_role_policy(RoleName=role_name, PolicyArn=policy['PolicyArn'])


def delete_all_inline_policies(iam, role_name):
    # Delete all inline policies from the role
    inline_policies = iam.list_role_policies(RoleName=role_name)['PolicyNames']
    for policy_name in inline_policies:
        iam.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
