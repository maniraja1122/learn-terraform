import boto3
from boto3.dynamodb.conditions import Key
import botocore
import json
def lambda_handler(event, context):
   userid=event["queryStringParameters"]["userId"]
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('users')
   response = table.query(
    KeyConditionExpression=Key('UserId').eq(userid))
   items = response.get("Items",[])
   return {
      "statusCode" : 200,
       "headers" : {"Content-Type": "application/json"},
       "body": json.dumps(items[0]) if len(items)>0 else "No User Found",
   }