# add your get-notes function here
import boto3
from boto3.dynamodb.conditions import Key
import json
import urllib.request

dynamodb_resource = boto3.resource("dynamodb")
data_table = dynamodb_resource.Table("lotion-30142184")


def lambda_handler2(event, context):
    email = event['queryStringParameters']['email']
    token = event['queryStringParameters']['auth_token']
    response_API = urllib.request.urlopen(
        f"https://www.googleapis.com/oauth2/v1/userinfo?access_token={token}")
    parse = json.loads(response_API.read().decode())
    authenticated_email = parse["email"]

    if (email == authenticated_email):
        try:
            data = data_table.query(
                KeyConditionExpression=Key("email").eq(email))
            return {
                'statusCode': 200,
                'body': json.dumps(data['Items']),
            }
        except Exception as exp:
            print(exp)
    else:
        print("Not Authenticated")