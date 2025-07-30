provider "aws" {
  region = "us-east-1"  
}

locals {
  instance_names = ["master", "worker1", "worker2"]
}

resource "aws_instance" "vm_instance" {
  count         = 3
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.medium"
  key_name      = "Dujohnson"  

  tags = {
    Name = local.instance_names[count.index]
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
    delete_on_termination = true
  }

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Instance ${local.instance_names[count.index]} is ready!" > /home/ubuntu/instance-ready.txt
              EOF
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-security-group"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ips" {
  value = {
    for instance in aws_instance.vm_instance:
    instance.tags.Name => instance.public_ip
  }
}