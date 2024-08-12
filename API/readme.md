This will deploy an API (with API Gateway) with lambda function as backend utilizing DynamoDB

Get:
```
https://6mm8pnsyfj.execute-api.us-west-2.amazonaws.com/v1/user/?userId="1"
```
Add:
```
https://6mm8pnsyfj.execute-api.us-west-2.amazonaws.com/v1/add/?userId="1"&name="mani"&age=1
```
Update:
```
https://6mm8pnsyfj.execute-api.us-west-2.amazonaws.com/v1/update/?userId="1"&name="mani"&age=1
```
Delete:
```
https://6mm8pnsyfj.execute-api.us-west-2.amazonaws.com/v1/delete/?userId="1"
```