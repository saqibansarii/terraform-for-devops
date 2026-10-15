# key pair

resource "aws_key_pair" "my_key" {
    key_name = "${var.env}-infra-app-key"
    public_key = file("terra-key-ec2.pub")

    tags = {
        Environment = var.env
    }
}

#VPC & security Group

resource "aws_default_vpc" "default" {
    
}


resource "aws_security_group" "my_security_group" {
    name = "${var.env}-infra-app-sg"
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



    #outbound rules
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0" ]
        description = "all access open outbound"
    }
    

    tags = {
    Name = "${var.env}-infra-app-sg"
  }
  
}

# ec2 instance


resource "aws_instance" "my_instance" {
    # count = 3 #meta argument
    count = var.instance_count
    


    depends_on = [ aws_security_group.my_security_group, aws_key_pair.my_key ]

    key_name = aws_key_pair.my_key.key_name
    security_groups = [ aws_security_group.my_security_group.name ]
    instance_type = var.instance_type
    ami = var.ec2_ami_id #ubuntu
    user_data = file("install_nginx.sh")

    root_block_device {
      volume_size = var.env == "prod" ? 20 : 10
      volume_type = "gp3"
    }
    tags = {
        Name = "${var.env}-infra-app-instance"
        Environment = var.env
    }
  
}



