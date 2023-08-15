terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

# specify the provider region
provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "lambda" {
  bucket = "lotionapp-st"
}

# output the name of the bucket after creation
output "bucket_name" {
  value = aws_s3_bucket.lambda.bucket
}


# the locals block is used to declare constants that 
# you can use throughout your code
locals {
  function_name        = "save-note-30145085"
  handler_name         = "main.lambda_handler"
  artifact_name        = "artifact.zip"
  get_function_name    = "get-note-30145085"
  get_handler_name     = "main.lambda_handler2"
  get_artifact_name    = "getartifact.zip"
  delete_function_name = "delete-note-30145085"
  delete_handler_name  = "main.lambda_handler3"
  delete_artifact_name = "deleteartifact.zip"
}

# create a role for the Lambda function to assume
# every service on AWS that wants to call other AWS services should first assume a role and
# then any policy attached to the role will give permissions
# to the service so it can interact with other AWS services
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda" {
  name               = "iam-for-lambda-${local.function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "get_lambda" {
  name               = "iam-for-lambda-${local.get_function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "delete_lambda" {
  name               = "iam-for-lambda-${local.delete_function_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# create archive file from main.py
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../functions/save-note/main.py"
  output_path = "artifact.zip"
}

data "archive_file" "get_lambda" {
  type        = "zip"
  source_file = "../functions/get-notes/main.py"
  output_path = "getartifact.zip"
}

data "archive_file" "delete_lambda" {
  type        = "zip"
  source_file = "../functions/delete-note/main.py"
  output_path = "deleteartifact.zip"
}

# create a Lambda function
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "lambda" {
  role             = aws_iam_role.lambda.arn
  function_name    = local.function_name
  handler          = local.handler_name
  filename         = local.artifact_name
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
}

resource "aws_lambda_function" "get_lambda" {
  role             = aws_iam_role.get_lambda.arn
  function_name    = local.get_function_name
  handler          = local.get_handler_name
  filename         = local.get_artifact_name
  source_code_hash = data.archive_file.get_lambda.output_base64sha256
  runtime          = "python3.9"
}

resource "aws_lambda_function" "delete_lambda" {
  role             = aws_iam_role.delete_lambda.arn
  function_name    = local.delete_function_name
  handler          = local.delete_handler_name
  filename         = local.delete_artifact_name
  source_code_hash = data.archive_file.delete_lambda.output_base64sha256
  runtime          = "python3.9"
}

# create a policy for publishing logs to CloudWatch
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "logs" {
  name        = "lambda-logging-${local.function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:PutItem"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.lotion-30142184.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get_logs" {
  name        = "lambda-logging-${local.get_function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:Query"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.lotion-30142184.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "delete_logs" {
  name        = "lambda-logging-${local.delete_function_name}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:DeleteItem"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.lotion-30142184.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

# attach the above policy to the function role
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.logs.arn
}

resource "aws_iam_role_policy_attachment" "get_lambda_logs" {
  role       = aws_iam_role.get_lambda.name
  policy_arn = aws_iam_policy.get_logs.arn
}

resource "aws_iam_role_policy_attachment" "delete_lambda_logs" {
  role       = aws_iam_role.delete_lambda.name
  policy_arn = aws_iam_policy.delete_logs.arn
}

# create a Function URL for Lambda 
# see the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url
resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "get_url" {
  function_name      = aws_lambda_function.get_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "delete_url" {
  function_name      = aws_lambda_function.delete_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

# show the Function URL after creation
output "lambda_url" {
  value = aws_lambda_function_url.url.function_url
}

output "get_lambda_url" {
  value = aws_lambda_function_url.get_url.function_url
}

output "delete_lambda_url" {
  value = aws_lambda_function_url.delete_url.function_url
}

# read the docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "lotion-30142184" {
  name         = "lotion-30142184"
  billing_mode = "PROVISIONED"

  # up to 8KB read per second (eventually consistent)
  read_capacity = 1

  # up to 1KB per second
  write_capacity = 1

  hash_key  = "email"
  range_key = "id"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }
}