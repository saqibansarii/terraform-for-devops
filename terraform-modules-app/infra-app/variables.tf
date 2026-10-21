variable "env" {
    description = "This is the environment for my infra"
    type = string
}

variable "bucket_name" {
  description = "This is the bucket name for my infra"
}


variable "instance_count" {
  description = "This is the no. of ec2 instance"
  type = number
}
variable "instance_type" {
  description = "This is the type of ec2 instance"
  type = string
}

variable "ec2_ami_id" {
  description = "This is the ami id of ec2 instance"
  type = string
}
variable "hash_key" {
  description = "This is the hash key ec2 instance"
  type = string
}