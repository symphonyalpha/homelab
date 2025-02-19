terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

resource "proxmox_lxc" "create_lxc" {
  target_node  = var.target_node

  hostname     = var.lxc_hostname
  password     = var.password
  vmid         = var.vmid

  ostemplate   = var.ostemplate

  unprivileged = true

  cores        = var.cores
  memory       = var.memory
  swap         = var.memory

  start           = true
  ssh_public_keys = file(var.ssh_key)
  tags            = var.tags

  features {
    keyctl  = var.keyctl
    nesting = var.nesting
  }

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    name   = var.interface
    bridge = var.bridge
    ip     = var.ip
    gw     = var.gateway
  }

  dynamic "mountpoint" {
    for_each = var.mountpoint
    content {
      slot    = mountpoint.value.slot
      key     = mountpoint.value.key
      storage = mountpoint.value.storage
      volume  = mountpoint.value.volume
      mp      = mountpoint.value.mp

      # Add size if provided
      size = lookup(mountpoint.value, "size", null)
    }
  }
}
