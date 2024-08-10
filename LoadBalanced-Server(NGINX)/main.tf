terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.61.0"
    }
  }
}
provider "aws" {
  region     = "us-west-2"
}
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
resource "aws_launch_template" "server_template" {
    name = "server-template"
    image_id = data.aws_ami.amazon-linux-2.image_id
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.mysecuritygroup.id]
    user_data=filebase64("userdata.sh")
    key_name = "cluster-key"
}
resource "aws_vpc" "server_vpc" {
    cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.server_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-2a"
    map_public_ip_on_launch = true
}
resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.server_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-west-2b"
    map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "server_gateway" {
    vpc_id = aws_vpc.server_vpc.id
}
resource "aws_route" "route-igw" {
  route_table_id            = aws_vpc.server_vpc.main_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.server_gateway.id
}
resource "aws_security_group" "mysecuritygroup" {
  name = "mysecuritygroup"
  vpc_id = aws_vpc.server_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "allowHTTP"{
    security_group_id = aws_security_group.mysecuritygroup.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 8080
    ip_protocol       = "tcp"
    to_port           = 8080
}
resource "aws_vpc_security_group_ingress_rule" "sshAll"{
    security_group_id = aws_security_group.mysecuritygroup.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 22
    ip_protocol       = "tcp"
    to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allowHTTP-80"{
    security_group_id = aws_security_group.mysecuritygroup.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 80
    ip_protocol       = "tcp"
    to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.mysecuritygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.mysecuritygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}
resource "aws_autoscaling_group" "server-asg" {
  vpc_zone_identifier = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]
  desired_capacity   = 3
  max_size           = 5
  min_size           = 2
  launch_template {
    id      = aws_launch_template.server_template.id
    version = "$Latest"
  }
}
resource "aws_lb" "server_lb" {
  name               = "server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysecuritygroup.id]
  subnets            = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]
}
resource "aws_lb_target_group" "server_lb-tg" {
  name     = "server-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.server_vpc.id
}
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.server-asg.id
  lb_target_group_arn    = aws_lb_target_group.server_lb-tg.arn
}
resource "aws_lb_listener" "server_lb_listener" {
  load_balancer_arn = aws_lb.server_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.server_lb-tg.arn
    type             = "forward"
  }
}
output "ip_address" {
  value = aws_lb.server_lb.dns_name
}