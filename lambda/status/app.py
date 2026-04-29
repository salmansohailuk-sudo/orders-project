import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('orders-dev')

def handler(event, context):

    # ✅ FIX: Safe extraction (prevents 500 error)
    path_params = event.get('pathParameters')

    if not path_params or 'order_id' not in path_params:
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Allow-Methods": "*"
            },
            "body": json.dumps({"message": "order_id required"})
        }

    order_id = path_params['order_id']

    res = table.get_item(Key={"order_id": order_id})
    item = res.get("Item")

    if not item:
        return {
            "statusCode": 404,

            # ✅ CORS
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Allow-Methods": "*"
            },

            "body": json.dumps({"message": "Not found"})
        }

    return {
        "statusCode": 200,

        # ✅ CORS
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "*"
        },

        "body": json.dumps(item)
    }
