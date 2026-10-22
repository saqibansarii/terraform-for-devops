module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}"
  cidr = local.vpc_cidr


  azs = local.azs
  public_subnets = local.public_subnets
  private_subnets =local.private_subnets
  intra_subnets = local.intra_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
#   enable_vpn_gateway = true


  tags = {
    Terraform = "true"
    Environment = local.env
  }
  
}