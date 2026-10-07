terraform {
  required_version = "~> 1.16.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "= 6.67.0" }
  }
}
provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "devops-assignment", Session = "21", Owner = "Vimal-24BCS10273", ManagedBy = "Terraform" }
  }
}
