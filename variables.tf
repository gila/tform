variable "num_nodes" {
  type        = string
  description = "Number of nodes to create. The first node the master node."
  default     = 1
}

variable "qcow2_image" {
  type        = string
  description = "Base install image. Ubuntu cloud images are assumed."
  default     = "./kinetic-server-cloudimg-amd64.img"
}

variable "ssh_user" {
  type        = string
  description = "SSH user; typicall your user account."
}

variable "host_name" {
  type        = string
  description = "hostname prefix for the VMs."
  default     = "ks-node"

}

variable "overlay_cidr" {
  type        = string
  description = "CIDR, classless inter-domain routing."
  default     = "10.244.0.0/16"
}
