provider "aws" {
  region = "us-east-2"
}

variable "All_Variables" {
  type    = list(string)
  default = ["us-east-2", "9**********4", "Dev", "Deployed from terraform","arn:aws:s3:::product-visits-datalake-43001"]
}

data "archive_file" "lambda1-zip" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda.zip"
}


resource "aws_iam_role" "lambdaRoleForSQSPermissions" {
  name = "productVisitsSendMessageLambdaRole_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}
resource "aws_iam_role_policy_attachment" "productVisitsSendMessage_Policy_Attachment" {
  role       = aws_iam_role.lambdaRoleForSQSPermissions.name
  policy_arn = aws_iam_policy.productVisitsSendMessageLambdaPolicy.arn
}

resource "aws_iam_policy" "productVisitsSendMessageLambdaPolicy" {
  name        = "productVisitsSendMessageLambdaPolicy"
  path        = "/"
  description = "IAM policy for logging from a lambda and for send message to SQS"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          #"Resource": "arn:aws:logs:us-east-2:9**********4:*"
          "Resource" : join(":*", [join(":", [join("", ["arn:aws:logs:", var.All_Variables[0]]), var.All_Variables[1]]), ""]),
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : "sqs:SendMessage",
          #"Resource": "arn:aws:sqs:us-east-2:9**********4:ProductVisitsDataQueue"
          "Resource" : join(":", [join(":", [join("", ["arn:aws:sqs:", var.All_Variables[0]]), var.All_Variables[1]]), aws_sqs_queue.ProductVisitsDataQueue.name])
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}


resource "aws_sqs_queue" "ProductVisitsDataQueue" {
  name = "ProductVisitsDataQueue"

  tags = {
    Name = var.All_Variables[3]
  }
}
resource "aws_lambda_function" "productVisitsSendDataToQueue" {
  filename      = "lambda.zip"
  function_name = "productVisitsSendDataToQueue"
  role          = aws_iam_role.lambdaRoleForSQSPermissions.arn
  handler       = "productVisitsSendDataToQueue.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_apigatewayv2_api" "productVisit" {
  name          = "productVisit"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
  tags = {
    Name = var.All_Variables[3]
  }
}


resource "aws_apigatewayv2_integration" "API_Integration_productVisit" {
  api_id               = aws_apigatewayv2_api.productVisit.id
  integration_type     = "AWS_PROXY"
  connection_type      = "INTERNET"
  description          = "Lambda example"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.productVisitsSendDataToQueue.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}



resource "aws_apigatewayv2_route" "API_Route_productVisit" {
  api_id    = aws_apigatewayv2_api.productVisit.id
  route_key = "POST /sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.API_Integration_productVisit.id}"
}


resource "aws_apigatewayv2_stage" "API_Stage_productVisit" {
  api_id      = aws_apigatewayv2_api.productVisit.id
  name        = var.All_Variables[2]
  auto_deploy = true
}

resource "aws_lambda_permission" "Lambda_Permission_productVisitsSendDataToQueue" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.productVisitsSendDataToQueue.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.productVisit.execution_arn}/*/*/sendMessage"
}

############################################################################################################################

resource "aws_dynamodb_table" "ProductVisits" {
  name             = "ProductVisits"
  hash_key         = "ProductVisitKey"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "ProductVisitKey"
    type = "S"
  }

  tags = {
    Name = var.All_Variables[3]
  }
}


resource "aws_iam_role" "lambdaRoleForSQSPollarPermissions" {
  name = "lambdaRoleForSQSPermissions_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_iam_role_policy_attachment" "productVisitsDataHandler_Policy_Attachment" {
  role       = aws_iam_role.lambdaRoleForSQSPollarPermissions.name
  policy_arn = aws_iam_policy.productVisitsDataHandlerSQSPollerLambdaPolicy.arn
}


resource "aws_iam_policy" "productVisitsDataHandlerSQSPollerLambdaPolicy" {
  name        = "productVisitsDataHandlerLambda_SQSPoller_Policy_Terraform"
  path        = "/"
  description = "IAM policy for Polling from SQS"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          #"Resource": "arn:aws:logs:us-east-2:9**********4:*"
          "Resource" : join(":*", [join(":", [join("", ["arn:aws:logs:", var.All_Variables[0]]), var.All_Variables[1]]), ""]),
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:PurgeMessage",
            "sqs:GetQueueAttributes"
          ],
          #"Resource": "arn:aws:sqs:us-east-2:9**********4:ProductVisitsDataQueue"
          "Resource" : join(":", [join(":", [join("", ["arn:aws:sqs:", var.All_Variables[0]]), var.All_Variables[1]]), aws_sqs_queue.ProductVisitsDataQueue.name])
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:PutItem"
          ],
          #"Resource": "arn:aws:dynamodb:us-east-2:9**********4:table/ProductVisits"
          "Resource" : join(":table/", [join(":", [join("", ["arn:aws:dynamodb:", var.All_Variables[0]]), var.All_Variables[1]]), aws_dynamodb_table.ProductVisits.name])
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_function" "productVisitsDataHandler" {
  filename      = "lambda.zip"
  function_name = "productVisitsDataHandler"
  role          = aws_iam_role.lambdaRoleForSQSPollarPermissions.arn
  handler       = "productVisitsDataHandler.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_event_source_mapping" "ProductVisitsDataQueue_Event_source_mapping" {
  event_source_arn = aws_sqs_queue.ProductVisitsDataQueue.arn
  function_name    = aws_lambda_function.productVisitsDataHandler.arn
}

output "API_URL" {
  description = "Paste this in the Static S3 html"
  value = "${aws_apigatewayv2_api.productVisit.api_endpoint}/${var.All_Variables[2]}/sendMessage"
}

############################################################################################################################

resource "aws_iam_role" "productVisitsLoadingLambdaRole" {
  name = "productVisitsLoadingLambdaRole_Terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_iam_role_policy_attachment" "productVisitsLoadingLambdaRole_Policy_Attachment" {
  role       = aws_iam_role.productVisitsLoadingLambdaRole.name
  policy_arn = aws_iam_policy.productVisitsLoadingLambdaPolicy.arn
}


resource "aws_iam_policy" "productVisitsLoadingLambdaPolicy" {
  name        = "productVisitsLoadingLambdaPolicy_Policy_Terraform"
  path        = "/"
  description = "IAM policy for Polling from SQS"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          #"Resource": "arn:aws:logs:us-east-2:9**********4:*"
          "Resource" : join(":*", [join(":", [join("", ["arn:aws:logs:", var.All_Variables[0]]), var.All_Variables[1]]), ""]),
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeStream",
            "dynamodb:GetQueueAListStreamsttributes"
          ],
          #"Resource": "arn:aws:dynamodb:us-east-2:9**********4:table/ProductVisits/stream/*"
          "Resource" : join("",[join(":table/", [join(":", [join("", ["arn:aws:dynamodb:", var.All_Variables[0]]), var.All_Variables[1]]), aws_dynamodb_table.ProductVisits.name]),"/stream/*"])
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:*"
          ],
          "Resource" : [
            var.All_Variables[4],
            join("",[var.All_Variables[4],"/*"])
          ]
        }
      ]
  })
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_function" "productVisitsDatalakeLoadingHandler" {
  filename      = "lambda.zip"
  function_name = "productVisitsDatalakeLoadingHandler"
  role          = aws_iam_role.productVisitsLoadingLambdaRole.arn
  handler       = "productVisitsDatalakeLoadingHandler.lambda_handler"
  runtime       = "python3.9"
  tags = {
    Name = var.All_Variables[3]
  }
}

resource "aws_lambda_event_source_mapping" "productVisitsDatalakeLoadingHandler_Event_source_mapping" {
  event_source_arn = aws_dynamodb_table.ProductVisits.stream_arn
  function_name    = aws_lambda_function.productVisitsDatalakeLoadingHandler.arn
  starting_position = "LATEST"
}
