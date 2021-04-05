terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.34.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
