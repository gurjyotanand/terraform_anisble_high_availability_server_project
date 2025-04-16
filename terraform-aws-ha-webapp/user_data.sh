#!/bin/bash
yum update -y
sudo yum install -y ansible
git clone https://github.com/gurjyotanand/terraform_anisble_high_availability_server_project.git /tmp/terraform_anisble_high_availability_server_project
ansible-playbook /tmp/terraform_anisble_high_availability_server_project/ansible-config/webserver.yml