terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
# DynamoDB
resource "aws_dynamodb_table" "users" {
  name           = "users"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "Name"
  attribute {
    name = "UserId"
    type = "S"
  }
  attribute {
    name = "Name"
    type = "S"
  }
  attribute {
    name = "Age"
    type = "S"
  }
  global_secondary_index {
    name               = "AgeIndex"
    hash_key           = "UserId"
    range_key          = "Age"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["Name"]
  }
}
# Lambda Functions
# Role and Policy Defination
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
# Custom Boto3 layer
# Add Function
data "archive_file" "add" {
  type        = "zip"
  source_file = "add.py"
  output_path = "lambda_function_add.zip"
}
resource "aws_lambda_function" "add" {
  filename      = "lambda_function_add.zip"
  function_name = "add"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "add.lambda_handler"
  source_code_hash = data.archive_file.add.output_base64sha256
  runtime = "python3.12"
  layers = [var.boto3layer]
}
# Delete Function
data "archive_file" "delete" {
  type        = "zip"
  source_file = "delete.py"
  output_path = "lambda_function_delete.zip"
}
resource "aws_lambda_function" "delete" {
  filename      = "lambda_function_delete.zip"
  function_name = "delete"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "delete.lambda_handler"
  source_code_hash = data.archive_file.delete.output_base64sha256
  runtime = "python3.12"
  layers = [var.boto3layer]
}
# Get Function
data "archive_file" "get" {
  type        = "zip"
  source_file = "get.py"
  output_path = "lambda_function_get.zip"
}
resource "aws_lambda_function" "get" {
  filename      = "lambda_function_get.zip"
  function_name = "get"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "get.lambda_handler"
  source_code_hash = data.archive_file.get.output_base64sha256
  runtime = "python3.12"
  layers = [var.boto3layer]
}
# Update Function
data "archive_file" "update" {
  type        = "zip"
  source_file = "update.py"
  output_path = "lambda_function_update.zip"
}
resource "aws_lambda_function" "update" {
  filename      = "lambda_function_update.zip"
  function_name = "update"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "update.lambda_handler"
  source_code_hash = data.archive_file.update.output_base64sha256
  runtime = "python3.12"
  layers = [var.boto3layer]
}
# API Gateway
resource "aws_api_gateway_rest_api" "userapi" {
  name = "userapi"
}
# Lambda Permissions for Gateway
resource "aws_lambda_permission" "add_gw_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-west-2:992382387916:${aws_api_gateway_rest_api.userapi.id}/*"
}
resource "aws_lambda_permission" "get_gw_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-west-2:992382387916:${aws_api_gateway_rest_api.userapi.id}/*"
}
resource "aws_lambda_permission" "delete_gw_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-west-2:992382387916:${aws_api_gateway_rest_api.userapi.id}/*"
}
resource "aws_lambda_permission" "update_gw_permissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-west-2:992382387916:${aws_api_gateway_rest_api.userapi.id}/*"
}
# Get Function API
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  parent_id   = aws_api_gateway_rest_api.userapi.root_resource_id
  path_part   = "user"
}
resource "aws_api_gateway_method" "get_user" {
  rest_api_id   = aws_api_gateway_rest_api.userapi.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.userId" = true
  }
}
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  resource_id = aws_api_gateway_method.get_user.resource_id
  http_method = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get.invoke_arn
  request_parameters = {
    "integration.request.querystring.userId" = "method.request.querystring.userId"
  }
}
# Add Function API
resource "aws_api_gateway_resource" "add" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  parent_id   = aws_api_gateway_rest_api.userapi.root_resource_id
  path_part   = "add"
}
resource "aws_api_gateway_method" "add_user" {
  rest_api_id   = aws_api_gateway_rest_api.userapi.id
  resource_id   = aws_api_gateway_resource.add.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.userId" = true
    "method.request.querystring.name" = true
    "method.request.querystring.age" = true
  }
}
resource "aws_api_gateway_integration" "add_integration" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  resource_id = aws_api_gateway_method.add_user.resource_id
  http_method = aws_api_gateway_method.add_user.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.add.invoke_arn
  request_parameters = {
    "integration.request.querystring.userId" = "method.request.querystring.userId"
    "integration.request.querystring.name" = "method.request.querystring.name"
    "integration.request.querystring.age" = "method.request.querystring.age"
  }
}
# Update Function API
resource "aws_api_gateway_resource" "update" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  parent_id   = aws_api_gateway_rest_api.userapi.root_resource_id
  path_part   = "update"
}
resource "aws_api_gateway_method" "update_user" {
  rest_api_id   = aws_api_gateway_rest_api.userapi.id
  resource_id   = aws_api_gateway_resource.update.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.userId" = true
    "method.request.querystring.name" = true
    "method.request.querystring.age" = true
  }
}
resource "aws_api_gateway_integration" "update_integration" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  resource_id = aws_api_gateway_method.update_user.resource_id
  http_method = aws_api_gateway_method.update_user.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.update.invoke_arn
  request_parameters = {
    "integration.request.querystring.userId" = "method.request.querystring.userId"
    "integration.request.querystring.name" = "method.request.querystring.name"
    "integration.request.querystring.age" = "method.request.querystring.age"
  }
}
# Delete Function API
resource "aws_api_gateway_resource" "delete" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  parent_id   = aws_api_gateway_rest_api.userapi.root_resource_id
  path_part   = "delete"
}
resource "aws_api_gateway_method" "delete_user" {
  rest_api_id   = aws_api_gateway_rest_api.userapi.id
  resource_id   = aws_api_gateway_resource.delete.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.userId" = true
  }
}
resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  resource_id = aws_api_gateway_method.delete_user.resource_id
  http_method = aws_api_gateway_method.delete_user.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.delete.invoke_arn
  request_parameters = {
    "integration.request.querystring.userId" = "method.request.querystring.userId"
  }
}
# Deploy API
resource "aws_api_gateway_deployment" "userAPI_deploy" {
  depends_on = [
    aws_api_gateway_integration.add_integration,
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.update_integration,
    aws_api_gateway_integration.delete_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.userapi.id
  stage_name  = "v1"
}
output "api_endpoint" {
  value = aws_api_gateway_deployment.userAPI_deploy.invoke_url
}