# Define a variable to trigger a file rewrite
variable "force_rewrite" {
  description = "Set to a new value to force the fred.json file to be rewritten."
  type        = string
  default     = "initial"
}

# Add tags variable
variable "tags" {
  description = "Tags for resource identification and management"
  type        = map(string)
  default     = {}
}

# The null_resource acts as a proxy for the variable.
# Changing the variable's value will taint this resource,
# which can then be referenced by replace_triggered_by.
resource "null_resource" "force_rewrite_trigger" {
  triggers = {
    value = var.force_rewrite
  }
}

# Data source to retrieve the AWS account ID
data "aws_caller_identity" "current" {}

# Data source to retrieve all available VPCs in the region
data "aws_vpcs" "all_vpcs" {}

# This 'for_each' loop retrieves all subnets for each VPC
data "aws_subnets" "all_subnets_in_vpcs" {
  for_each = toset(data.aws_vpcs.all_vpcs.ids)
  filter {
    name   = "vpc-id"
    values = [each.value]
  }
}

# The 'local' block is used to prepare the data structure for the JSON file.
locals {
  subnets_by_vpc = {
    for k, v in data.aws_subnets.all_subnets_in_vpcs : k => v.ids
  }

  # Add tags to the metadata
  metadata = {
    aws_account_id = data.aws_caller_identity.current.account_id
    all_vpc_ids    = data.aws_vpcs.all_vpcs.ids
    subnets_by_vpc = local.subnets_by_vpc
    tags           = var.tags  # Include tags in the output
    timestamp      = timestamp()
    force_rewrite  = var.force_rewrite
  }
}

# The 'local_file' resource creates the fred.json file
resource "local_file" "fred_json" {
  filename = "fred.json"
  content  = jsonencode({
    aws_account_id = data.aws_caller_identity.current.account_id
    all_vpc_ids    = data.aws_vpcs.all_vpcs.ids
    subnets_by_vpc = local.subnets_by_vpc
  })

  # Now, we reference the null_resource instead of the variable.
  lifecycle {
    replace_triggered_by = [
      null_resource.force_rewrite_trigger
    ]
  }
}

