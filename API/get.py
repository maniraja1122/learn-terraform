import boto3
import botocore
import json
def lambda_handler(event, context):
   userid=event["queryStringParameters"]["userId"]
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('users')
   response = table.get_item(
    Key={
        'UserId': userid
    } )
   item = response['Item']
   return {
      "statusCode" : 200,
       "headers" : {"Content-Type": "application/json"},
       "body": item,
   }