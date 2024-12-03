resource "aws_s3_bucket" "nops_container_cost" {
  bucket = "nops-container-cost-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nops_bucket_encryption" {
  bucket = aws_s3_bucket.nops_container_cost.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nops_bucket_block_public_access" {
  bucket = aws_s3_bucket.nops_container_cost.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "nops_bucket_deny_insecure_transport" {
  bucket = aws_s3_bucket.nops_container_cost.id
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.nops_container_cost.arn,
          "${aws_s3_bucket.nops_container_cost.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
