provider "aws" {
 region = "us-east-1"
}
# VPC
resource "aws_vpc" "main_vpc" {
 cidr_block = "10.0.0.0/16"
 tags = {
   Name = "main_vpc"
 }
}
# Internet Gateway
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main_vpc.id
 tags = {
   Name = "main_igw"
 }
}
# Public Subnets
resource "aws_subnet" "public" {
 count                   = 3
 vpc_id                  = aws_vpc.main_vpc.id
 cidr_block              = cidrsubnet("10.0.1.0/24", 2, count.index)
 availability_zone       = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)
 map_public_ip_on_launch = true
 tags = {
   Name = "public_subnet_${count.index + 1}"
 }
}
# Private Subnets
resource "aws_subnet" "private" {
 count                   = 3
 vpc_id                  = aws_vpc.main_vpc.id
 cidr_block              = cidrsubnet("10.0.2.0/24", 2, count.index)
 availability_zone       = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)
 tags = {
   Name = "private_subnet_${count.index + 1}"
 }
}
# Public Route Table
resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main_vpc.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
 tags = {
   Name = "public_route_table"
 }
}
# Associate public subnets to route table
resource "aws_route_table_association" "public_assoc" {
 count          = 3
 subnet_id      = aws_subnet.public[count.index].id
 route_table_id = aws_route_table.public_rt.id
}
# Security Group allowing 22, 80, 8080
resource "aws_security_group" "web_sg" {
 name        = "web_sg"
 description = "Allow SSH, HTTP, and custom port 8080"
 vpc_id      = aws_vpc.main_vpc.id
 ingress {
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
   from_port   = 8080
   to_port     = 8080
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
   Name = "web_security_group"
 }
}
# EC2 Instance in public subnet
resource "aws_instance" "ubuntu_instance" {
 ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS in us-east-1
 instance_type = "t2.micro"
 subnet_id     = aws_subnet.public[0].id
 vpc_security_group_ids = [aws_security_group.web_sg.id]
 associate_public_ip_address = true
 key_name = "linux.pem" # 🔑 Replace with your actual EC2 key pair name
 tags = {
   Name = "ubuntu_ec2"
 }
}