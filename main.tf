terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
  backend "s3" {
    key    = "aws/terraform-load-balancer/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Provision the ec2 instance for NGINX
resource "aws_instance" "nginx-server" {
  ami                    = "ami-0aa2b7722dc1b5612"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.general-sg.id]
  user_data              = file(user-data-nginx.tpl)
              
            

  tags = {
    "Name" = "nginx-server"
  }
}

# Provision the ec2 instance for APACHE
resource "aws_instance" "apache-server" {
  ami                    = "ami-007855ac798b5175e"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.general-sg.id]
  user_data              = file(user-data-apache.tpl)

  tags = {
    "Name" = "apache-server"
  }
}

# Provision a load balancer
resource "aws_lb" "terraform-one" {
  name               = "terraform-one-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.general-sg.id]
  subnets            = ["subnet-053a3b50133d15b07", "subnet-0d3e5a5d367271aa1", "subnet-0666be03f85594f4e"]
}

# Provision a target group
resource "aws_lb_target_group" "terraform-one" {
  name        = "terraform-one-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-051bec25153096c8c"

  health_check {
    path = "/"
  }
}

# Provision a listener 
resource "aws_lb_listener" "terraform-one" {
  load_balancer_arn = aws_lb.terraform-one.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-one.arn
  }
}

# Provision the target group attachments
resource "aws_lb_target_group_attachment" "nginx-server" {
  target_group_arn = aws_lb_target_group.terraform-one.arn
  target_id        = aws_instance.nginx-server.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "apache-server" {
  target_group_arn = aws_lb_target_group.terraform-one.arn
  target_id        = aws_instance.apache-server.id
  port             = 80
}

# Provision the security group
resource "aws_security_group" "general-sg" {
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow ssh"
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "allow http"
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
  }]
}
# Add Autoscalling group to the Load balancers
resource "aws_autoscaling_group" "lb-asg" {
  name                      = "lb-asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  vpc_zone_identifier       = ["subnet-053a3b50133d15b07"]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "lb-asg"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb.terraform-one,
  ]
}




#ygytty 



# Create launch template
resource "aws_launch_template" "example" {
  name_prefix = "example"
  image_id    = "ami-0123456789abcdef"
  instance_type = "t2.micro"
}

# Create ASG with ELBv2
resource "aws_autoscaling_group" "example" {
  name                      = "example"
  vpc_zone_identifier       = ["subnet-12345678", "subnet-23456789"]
  launch_template           = {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 5
  desired_capacity          = 2
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id      = aws_launch_template.example.id
        version                 = "$Latest"
        override                = []
      }
      overrides {
        instance_type           = "c5.large"
      }
      overrides {
        instance_type           = "c5.xlarge"
        weighted_capacity       = 4
      }
    }
    instances_distribution {
      on_demand_allocation_strategy = "prioritized"
      on_demand_base_capacity       = 1
      spot_allocation_strategy      = "lowest-price"
      spot_instance_pools            = 2
      spot_max_price                 = "0.05"
    }
  }
  tag {
    key                 = "Name"
    value               = "example"
    propagate_at_launch = true
  }
}

# Create ELBv2 listener and target group
resource "aws_lb" "example" {
  name               = "example"
  load_balancer_type = "application"
  subnets            = ["subnet-12345678", "subnet-23456789"]

  listener {
    port = 80
    default_action {
      target_group_arn = aws_lb_target_group.example.arn
      type             = "forward"
    }
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example"
  port     = 80
  protocol = "HTTP"

  health_check {
    path = "/"
  }
}

# Attach ASG to target group
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  alb_target_group_arn   = aws_lb_target_group.example.arn
}
