variable "hostname" {
  type = string
}
variable "ip" {
  type = string
}
variable "ssh_priv_key" { default = "../secrets/id_ed25519" }

variable "ansible_group" {}

variable "playbook_directory" { default="playbooks" }
variable "ansible_playbook" { default="post.yaml" }
