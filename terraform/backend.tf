terraform {
  backend "s3" {
    bucket       = "sheraaz-terraform-state"
    key          = "ecs-fargate-cicd/terraform.tfstate"
    region       = "af-south-1"
    use_lockfile = true
    encrypt      = true
  }
}