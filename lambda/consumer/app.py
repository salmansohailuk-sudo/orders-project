import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('orders-dev')

sns = boto3.client('sns')

def handler(event, context):
    for record in event['Records']:
        data = json.loads(record['body'])

        try:
            table.update_item(
                Key={"order_id": data["order_id"]},
                UpdateExpression="SET #s = :s",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "SUCCESS"}
            )

            sns.publish(
                TopicArn=os.environ['SNS_TOPIC'],
                Message=f"Order {data['order_id']} SUCCESS"
            )

        except Exception as e:
            table.update_item(
                Key={"order_id": data["order_id"]},
                UpdateExpression="SET #s = :s",
                ExpressionAttributeNames={"#s": "status"},
                ExpressionAttributeValues={":s": "FAILED"}
            )

            sns.publish(
                TopicArn=os.environ['SNS_TOPIC'],
                Message=str(e)
            )