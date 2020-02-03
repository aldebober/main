provider "digitalocean" {
}

terraform {
    backend "s3" {
        bucket = "changeme-state-tf"
        region = "us-east-1" # required but totally ignored
        endpoint = "https://fra1.digitaloceanspaces.com"
        key = "tf.tfstate"

        # Hey DO Spaces is only S3 compatible not exactly S3
        skip_credentials_validation = true
        skip_get_ec2_platforms = true
        skip_requesting_account_id = true
        skip_metadata_api_check = true
    }
}

