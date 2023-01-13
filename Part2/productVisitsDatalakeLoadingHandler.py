import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
	bucket ='product-visits-datalake-43001'
	records=event['Records']
	Product_dict={}
	for record in records:
		if record['eventName'] == "INSERT":
			product=record['dynamodb']
			for key,value in product.get('NewImage').items():
				if key == "Category":
					temp=value
					Product_dict['Category']=temp.values()
				elif key == "ProductName":
					temp=value
					Product_dict['ProductName']=temp.values()
				elif key == "ProductVisitKey":
					temp=value
					Product_dict['ProductVisitKey']=temp.values()
				elif key == "ProductId":
					temp=value
					Product_dict['ProductId']=temp.values()
				elif key == "CustomerId":
					temp=value
					Product_dict['CustomerId']=temp.values()
				elif key == "CustomerName":
					temp=value
					Product_dict['CustomerName']=temp.values()
				elif key == "PricePerUnit":
					temp=value
					Product_dict['PricePerUnit']=temp.values()
				elif key == "TimeOfVisit":
					temp=value
					Product_dict['TimeOfVisit']=temp.values()
		
			year=str(Product_dict['TimeOfVisit'])[14:18]
			month=str(Product_dict['TimeOfVisit'])[19:21]
			day=str(Product_dict['TimeOfVisit'])[22:24]
			hour=str(Product_dict['TimeOfVisit'])[25:27]
			s3_prefix= year + "/" + month + "/"+ day + "/" + hour + "/"
			Filename = s3_prefix + str(Product_dict['ProductVisitKey'])[ 14:len(str(Product_dict['ProductVisitKey']))- 4 ] + ".json"
			Product_dict_formated={}
			for key,value in Product_dict.items(): #this is remove "dict_values" word from key value pair
				Product_dict_formated[key]=list(value)[0]
		
			uploadByteStream = bytes(json.dumps(Product_dict_formated).encode('UTF-8'))
			s3.put_object(Bucket=bucket, Key=Filename, Body=uploadByteStream)
			print('Uploaded file to S3')