terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.62.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
resource "aws_default_vpc" "db_vpc"{
    force_destroy = true
}
resource "aws_default_subnet" "db_subnet" {
    availability_zone = "us-west-2a"
    map_public_ip_on_launch = true
    force_destroy = true
}
# Below Config is not required as default VPC is by default open to internet i.e has igw
# resource "aws_internet_gateway" "db-igw" {
#     vpc_id = aws_default_vpc.db_vpc.id
# }
# resource "aws_route" "igw-db_subnet" {
#   route_table_id = aws_default_vpc.db_vpc.main_route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id = aws_internet_gateway.db-igw.id
# }
resource "aws_security_group" "db-sg" {
  name = "db-sg"
  vpc_id = aws_default_vpc.db_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "allow-sql" {
  security_group_id = aws_security_group.db-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}
resource "aws_db_instance" "default" {
  allocated_storage           = 10
  db_name                     = "mydb"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  username                    = "admin"
  password = "admin123"
  availability_zone = aws_default_subnet.db_subnet.availability_zone
  vpc_security_group_ids = [ aws_security_group.db-sg.id ]
  port = 3306
  skip_final_snapshot = true
  apply_immediately = true
  backup_retention_period = 0
  publicly_accessible = true
}
output "db_endpoint" {
  value = aws_db_instance.default.endpoint
}