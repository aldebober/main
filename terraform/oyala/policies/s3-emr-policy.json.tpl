{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "111",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::862470062164:user/role-log-processor"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${bucket_name}"
        },
        {
            "Sid": "111",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::862470062164:user/role-log-processor"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${bucket_name}/*"
        }
    ]
}
