import boto3
import csv

sqs = boto3.resource('sqs')
sqs2 = boto3.client('sqs')

queue = sqs.get_queue_by_name(QueueName='My-secound-Queue')

while True:
    response = sqs2.receive_message(QueueUrl=queue.url, MaxNumberOfMessages=1)
    messages = response.get('Messages', [])
    if not messages:
        continue
    message = messages[0]
    print(message)
    receipt_handle = message['ReceiptHandle']
    with open('metadata.csv', 'w') as csv_file:
        writer = csv.writer(csv_file)
        for key, value in response.items():
            writer.writerow([key, value])

    sqs2.delete_message(QueueUrl=queue.url, ReceiptHandle=receipt_handle)