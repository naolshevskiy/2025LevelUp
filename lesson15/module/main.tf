
module "db" {
  source = "./modules/vm-db"

  ip_address             = var.db_ip
  ssh_user               = var.ssh_user
  ssh_private_key_path   = var.ssh_private_key_path
  db_name                = var.db_name
  db_password            = var.db_password
  subnet_cidr            = "192.168.109.0/24"
}

module "backend" {
  source = "./modules/vm-backend"

  ip_address             = var.backend_ip
  ssh_user               = var.ssh_user
  ssh_private_key_path   = var.ssh_private_key_path
  db_host                = var.db_ip
  db_name                = var.db_name
  db_password            = var.db_password
}


module "frontend" {
  source = "./modules/vm-frontend"

  ip_address             = var.frontend_ip
  ssh_user               = var.ssh_user
  ssh_private_key_path   = var.ssh_private_key_path
  backend_ip             = var.backend_ip