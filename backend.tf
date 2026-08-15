terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "coaching10_Aievolute/terraform.tfstate"
    region = "us-east-1"
  }
}

