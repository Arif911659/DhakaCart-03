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
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "listeners" {
  description = "List of listeners"
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

