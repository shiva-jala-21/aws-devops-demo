resource "aws_vpc" "python" {
  cidr_block           = "16.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "python-demo-vpc"
  }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.python.id
    cidr_block = "16.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
      Name = "public-subnet"
  }
  
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.python.id
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
    route_table_id = aws_route_table.public-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.python-internet-gateway.id
  
}

resource "aws_route_table_association" "python-route-table-association" {
    route_table_id = aws_route_table.public-route-table.id
    subnet_id = aws_subnet.public.id
  
}