import boto3

sqs = boto3.client('sqs')

def lambda_handler(event, context):

    ProductName = event['ProductName']
    ProductId = event['ProductId']
    Category = event['Category']
    PricePerUnit = event['PricePerUnit']
    CustomerId = event['CustomerId']
    CustomerName = event['CustomerName']
    TimeOfVisit = event['TimeOfVisit']
    
    sqs.send_message(
        QueueUrl="https://sqs.us-east-1.amazonaws.com/9XXXXXXXXXX4/ProductVisitsDataQueue",
        MessageBody=str(event)
    )
    