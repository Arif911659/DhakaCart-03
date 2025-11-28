variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Type of load balancer (application, network, gateway)"
  type        = string
  default     = "application"
}

variable "subnets" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "create_target_group" {
  description = "Whether to create target group and listeners"
  type        = bool
  default     = true
}

variable "target_port" {
  description = "Port for target group"
  type        = number
  default     = 80
}

variable "target_ids" {
  description = "List of target instance IDs to register"
  type        = list(string)
  default     = []
}

variable "listeners" {
  description = "List of listeners (deprecated, use target_port instead)"
  type = list(object({
    port     = number
    protocol = string
  }))
  default = []
}

variable "health_check" {
  description = "Health check configuration"
  type = object({
    port     = number
    protocol = string
    path     = optional(string)
  })
  default = null
}
