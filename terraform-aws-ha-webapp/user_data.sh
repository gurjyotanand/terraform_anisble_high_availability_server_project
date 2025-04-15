#!/bin/bash
yum update -y
amazon-linux-extras install ansible2 -y
git clone https://github.com/yourusername/ansible-config.git /tmp/ansible
ansible-playbook /tmp/ansible/webserver.yml