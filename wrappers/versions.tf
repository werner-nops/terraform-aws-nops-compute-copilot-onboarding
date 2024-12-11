terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    nops = {
      source  = "nops-io/nops"
      version = "0.0.7"
    }
  }
}
