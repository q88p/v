resource "aws_key_pair" "ssh-key-tf" {
  key_name   = "ssh-key-tf"
  public_key = file(var.ssh_pub_key)
}

resource "aws_security_group" "allow_ssh-tf" {
  name        = "allow_ssh-tf"
  description = "Allow SSH inbound traffic from whitelisted IP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh-tf"
  }
}

resource "aws_iam_instance_profile" "ec2-ses-profile-tf" {
  name  = "ec2-ses-profile-tf"
  role = aws_iam_role.ec2-ses-role-tf.name
}

resource "aws_instance" "email_sender-tf" {
  ami = "ami-076c2ee28e3f9f38e" #Amazon Linux 2 AMI (HVM), SSD Volume Type Sun Mar 28 15:10:48 EEST 2021
  instance_type = "t3.micro"
  key_name = "ssh-key-tf"
  security_groups = ["allow_ssh-tf"]
  iam_instance_profile = aws_iam_instance_profile.ec2-ses-profile-tf.name

  provisioner "remote-exec" {
      inline = ["curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash", ". ~/.nvm/nvm.sh", "nvm install node", "npm install aws-sdk", "echo Done!"]

      connection {
        host = aws_instance.email_sender-tf.public_ip
        type = "ssh"
        user = "ec2-user"
        private_key = file(var.ssh_pvt_key)
      }
    }

    provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user -i '${aws_instance.email_sender-tf.public_ip},' --private-key ${var.ssh_pvt_key} -e 'pub_key=${var.ssh_pub_key}, my_email=${var.my_email}, configuration_set_name=${aws_ses_configuration_set.ses-configuration-tf.name}' ansible/email-app-install.yml"
    }
}

output "EC2-IP-address" {
  value = aws_instance.email_sender-tf.public_ip
}
