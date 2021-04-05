## How To
```
brew install terraform
brew install ansible
```
```
git clone https://github.com/q88p/v.git
cd v/
terraform init
```
```
terraform apply \
-var "my_email=EMAIL" \
-var "my_ip=IP/32" \
-var "ssh_pub_key=~/.ssh/id_rsa.pub" \
-var "ssh_pvt_key=~/.ssh/id_rsa" \
-var "aws_access_key=ACCESS_KEY"  \
-var "aws_secret_key=ACESS_KEY_SECRET" \
-var "do_token=DIGITAL_OCEAN_TOKEN" \
-var "geoip_account=GEOIP_ACCOUNT" \
-var "geoip_license=GEOIP_LICENSE" \
-var "aws_region=REGION" \
-var "do_ssh_key_name=DO_SSH_KEY_NAME"
```
```
login to your mailbox and verify your addess to allow SES to use it as from
ssh into AWS EC2
```
```
node REGION send_email.js ses-configuration-tf EMAIL success@simulator.amazonses.com
node REGION send_email.js ses-configuration-tf EMAIL bounce@simulator.amazonses.com
node REGION send_email.js ses-configuration-tf EMAIL ooto@simulator.amazonses.com
node REGION send_email.js ses-configuration-tf EMAIL complaint@simulator.amazonses.com
node REGION send_email.js ses-configuration-tf EMAIL suppressionlist@simulator.amazonses.com
```
```
https://SOF-ELK-ip-address:5601
Create index pattern ses-*
Discover
Change index pattern to ses-*
```
```
terraform destroy \
-var "my_email=EMAIL" \
-var "my_ip=IP/32" \
-var "ssh_pub_key=~/.ssh/id_rsa.pub" \
-var "ssh_pvt_key=~/.ssh/id_rsa" \
-var "aws_access_key=ACCESS_KEY"  \
-var "aws_secret_key=ACESS_KEY_SECRET" \
-var "do_token=DIGITAL_OCEAN_TOKEN" \
-var "geoip_account=GEOIP_ACCOUNT" \
-var "geoip_license=GEOIP_LICENSE" \
-var "aws_region=REGION" \
-var "do_ssh_key_name=DO_SSH_KEY_NAME"
```
