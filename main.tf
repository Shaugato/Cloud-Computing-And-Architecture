# Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "SParoiVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "SParoiVPC"
  }
}

# Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.SParoiVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.SParoiVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.SParoiVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.SParoiVPC.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Private Subnet 2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "sparoi_igw" {
  vpc_id = aws_vpc.SParoiVPC.id
  tags = {
    Name = "Sparoi Internet Gateway"
  }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "sparoi_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "SPAROI NAT Gateway"
  }
}

# Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.SParoiVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sparoi_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.SParoiVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sparoi_nat_gw.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name   = "WebServerSG"
  vpc_id = aws_vpc.SParoiVPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "WebServerSG"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "DataBaseSG"
  vpc_id = aws_vpc.SParoiVPC.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DataBaseSG"
  }
}

# EC2 Instances (DevServer)
resource "aws_instance" "dev_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_2.id
  key_name      = "Baston_web"
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd php mysql php-mysqlnd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    # Additional configuration for phpMyAdmin...
  EOF

  tags = {
    Name = "DevServer"
  }
}

# Elastic Load Balancer
resource "aws_lb" "sparoi_elb" {
  name               = "Sparoi-ELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "Sparoi-ELB"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "sparoi_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  target_group_arns    = [aws_lb_target_group.sparoi_tg.arn]

  launch_template {
    id      = aws_launch_template.sparoi_lt.id
    version = "$Latest"
  }

  tags = [{
    key                 = "Name"
    value               = "WebServer"
    propagate_at_launch = true
  }]
}

# Launch Template
resource "aws_launch_template" "sparoi_lt" {
  name          = "Sparoi-LT"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "Baston_web"
  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  tags = {
    Name = "Sparoi-LT"
  }
}

# RDS Instance
resource "aws_db_instance" "sparoi_rds" {
  identifier          = "sparoi-db"
  engine              = "mysql"
  instance_class      = "db.t2.micro"
  allocated_storage   = 20
  db_subnet_group_name = aws_db_subnet_group.sparoi_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username            = "admin"
  password            = "admin123"
  skip_final_snapshot = true
}

# S3 Bucket
resource "aws_s3_bucket" "sparoi_bucket" {
  bucket = "sparoi-bucket"

  versioning {
    enabled = true
  }

  acl = "private"
}

resource "aws_s3_bucket_policy" "sparoi_bucket_policy" {
  bucket = aws_s3_bucket.sparoi_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::sparoi-bucket/*"
    }
  ]
}
POLICY
}

# Lambda Function
resource "aws_lambda_function" "create_thumbnail" {
  function_name = "CreateThumbnail"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda-deployment-package-0.1.zip"
  source_code_hash = filebase64sha256("lambda-deployment-package-0.1.zip")
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
