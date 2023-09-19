variable "k8s_cluster_token" {
  default = "abcdef.1234567890abcdef"
}

variable "overlay_cidr" {

}

variable "ssh_user" {

}


variable "node_list" {

}

resource "null_resource" "k8s" {
  count = length(var.node_list)

  connection {
    host        = element(var.node_list, count.index)
    user        = var.ssh_user
    private_key = file(format("/home/%s/.ssh/id_rsa", var.ssh_user))
  }

  provisioner "local-exec" {
    # Loop through the list of IP addresses and ping each one.
    command = <<-EOT
          for ip in "${join("\" \"", var.node_list)}"; do
            until ping -c1 -W 1 "$ip"; do sleep 5; done
          done
        EOT
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }

  provisioner "file" {

    content = templatefile("${path.module}/kubeadm_config.yaml", {
      master_ip = element(var.node_list, 0)
      token     = var.k8s_cluster_token
      cert_sans = element(var.node_list, 0)
      pod_cidr  = var.overlay_cidr

    })
    destination = "/tmp/kubeadm_config.yaml"
  }


  provisioner "file" {

    content = templatefile("${path.module}/repo.sh", {
    })
    destination = "/tmp/repo.sh"
  }

  provisioner "file" {

    content = templatefile("${path.module}/master.sh", {
    })
    destination = "/tmp/master.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/node.sh", {
      nr_hugepages  = 8
      modprobe_nvme = "ubuntu-20.04-server-cloudimg-amd64.img"
      master_ip     = element(var.node_list, 0)
      token         = var.k8s_cluster_token
    })
    destination = "/tmp/node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/repo.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      count.index == 0 ? "bash /tmp/master.sh" : "bash /tmp/node.sh"
    ]
  }
}
