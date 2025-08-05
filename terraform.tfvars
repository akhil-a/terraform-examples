project_name  = "terraform-website"
project_env   = "prod"
instance_type = "t2.micro"
#ami_id         = "ami-0a1235697f4afa8a4"
ami_id         = "ami-08ca1d1e465fbfe0c"
vcp_cidr_block = "172.16.0.0/16"
enable_nat_gw  = true
server_ports   = [80, 443]
domain_name    = "akhilsworld.shop"

asg_sizes = {
  max_size         = 2
  min_size         = 2
  desired_capacity = 2

}
