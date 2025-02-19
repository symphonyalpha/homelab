output "ip" {
  value = proxmox_lxc.create_lxc.network[0].ip
}

output "hostname" {
  value = proxmox_lxc.create_lxc.hostname
}
