resource "aws_ses_email_identity" "my-email-identity-tf" {
  email = var.my_email
}

data "aws_iam_policy_document" "send-email-policy-tf" {
  statement {
    actions = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_email_identity.my-email-identity-tf.arn]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_ses_identity_policy" "ses-identity-policy-tf" {
  identity = aws_ses_email_identity.my-email-identity-tf.arn
  name = "EC2-SES-policy-tf"
  policy   = data.aws_iam_policy_document.send-email-policy-tf.json
}

resource "aws_s3_bucket" "log-bucket-tf" {
  bucket = "log-bucket-tf"
  acl = "private"
}

resource "aws_iam_role" "ses-firehose-role-tf" {
  name = "ses-firehose-role-tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ses-firehose-policy-tf" {
  name = "ses-firehose-policy-tf"
  role = aws_iam_role.ses-firehose-role-tf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "GiveSESPermissionToPutFirehose",
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [aws_s3_bucket.log-bucket-tf.arn, "${aws_s3_bucket.log-bucket-tf.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role" "ec2-ses-role-tf" {
  name = "ec2-ses-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ec2-ses-policy-tf" {
  name = "ec2-ses-policy-tf"
  role = aws_iam_role.ec2-ses-role-tf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "GiveSESPermissionToPutFirehose",
        Effect = "Allow",
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Resource = aws_ses_email_identity.my-email-identity-tf.arn
      }
    ]
  })
}

resource "aws_iam_role" "ses-firehose-cs-role-tf" {
  name = "ses-firehose-cs-role-tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ses.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ses-firehose-cs-policy-tf" {
  name = "ses-firehose-cs-policy-tf"
  role = aws_iam_role.ses-firehose-cs-role-tf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "",
        Effect = "Allow",
        Action = [
            "firehose:PutRecord",
            "firehose:PutRecordBatch"
        ],
        Resource = aws_kinesis_firehose_delivery_stream.ses-firehose-delivery-stream-tf.arn
      }
    ]
  })
}

resource "time_sleep" "wait_2_mins" { # new assume role policy requires time to be usable
  depends_on = [aws_kinesis_firehose_delivery_stream.ses-firehose-delivery-stream-tf]

  create_duration = "2m"
}

resource "aws_kinesis_firehose_delivery_stream" "ses-firehose-delivery-stream-tf" {
  name = "ses-firehose-delivery-stream-tf"
  destination = "s3"

  s3_configuration {
    role_arn = aws_iam_role.ses-firehose-role-tf.arn
    bucket_arn = aws_s3_bucket.log-bucket-tf.arn
    buffer_interval = 60
    buffer_size = 1
  }
}

resource "aws_ses_configuration_set" "ses-configuration-tf" {
  name = "ses-configuration-tf"
}

resource "aws_ses_event_destination" "ses-kinesis-tf" {
  name = "ses-kinesis-tf"
  configuration_set_name = aws_ses_configuration_set.ses-configuration-tf.name
  enabled = true
  matching_types = ["send", "reject", "bounce", "complaint", "delivery"]

  kinesis_destination {
    stream_arn = aws_kinesis_firehose_delivery_stream.ses-firehose-delivery-stream-tf.arn
    role_arn = aws_iam_role.ses-firehose-cs-role-tf.arn
  }

  depends_on = [time_sleep.wait_2_mins]
}

resource "aws_iam_access_key" "s3-logs-read-key-tf" {
  user    = aws_iam_user.s3-logs-read-service-account-tf.name
}

resource "aws_iam_user" "s3-logs-read-service-account-tf" {
  name = "s3-logs-read-service-account-tf"
}

resource "aws_iam_user_policy" "s3-logs-read-policy-tf" {
  name = "test"
  user = aws_iam_user.s3-logs-read-service-account-tf.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "",
        Effect = "Allow",
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [aws_s3_bucket.log-bucket-tf.arn, "${aws_s3_bucket.log-bucket-tf.arn}/*"]
      }
    ]
  })
}

# output "log_user_access_key" {
#   value = aws_iam_access_key.s3-logs-read-key-tf.id
# }
#
# output "log_user_secret" {
#   value = aws_iam_access_key.s3-logs-read-key-tf.secret
# }
output "log_bucket_name" {
  value = aws_s3_bucket.log-bucket-tf.bucket
}
