terraform {
  required_version = "~> 0.11.3"

  backend "s3" {
    bucket = ""
    key    = ""
  }
}
