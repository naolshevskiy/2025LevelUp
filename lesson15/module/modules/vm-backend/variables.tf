variable "ip_address" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "nikita"
}

variable "ssh_private_key_path" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type    = string
  default = "webbooks"
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true