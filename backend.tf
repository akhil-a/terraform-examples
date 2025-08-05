terraform {
  backend "s3" {
    bucket = "terraform-statefiles-akhil10anil"
    key    = "terraform-website/terraform.tfstate"
    region = "ap-south-1"
  }
}
