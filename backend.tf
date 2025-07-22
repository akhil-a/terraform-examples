terraform {
  backend "s3" {
    bucket = "terraform-statefiles-akhil10anil"
    key    = "terraform-example/terraform.tfstate"
    region = "ap-south-1"
  }
}
