provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"

  assume_role {
    role_arn     = "arn:aws:iam::170567814823:role/AdminFromOoyalaAccount"
    session_name = "tf"
  }
}
