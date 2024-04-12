//module vpc, lb_stickiness, 
// role permissions: ecsTaskExecution, WriteLogs

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "eks_execution_role" {
  name = "eks_execution_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

variable "cluster-name" {
  default = "terraform-eks"
  type    = string
}


resource "aws_iam_policy" "ecs_policy" {
  name = "ecs_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ecs:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_policy_attachment" {
  name       = "ecs_policy_attachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = aws_iam_policy.ecs_policy.arn
}

resource "aws_iam_policy_attachment" "eks_cluster_policy_attachment" {
  name       = "eks_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.eks_execution_role.name]
}

resource "aws_iam_policy_attachment" "eks_service_policy_attachment" {
  name       = "eks_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  roles      = [aws_iam_role.eks_execution_role.name]
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ecs_vpc"
  }
}

resource "aws_security_group" "ecs_security_group" {
  name        = "ecs-security-group"
  description = "Security group for ECS operations"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "Allow ECS service communication within VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "eks_security_group" {
  name        = "eks_security_group"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "Allow EKS service communication within VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks"
  }
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public subnet us-east-1a"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.64.0/18"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public subnet us-east-1b"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.128.0/18"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private subnet us-east-1a"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.192.0/18"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private subnet us-east-1b"
  }
}

resource "aws_internet_gateway" "ecs_internet_gateway" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}



resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ecs_internet_gateway.id
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "test-ecs-cluster"

  tags = {
    Name = "test-ecs-cluster"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name            = "ecs-launch-config"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ecs_security_group.id]
}


resource "aws_ecs_task_definition" "sample_task" {
  family             = "sample-nginx-task"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_execution_role.arn
  container_definitions = jsonencode([
    {
      name              = "nginx-container"
      image             = "nginx"
      memoryReservation = 128
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ],
      log_configuration = {
        log_driver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/sample-nginx-task",
          "awslogs-region"        = "us-east-1",
          "awslogs-create-group"  = "true",
          "awslogs-stream-prefix" = "test"
        }
      }
    }
  ])

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}



resource "aws_lb" "ecs_lb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.ecs_security_group.id]
}

resource "aws_lb_target_group" "ecs_target_group" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecs_vpc.id

  target_type = "ip"

  # health_check {
  #   path                = "/health"
  #   interval            = 30
  #   timeout             = 10
  #   healthy_threshold   = 3
  #   unhealthy_threshold = 2
  #   matcher             = "200-399"
  # }
}

resource "aws_lb_listener" "aws_lb_listener" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.id
    type             = "forward"
  }
}

# resource "aws_lb_target_group_attachment" "ecs_target_group_attachment" {
#   depends_on = [ aws_ecs_service.sample_service ]
#   target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   target_id        = aws_ecs_service.sample_service.id
#   port = 80
# }



resource "aws_ecs_service" "sample_service" {
  name                 = "sample-nginx-service"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.sample_task.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  force_new_deployment = "true"


  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.ecs_security_group.id]

    assign_public_ip = "true"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "nginx-container"
    container_port   = 80
  }
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks_execution_role.arn

  vpc_config {
    security_group_ids = ["${aws_security_group.eks_security_group.id}"]
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  }

  depends_on = [
    aws_iam_policy_attachment.eks_cluster_policy_attachment,
    aws_iam_policy_attachment.eks_service_policy_attachment
  ]
}

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG
}

output "kubeconfig" {
  value = local.kubeconfig
}

resource "aws_iam_role" "worker" {
  name = "terraform-eks-worker"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "worker" {
  name = "terraform-eks-worker"
  role = aws_iam_role.worker.name
}

resource "aws_security_group" "worker" {
  name        = "terraform-eks-worker"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.ecs_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

tags = tomap({
  "Name" = "terraform-eks-worker",
  "kubernetes.io/cluster/${var.cluster-name}" = "owned",
})

}

resource "aws_security_group_rule" "worker-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.worker.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-ingress-cluster-https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.eks_security_group.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-ingress-cluster-others" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.eks_security_group.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_security_group-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_security_group.id
  source_security_group_id = aws_security_group.worker.id
  to_port                  = 443
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  depends_on = [ aws_eks_cluster.cluster ]
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.cluster.name}-*"]
  }
}

locals {
  worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "eks_config" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.worker.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "t2.micro"
  name_prefix                 = "terraform-eks"
  security_groups             = ["${aws_security_group.worker.id}"]
  user_data_base64            = base64encode(local.worker-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_asg" {
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.eks_config.id
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks"
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id, aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tag {
    key                 = "Name"
    value               = "terraform-eks"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

resource "aws_ecr_repository" "nginx_repository" {
  name = "nginx-image"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.nginx_repository.repository_url
}

resource "null_resource" "write_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOF
echo '${local.kubeconfig}' > kubeconfig.txt
EOF

    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_eks_cluster.cluster]
}
