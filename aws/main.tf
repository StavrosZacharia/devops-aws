#Create VPC
module "infra_vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.1.2"

    name               = "${var.environment}-eks-vpc"
    cidr               = var.vpc_cidr_block
    azs                = ["${var.region}a", "${var.region}c"]
    public_subnets     = var.public_subnets
    private_subnets    = var.private_subnets
    enable_nat_gateway = true
    enable_dns_hostnames = true


    private_subnet_tags = {
    Terraform                                      = "true"
    Environment                                    = var.environment
    "kubernetes.io/cluster/${var.environment}-eks" = "owned"
    "kubernetes.io/role/internal-elb"              = 1
  }

  nat_gateway_tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}  



# #Create EKS IAM policy and role
# resource "aws_iam_role" "eks_iam_role" {
#   name = "${var.environment}-eks-terraform-role"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "eks.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })

#   tags = {
#     Terraform   = "true"
#     Environment = var.environment
#   }
# }


# #Attach policies
# resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_iam_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.eks_iam_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_iam_role.name
# }


# #Create EKS log group
# resource "aws_cloudwatch_log_group" "eks_log_group" {
#   name              = "/aws/eks/${var.environment}-eks/cluster"
#   retention_in_days = 180
# }


# #Create EKS cluster
# resource "aws_eks_cluster" "eks_cluster" {
#   name     = "${var.environment}-eks"
#   role_arn = aws_iam_role.eks_iam_role.arn
#   version  = var.eks_version
#   vpc_config {
#     subnet_ids = [element(module.infra_vpc.private_subnets, 0), element(module.infra_vpc.private_subnets, 1)]

#     endpoint_public_access = true # Disable for production
#   }

#   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

#   depends_on = [
#     module.infra_vpc,
#     aws_iam_role.eks_iam_role,
#     aws_cloudwatch_log_group.eks_log_group
#   ]

#   tags = {
#     Terraform   = "true"
#     Environment = var.environment
#   }
# }


# #Create EKS worker nodes role
# resource "aws_iam_role" "eks_workernodes" {
#   name = "${aws_eks_cluster.eks_cluster.name}-node-group"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })

#   tags = {
#     Terraform   = "true"
#     Environment = var.environment
#   }
# }


# #Attach policies to role
# resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
#   policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonSSMReadOnlyAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   role       = aws_iam_role.eks_workernodes.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonSNSFullAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
#   role       = aws_iam_role.eks_workernodes.name
# }


# #Create EKS worker node group
# resource "aws_eks_node_group" "worker_node_group" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = "${aws_eks_cluster.eks_cluster.name}-workernodes"
#   node_role_arn   = aws_iam_role.eks_workernodes.arn
#   subnet_ids      = [element(module.infra_vpc.private_subnets, 0), element(module.infra_vpc.private_subnets, 1)]
#   instance_types  = ["${var.workernodes_instance_type}"]
#   disk_size       = var.workernodes_disk_size
#   capacity_type   = "ON_DEMAND"

#   scaling_config {
#     desired_size = 4
#     max_size     = 6
#     min_size     = 1
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.EC2InstanceProfileForImageBuilderECRContainerBuilds,
#     aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
#   ]

#   tags = {
#     Terraform   = "true"
#     Environment = var.environment
#   }

# }


# # Adding EKS add-on for ebs csi driver - for accessing pv (required after v1.23)
# # Get the OICD isseer




# #Create the aws load balancer role with policy



# #Karpenter auto scaler



# #Generate kube config



