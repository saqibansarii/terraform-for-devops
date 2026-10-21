module "eks" {

  # import the module template
  source = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"


  # cluster info (control plane )
  name               = local.name
  kubernetes_version = "1.33"
  endpoint_public_access = true 
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # control plane network
  control_plane_subnet_ids = module.vpc.intra_subnets 
  addons = {
        vpc-cni = {
            most_recent = true
            before_compute = true
        }
        kube-proxy = {
            most_recent = true
        }
        coredns = {
            most_recent = true
        }
    }



  # managing nodes in cluster  
  eks_managed_node_groups = {
    saqib-eks-cluster = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      attach_cluster_primary_security_group = true

      min_size     = 2
      max_size     = 3
      desired_size = 2

      capacity_type = "SPOT"
    }
  }

  tags = {
    Environment = local.env
    Terraform   = "true"
  }
}