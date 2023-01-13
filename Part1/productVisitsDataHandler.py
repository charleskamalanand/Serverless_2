import json
import boto3
import os,binascii

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ProductVisits')

def lambda_handler(event, context):
    records=event['Records']
    for record in records:
        products=json.loads(record['body'].replace("\'", "\""))
        for key,value in products.items():
            if key == "ProductId":
                ProductId=value
            elif key == "ProductName":
                ProductName=value
            elif key == "Category":
                Category=value
            elif key == "PricePerUnit":
                PricePerUnit=value
            elif key == "CustomerId":
                CustomerId=value
            elif key == "CustomerName":
                CustomerName=value
            elif key == "TimeOfVisit":
                TimeOfVisit=value
        
    response = table.put_item(
        Item={
            'ProductVisitKey' : str(binascii.b2a_hex(os.urandom(15))),
            'ProductId' : ProductId,
            'ProductName' : ProductName,
			'Category' : Category,
			'PricePerUnit' : PricePerUnit,
			'CustomerId' : CustomerId,
			'CustomerName' : CustomerName,
			'TimeOfVisit' : TimeOfVisit
            })
    print('Loaded date to dynamoDB')

