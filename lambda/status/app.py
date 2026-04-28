import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('orders-dev')

def handler(event, context):
    order_id = event['pathParameters']['order_id']

    res = table.get_item(Key={"order_id": order_id})
    item = res.get("Item")

    if not item:
        return {
            "statusCode": 404,
            "body": json.dumps({"message": "Not found"})
        }

    return {
        "statusCode": 200,
        "body": json.dumps(item)
    }