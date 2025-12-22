provider "aws" {
  region = "us-east-2"
}

# resource "aws_iam_user" "createuser" {
#   for_each = toset(var.user_names)    # (set => each.value), (map => each.key, each.value)
#   name     = each.value
# }