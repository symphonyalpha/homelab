variable "target_node" { default = "pve-raiden" }

variable "lxc_hostname" {}
variable "password" { sensitive = true }
variable "vmid" {}

variable "ostemplate" { default = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst" }

variable "unprivileged" { default = true }

variable "cores" { default = 1 }
variable "memory" { default = 512 }

variable "start" { default = true }
variable "ssh_key" { default = "secrets/id_ed25519.pub" }
variable "tags" { default = "ansible" }

variable "keyctl" { default = true }
variable "nesting" { default = true }

variable "rootfs_storage" { default = "local-lvm" }
variable "rootfs_size" { default = "30G" }

variable "interface" { default = "eth0" }
variable "bridge" { default = "vmbr0" }
variable "ip" {}
variable "gateway" { default = "192.168.2.1" }

variable "mountpoint" {
  type = list(object({
    slot    = string
    key     = string
    storage = string
    volume  = string
    mp      = string
    size    = optional(string)
  }))
  default = []
}