variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "jwt_secret" {
  description = "Secret key used to sign JWT tokens"
  type        = string
  sensitive   = true
}

variable "jwt_issuer" {
  description = "Issuer for JWT tokens"
  type        = string
  sensitive   = true
}

variable "use_existing_private_subnets" {
  description = "Boolean to determine whether to use existing private subnets or create new ones"
  type        = bool
  default     = false
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use"
  type        = list(string)
  default     = []
}



