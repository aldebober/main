/*
 * Terraform variables definition
*/
terraformer_bucket = "epam-migration-staging-virginia-terraform-state"

aws_profile = "default"
aws_region = "us-east-1"

product_name = "discovery"
product_code_tag = ""
environment_tag = "staging"

emr_role = "EMR_EC2_DefaultRole"
lambda_file = "test.zip"

vpc_cidr = ""
vpc_azs = "us-east-1a,us-east-1b"
vpc_priv_subnets = ""
vpc_pub_subnets = ""

vpn_gateway_id = ""
peering_to_main_aws_id = ""
peering_to_jenkins_id = ""
vpn_gateway_to_git_id = ""

route53_subzone_for_ooyala_com = "discovery-aws"

ssh_cidrs = ["10.0.0.0/8"]
