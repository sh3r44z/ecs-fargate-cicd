variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "af-south-1"
}

variable "app_name" {
  description = "Application name used for naming resources"
  type        = string
  default     = "fastapi-cicd"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MB for the Fargate task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of containers to run"
  type        = number
  default     = 1
}