############# SNS creation ##############
resource "aws_sns_topic" "topic" {
  name = "sns-topic"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:sns-topic",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.src_bucket.arn}"}
        }
    }]
}
POLICY
}

############# s3 & Notification ################

resource "aws_s3_bucket" "src_bucket" {
  bucket = "my-first-bucket-20200"
}

resource "aws_s3_bucket" "trg_bucket" {
  bucket = "my-secound-bucket-20200"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.src_bucket.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    # filter_suffix = ".log"
  }
}

############### sqs creation ######################

# resource "aws_sqs_queue" "deadletter_queue" {
#   name = "deadletter-queue"
# #   redrive_allow_policy = jsonencode({
# #     redrivePermission = "byQueue",
# #     sourceQueueArns   = [aws_sqs_queue.terraform_first_queue.arn]
# #   })
# }

resource "aws_sqs_queue" "dead_letter_queue" {
  name              = "dead-letter-queue"
  visibility_timeout_seconds = 50
}

resource "aws_sqs_queue" "terraform_first_queue" {
  name = "My-first-Queue"

  visibility_timeout_seconds = 30
  # message_retention_seconds = 60
  redrive_policy    = jsonencode({
  deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
  maxReceiveCount    = 10
    
  })
  
  # redrive_policy = jsonencode({
  #   deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
  #   maxReceiveCount     = 10
  # })
}

resource "aws_sqs_queue" "terraform_secound_queue" {
  name = "My-secound-Queue"

  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 10
  })
}

############ sqs policy #########################

resource "aws_sqs_queue_policy" "first-sqs-policy" {
  queue_url = aws_sqs_queue.terraform_first_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.terraform_first_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "secound-sqs-policy" {
  queue_url = aws_sqs_queue.terraform_secound_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.terraform_secound_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.topic.arn}"
        }
      }
    }
  ]
}
POLICY
}


############ SNS subscribtion ####################

resource "aws_sns_topic_subscription" "first_sqs_target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.terraform_first_queue.arn
}

resource "aws_sns_topic_subscription" "secound_sqs_target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.terraform_secound_queue.arn
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "amro.tarek6@gmail.com"
}