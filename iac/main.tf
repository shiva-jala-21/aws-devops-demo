resource "aws_vpc" "python" {
  cidr_block           = "16.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "python-demo-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.python.id
  cidr_block              = "16.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }

}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.python.id
  cidr_block              = "16.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "public-subnet"
  }

}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.python.id
  cidr_block = "16.0.2.0/24"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "python-internet-gateway" {
  vpc_id = aws_vpc.python.id
  tags = {
    Name = "aws-devops-demo-igw"
  }

}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.python.id
  tags = {
    Name = "python-public-route-table"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.python-internet-gateway.id

}

resource "aws_route_table_association" "python-route-table-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public.id

}

resource "aws_route_table_association" "public_2" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public2.id
}

resource "aws_ecr_repository" "python_app" {
  name                 = "aws-devops-demo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "aws-devops-demo-ecr"
  }
}

resource "aws_security_group" "alb_security_group" {
  vpc_id = aws_vpc.python.id
  name   = "python-alb-sg"
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "python-alb-sg"
  }
}


resource "aws_security_group" "ecs_security_group" {
  name        = "python-ecs-sg"
  description = "Security group for ECS Fargate"
  vpc_id      = aws_vpc.python.id

  ingress {
    description     = "Allow Flask traffic from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "python-ecs-sg"
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "aws-devops-demo-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "aws-devops-demo-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "app" {
  name               = "aws-devops-demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets = [
    aws_subnet.public.id,
    aws_subnet.public2.id
  ]

  tags = {
    Name = "aws-devops-demo-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "aws-devops-demo-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.python.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "5000"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "aws-devops-demo-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_cluster" "app" {
  name = "aws-devops-demo-cluster"

  tags = {
    Name = "aws-devops-demo-cluster"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/aws-devops-demo"
  retention_in_days = 7

  tags = {
    Name = "aws-devops-demo-logs"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "aws-devops-demo"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "python-app"
      image     = "${aws_ecr_repository.python_app.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "aws-devops-demo-task"
  }
}

resource "aws_ecs_service" "app" {
  name            = "aws-devops-demo-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 1
  launch_type   = "FARGATE"

  health_check_grace_period_seconds = 60

  network_configuration {
    subnets = [
      aws_subnet.public.id,
      aws_subnet.public2.id
    ]

    security_groups = [
      aws_security_group.ecs_security_group.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "python-app"
    container_port   = 5000
  }

  depends_on = [
    aws_lb_listener.app
  ]

  tags = {
    Name = "aws-devops-demo-service"
  }
  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}
