data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "latest_ami" {

  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${var.project_name}-${var.project_env}-*"]
  }

  filter {
    name   = "tag:Environment"
    values = [var.project_env]
  }

  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }
}


data "aws_acm_certificate" "load_balancer_acm" {
  domain      = var.domain_name
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}