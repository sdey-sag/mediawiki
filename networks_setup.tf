#Create VPC in us-east-1
resource "aws_vpc" "vpc_mediawiki" {
  provider             = aws.mediawiki-node
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mediawiki_vpc"
  }

}

#Create IGW in us-east-1
resource "aws_internet_gateway" "igw" {
  provider = aws.mediawiki-node
  vpc_id   = aws_vpc.vpc_mediawiki.id
}


#Create route table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.mediawiki-node
  vpc_id   = aws_vpc.vpc_mediawiki.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "mediawiki-rt"
  }
}

#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.mediawiki-node
  vpc_id         = aws_vpc.vpc_mediawiki.id
  route_table_id = aws_route_table.internet_route.id
}
#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.mediawiki-node
  state    = "available"
}

#Create subnet # 1 in us-east-1
resource "aws_subnet" "subnet_1" {
  provider          = aws.mediawiki-node
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_mediawiki.id
  cidr_block        = "10.0.1.0/24"
}

#Create SG for allowing TCP/8080 from * and TCP/22 from your IP in us-east-1
resource "aws_security_group" "mediawiki-sg" {
  provider    = aws.mediawiki-node
  name        = "mediawiki-sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.vpc_mediawiki.id
  ingress {
    description = "Allow SSH from public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from public IP"
    from_port   = var.webserver-port
    to_port     = var.webserver-port
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
