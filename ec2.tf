# key pair

resource "aws_key_pair" "my_key" {
    key_name = "terra-key-ec2"
    public_key = file("terra-key-ec2.pub")
}

#VPC & security Group

resource "aws_default_vpc" "default" {
    
}


resource "aws_security_group" "my_security_group" {
    name = "automate_sg"
    description = "this will add a TF generated Security Group"
    vpc_id = aws_default_vpc.default.id 
    #interpolation is a way in which you can inherit or extract the values from the terraform block.

    #inbound rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0" ]
        description = "SSH Open"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0" ]
        description = "HTTP Open"
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0" ]
        description = "Flask app"
    }


    #outbound rules
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0" ]
        description = "all access open outbound"
    }
    

    tags = {
    Name = "allow_tls"
  }
  
}

# ec2 instance


resource "aws_instance" "my_instance" {
    # count = 3 #meta argument
    for_each = tomap({
        Server-through-terraform-micro = "t2.micro"
        Server-through-terraform-medium = "t2.medium"
    }) # meta argument


    depends_on = [ aws_security_group.my_security_group, aws_key_pair.my_key ]

    key_name = aws_key_pair.my_key.key_name
    security_groups = [ aws_security_group.my_security_group.name ]
    instance_type = each.value
    ami = var.ec2_ami_id #ubuntu
    user_data = file("install_nginx.sh")

    root_block_device {
      volume_size = var.env == "prod" ? 20 : var.ec2_default_root_storage_size
      volume_type = "gp3"
    }
    tags = {
        Name = each.key
    }
  
}
