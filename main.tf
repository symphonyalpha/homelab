locals {
  lxc_hostname = "testing"
  lxc_vmid = 150
  ip = "192.168.2.200/24"
  ssh_key = "./secrets/id_ed25519.pub"
}

terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
  }
  
}

provider "proxmox" {
  pm_api_url          = "https://pve-raiden.symphonyalpha.me/api2/json"
  pm_user             = "root@pam"
  pm_password         = var.proxmox_password
}

resource "proxmox_lxc" "test_lxc" {
  target_node  = "pve-raiden"
  hostname     = local.lxc_hostname
  password     = var.lxc_password
  vmid         = local.lxc_vmid
  ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  unprivileged = true
  cores        = 1
  memory       = 512
  swap         = 512

  start        = true
  ssh_public_keys = file(local.ssh_key)
  tags         = "ansible"

  features {
    keyctl  = true
    nesting = true
  }

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "20G"
  }

  // NFS share mounted on host
  mountpoint {
    slot    = "0"
    key     = "0"
    storage = "/zfs-pool/docker"
    volume  = "/zfs-pool/docker"
    mp      = "/docker"
    size    = "1G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = local.ip
    gw     = "192.168.2.1"
  }
}

resource "ansible_host" "ansible_inventory" {
  depends_on = [proxmox_lxc.test_lxc]
  name = "test_lxc"
  groups = ["test"]

  variables = {
    ansible_host = "${split("/", local.ip)[0]}"
  }
}

resource "null_resource" "run_ansible" {
  depends_on = [ansible_host.ansible_inventory]

  provisioner "local-exec" {
    command     = "until nc -zv ${split("/", local.ip)[0]} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }

  provisioner "local-exec" {
    command = <<EOT
    ansible-playbook -i terraform.yaml ansible-proxmox.yaml
    EOT
  }
}