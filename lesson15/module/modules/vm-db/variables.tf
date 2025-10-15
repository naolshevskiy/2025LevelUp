variable "ip_address" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_private_key_path" {
  type = string
}

variable "db_name" {
  type    = string
  default = "webbooks"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "subnet_cidr" {
  type    = string
  default = "192.168.109.0/24"