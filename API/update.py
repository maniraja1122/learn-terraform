import boto3
import botocore
import json
def lambda_handler(event, context):
   userid=event["queryStringParameters"]["userId"]
   name=event["queryStringParameters"]["name"]
   age=event["queryStringParameters"]["age"]

   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('users')
   table.put_item(
        Item={
            "UserId":userid,
            "Name":name,
            "Age":age
        }
    )
   return {
      "statusCode" : 200,
       "headers" : {"Content-Type": "application/json"},
       "body": "User Updated Successfully"
   }