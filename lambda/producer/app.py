import json
import boto3
import os
import uuid

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('orders-dev')

def handler(event, context):
    body = json.loads(event['body'])

    order_id = str(uuid.uuid4())

    item = {
        "order_id": order_id,
        "customer_id": body["customer_id"],
        "product_id": body["product_id"],
        "quantity": body["quantity"],
        "status": "PENDING"
    }

    table.put_item(Item=item)

    sqs.send_message(
        QueueUrl=os.environ['QUEUE_URL'],
        MessageBody=json.dumps(item)
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "order_id": order_id,
            "status": "PENDING"
        })
    }