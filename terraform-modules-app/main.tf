module "dev-infra" {
  source = "./infra-app"
  env = "dev"
  bucket_name = "infra-app-bucket"
  instance_count = 1
  instance_type = "t2.micro"
  ec2_ami_id = "ami-0e5497a77ef21b5ac"
  hash_key = "studentID"
}
module "prod-infra" {
  source = "./infra-app"
  env = "prod"
  bucket_name = "infra-app-bucket"
  instance_count = 2
  instance_type = "t2.medium"
  ec2_ami_id = "ami-0e5497a77ef21b5ac"
  hash_key = "studentID"
}
module "stg-infra" {
  source = "./infra-app"
  env = "stg"
  bucket_name = "infra-app-bucket"
  instance_count = 1
  instance_type = "t2.small"
  ec2_ami_id = "ami-0e5497a77ef21b5ac"
  hash_key = "studentID"
}