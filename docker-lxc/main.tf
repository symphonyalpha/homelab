locals {
  lxc_hostname       = "docker"
  lxc_vmid           = 101
  lxc_cores          = 2
  lxc_memory         = 4096
  ip                 = "192.168.2.151/24"
  ansible_group      = "docker"

  ssh_key            = "../secrets/id_ed25519.pub"
  ssh_priv_key       = "../secrets/id_ed25519"
  playbook_directory = "../playbooks"
}

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }

}

provider "proxmox" {
  pm_api_url  = "https://pve-raiden.symphonyalpha.me/api2/json"
  pm_user     = "root@pam"
  pm_password = var.proxmox_password
}

resource "proxmox_lxc" "create_lxc" {
  target_node  = "pve-raiden"
  hostname     = local.lxc_hostname
  password     = var.lxc_password
  vmid         = local.lxc_vmid
  ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  unprivileged = true
  cores        = local.lxc_cores
  memory       = local.lxc_memory
  swap         = local.lxc_memory

  start           = true
  ssh_public_keys = file(local.ssh_key)
  tags            = "ansible"

  features {
    keyctl  = true
    nesting = true
  }

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "30G"
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

  mountpoint {
    slot    = "1"
    key     = "1"
    storage = "/zfs-pool/data"
    volume  = "/zfs-pool/data"
    mp      = "/data"
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
  depends_on = [proxmox_lxc.create_lxc]
  name       = "docker"
  groups     = ["${local.ansible_group}"]

  variables = {
    ansible_host                 = "${split("/", local.ip)[0]}"
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local.ssh_priv_key
  }
}

resource "null_resource" "test_ssh" {
  depends_on = [ansible_host.ansible_inventory]

  provisioner "local-exec" {
    command     = "until nc -zv ${split("/", local.ip)[0]} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
    working_dir = path.module
  }
}

resource "ansible_playbook" "run_playbook" {
  depends_on = [null_resource.test_ssh]

  playbook = "${local.playbook_directory}/docker.yaml"
  name     = split("/", local.ip)[0]
}
