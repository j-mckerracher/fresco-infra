data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Only fetch existing subnets if using existing subnets
data "aws_subnet" "existing_private_subnets" {
  count = var.use_existing_private_subnets ? length(var.existing_private_subnet_ids) : 0
  id    = var.existing_private_subnet_ids[count.index]
}
