provider "aws" {
  region = var.region
}

resource "aws_vpc" "ansible_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ansible_subnet" {
  vpc_id     = aws_vpc.ansible_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ansible_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.ansible_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.ansible_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.ansible_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create 3 EC2 instances
resource "aws_instance" "control_node" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ansible_subnet.id
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "Ansible-Control-Node"
  }
}

resource "aws_instance" "managed_node_2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ansible_subnet.id
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "Ansible-Managed-Node-2"
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "nodekey"
  public_key = tls_private_key.example.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

resource "local_file" "private_key" {
  filename = "${path.module}/nodekey.pem"
  content  = tls_private_key.example.private_key_pem
  file_permission = "0400"
}