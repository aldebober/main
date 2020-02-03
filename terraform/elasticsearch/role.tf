resource "aws_iam_service_linked_role" "this" {
  aws_service_name = "es.amazonaws.com"
}
