data "digitalocean_ssh_key" "terraform" {
  name = var.do_ssh_key_name
}

resource "digitalocean_droplet" "sof-elk-tf" {
  image  = "centos-7-x64"
  name   = "sof-elk"
  region = "fra1"
  size   = "s-4vcpu-8gb"

  ssh_keys = [
      data.digitalocean_ssh_key.terraform.id
  ]

  depends_on = [aws_s3_bucket.log-bucket-tf, aws_iam_access_key.s3-logs-read-key-tf]

  provisioner "remote-exec" {
    inline = ["echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.ssh_pvt_key} -e 'ssh_pub_key=${var.ssh_pub_key} disable_root=yes geoip_config_persist=no geoip_accountid=${var.geoip_account} geoip_licensekey=${var.geoip_license} aws_region=${var.aws_region} aws_logs_access_key=${aws_iam_access_key.s3-logs-read-key-tf.id} aws_logs_secret_key=${aws_iam_access_key.s3-logs-read-key-tf.secret} log_bucket=${aws_s3_bucket.log-bucket-tf.bucket}' sof-elk/ansible/sof-elk_install.yml"
  }
}

resource "digitalocean_firewall" "do-firewall-tf" {
  name = "whitelisted"

  droplet_ids = [digitalocean_droplet.sof-elk-tf.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.my_ip]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "5601"
    source_addresses = [var.my_ip]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = [var.my_ip]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0"]
  }
}

output "SOF-ELK-ip-address" {
  value = digitalocean_droplet.sof-elk-tf.ipv4_address
}
