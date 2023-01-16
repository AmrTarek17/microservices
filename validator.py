import boto3
import json
import time

# import os

# Create an SQS client
sqs = boto3.client('sqs')
s3 = boto3.client('s3')
sqs2 = boto3.resource('sqs')


# The URL of the SQS queue
# queue_url = 'https://sqs.us-west-2.amazonaws.com/202009016751/My-first-Queue'

queue = sqs2.get_queue_by_name(QueueName='My-first-Queue')
queue_url = queue.url

while True:
    # Receive messages from the queue
    response = sqs.receive_message(QueueUrl=queue_url, MaxNumberOfMessages=1)
    
    # Get the messages from the response
    messages = response.get('Messages', [])

    # If there are no messages, wait and try again
    if not messages:
        continue

    # Process the message
    message = messages[0]
    print(message)
    body = json.loads(message['Body'])
    receipt_handle = message['ReceiptHandle']
    message_body = json.loads(body["Message"])
    record = message_body["Records"][0]
    # Get the bucket name and file name from the message
    bucket_name = record["s3"]["bucket"]["name"]
    file_name = record["s3"]["object"]["key"]
    # Download the file from S3
    print(bucket_name)
    print(file_name)
    s3.download_file(bucket_name, file_name, f'/root/amr-playGround/microservices/{file_name}')

    
    
    # Delete the message from the queue
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt_handle)

    with open(f'{file_name}', 'r') as f:
        data = f.read()
        data = data.replace(',', '\n')

    with open(f'{file_name}', 'w') as f:
        f.write(data)

    s3.upload_file(file_name, 'my-secound-bucket-20200', file_name )
    
    #sleep for 1 min
    time.sleep(60)