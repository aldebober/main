variable "cluster-name" {
    default = "changeme-com"
}

terraform {
    backend "s3" {
        bucket = "changeme-state-tf"
        region = "us-east-1" # required but totally ignored
        endpoint = "https://fra1.digitaloceanspaces.com"
        key = "kube/tf.tfstate"

        # Hey DO Spaces is only S3 compatible not exactly S3
        skip_credentials_validation = true
        skip_get_ec2_platforms = true
        skip_requesting_account_id = true
        skip_metadata_api_check = true
    }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket = "changeme-state-tf"
    endpoint = "https://fra1.digitaloceanspaces.com"
    skip_credentials_validation = true

    key     = "tf.tfstate"
    region  = "eu-west-1"
  }
}

provider "kubernetes" {
  host = "${data.terraform_remote_state.cluster.endpoint}"

  token = "${data.terraform_remote_state.cluster.token}"
  client_certificate = "${base64decode(data.terraform_remote_state.cluster.client_certificate)}"
  client_key = "${base64decode(data.terraform_remote_state.cluster.client_key)}"
  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.cluster.cluster_ca_certificate)}"
}

