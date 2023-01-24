import json
import boto3
import os,binascii

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ProductVisits')

def lambda_handler(event, context):
    records=event['Records']
    #print(event)
    ProductId=""
    ProductName=""
    Category=""
    PricePerUnit=""
    CustomerId=""
    CustomerName=""
    TimeOfVisit=""
    for record in records:
    #    products=json.loads(record['body'].replace("\'", "\""))
        products=record['body']
        #print(products)
        #print(type(dict(eval(products))))
        #print(products[0])
        actual_products=dict(eval(products))['body']
        #print(type(dict(eval(actual_products))))
        for key,value in dict(eval(actual_products)).items():
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
    #print(ProductId)    
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
    
