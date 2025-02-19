terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

resource "ansible_host" "ansible_inventory" {
  name       = var.hostname
  groups     = [var.ansible_group]

  variables = {
    ansible_host = var.ip
    ansible_user               = "root"
    ansible_ssh_private_key_file = var.ssh_priv_key
  }
}

resource "null_resource" "test_ssh" {
  provisioner "local-exec" {
    command = "until nc -zv ${var.ip} 22; do echo 'Waiting for SSH...'; sleep 5; done"
  }
}

resource "ansible_playbook" "run_playbook" {
  playbook = "${var.playbook_directory}/${var.ansible_playbook}"
  name     = var.ip
  verbosity = 3
}
