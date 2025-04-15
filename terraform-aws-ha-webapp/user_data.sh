#!/bin/bash
yum update -y
amazon-linux-extras install ansible2 -y
git clone git clone https://github.com/gurjyotanand/terraform_anisble_high_availability_server_project.git
 /tmp/ansible
ansible-playbook /tmp/ansible/webserver.yml