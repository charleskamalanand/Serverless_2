import boto3

sqs = boto3.client('sqs')

def lambda_handler(event, context):    
    sqs.send_message(
        QueueUrl="https://sqs.us-east-2.amazonaws.com/951560400874/ProductVisitsDataQueue",
        MessageBody=str(event)
    )
    