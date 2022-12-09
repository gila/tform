terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

variable "num_nodes" {}

variable "ssh_user" {}

variable "host_name" {}

variable "qcow2_image" {}

variable osd_size {
    description = "size in GB for the OSD drivers"
    default = 5
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "tpool" {
  name = "tpool"
  type = "dir"
  path = format("/home/${var.ssh_user}/tpool")
}

resource "libvirt_volume" "qcow2-image" {
  name   = "base_image"
  pool   = libvirt_pool.tpool.name
  source = var.qcow2_image
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  count          = var.num_nodes
  name           = format("${var.host_name}-%d", count.index + 1)
  pool           = libvirt_pool.tpool.name
  base_volume_id = libvirt_volume.qcow2-image.id
  size           = 53687091200
  format         = "qcow2"
}

resource "libvirt_volume" "data" {
  count  = var.num_nodes
  name   = format("${var.host_name}-data-%d", count.index + 1)
  pool   = libvirt_pool.tpool.name
  size   = "${var.osd_size * 1024 * 1024 * 1024}"
  format = "qcow2"
}


resource "libvirt_cloudinit_disk" "commoninit" {
  count = var.num_nodes
  name  = format("cloud_init_${var.host_name}-%d", count.index + 1)
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    "ssh_user" : var.ssh_user
    "ssh_key" : file(format("/home/${var.ssh_user}/.ssh/id_rsa.pub"))
    "hostname" : format("${var.host_name}-%d", count.index + 1)
    }
  )

  network_config = templatefile("${path.module}/network_config.cfg", {})
  pool           = libvirt_pool.tpool.name
}


resource "libvirt_domain" "domain-ubuntu" {
  count      = var.num_nodes
  name       = format("${var.host_name}-%d", count.index + 1)
  memory     = count.index > 0 ? "${8 * 1024}" : "${16 * 1024}"
  vcpu       = count.index > 0 ? 2 : 4
  qemu_agent = true

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  network_interface {
    hostname       = format("${var.host_name}-%d", count.index + 1)
    bridge         = "br0"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2[count.index].id
  }

  dynamic "disk" {
    for_each = count.index > 0 ? [1] : []
    content {
      volume_id = libvirt_volume.data[count.index].id
    }
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

output "nodes" {
  value = libvirt_domain.domain-ubuntu.*.network_interface.0.addresses.0
}

output "result" {
  value = tomap({ for node in libvirt_domain.domain-ubuntu : node.name => node.network_interface[0].addresses[0] })
}
