#Output for Count


# output "ec2_public_ip" {
#   value = aws_instance.my_instance[*].public_ip
# }
# output "ec2_private_ip" {
#   value = aws_instance.my_instance[*].private_ip
# }

# output "ec2_public_dns" {
#   value = aws_instance.my_instance[*].public_dns
# }




#Output for Foreach


  output "ec2_pubic_ip" {
    value = [
      for key in aws_instance.my_instance : key.public_ip
    ]
  }
  output "ec2_private_ip" {
    value = [
      for key in aws_instance.my_instance : key.private_ip
    ]
  }
  output "ec2_pubic_dns" {
    value = [
      for key in aws_instance.my_instance : key.public_dns
    ]
  }