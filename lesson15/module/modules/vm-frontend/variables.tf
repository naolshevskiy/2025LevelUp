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

variable "backend_ip" {
  type = string
}