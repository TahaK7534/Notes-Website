# add your delete-note function here# add your save-note function here
import boto3
import json
import urllib.request

dynamodb_resource = boto3.resource("dynamodb")
data_table = dynamodb_resource.Table("lotion-30142184")


def lambda_handler3(event, context):
    body = json.loads(event["body"])
    id_value = body.get('id')
    email_value = body.get('email')

    email = event['queryStringParameters']['email']
    token = event['queryStringParameters']['auth_token']
    response_API = urllib.request.urlopen(
        f"https://www.googleapis.com/oauth2/v1/userinfo?access_token={token}")
    parse = json.loads(response_API.read().decode())
    authenticated_email = parse["email"]

    if (email == authenticated_email):

        try:
            data_table.delete_item(
                Key={'id': id_value, 'email': email_value}
            )

            return {
                "statusCode": 200,
                "body": "success"
            }
        except Exception as exp:
            return {
                "statusCode": 500,
                "body": json.dumps(
                    {
                        "message": str(exp)
                    }
                )
            }