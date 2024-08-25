module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks-sm"
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = data.aws_vpc.my_vpc_id.id
  subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 5
      desired_size = 3
    }
  }

  authentication_mode                      = "API_AND_CONFIG_MAP" # Cluster access entry
  enable_cluster_creator_admin_permissions = true
  depends_on = [module.vpc]

    node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

#module "vpc_cni_irsa" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "~> 4.12"
#
#  role_name_prefix      = "VPC-CNI-IRSA"
#  attach_vpc_cni_policy = true
#  vpc_cni_enable_ipv4   = true
#
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-node"]
#    }
#  }
#
#  tags = local.tags
#}
#
#module "lb_controller_irsa_role" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "~> 4.12"
#
#  role_name                              = "AmazonEKSLoadBalancerControllerRole"
#  attach_load_balancer_controller_policy = true
#
#  oidc_providers = {
#    ex = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#    }
#  }
#
#  tags = local.tags
#}

#resource "aws_iam_policy" "additional_iam_policy" {
#  name   = "AWSLoadBalancerControllerAdditionalIAMPolicy"
#  policy = file("${path.module}/policy/additional_policy.json")
#}
#
#resource "aws_iam_role_policy_attachment" "additional_iam_policy_attach" {
#  role       = module.lb_controller_irsa_role.iam_role_name
#  policy_arn = aws_iam_policy.additional_iam_policy.arn
#}