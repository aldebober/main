terraform {
  required_version = "~> 0.11.3"

  backend "s3" {
    bucket = "epam-migration-staging-virginia-terraform-state"
    key    = "epam-migration-staging-virginia-discovery-stack"
  }
}
