

module "k8s" {
  source = "./k8s"
  ssh_user     = var.ssh_user
  node_list    = module.provider.nodes
  overlay_cidr = var.overlay_cidr
}

module "provider" {
  source      = "./libvirt"
  num_nodes   = var.num_nodes
  ssh_user    = var.ssh_user
  host_name   = var.host_name
  qcow2_image = var.qcow2_image
}

output "data" {
  value = module.provider.result
}
