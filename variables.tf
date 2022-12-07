variable "qcow2_image" {
    type = string
    description = "Ubuntu base install image"
    default = "./kinetic-server-cloudimg-amd64.img"
}


variable "ssh_user" {
  type        = string
  description = "SSH user"
}
