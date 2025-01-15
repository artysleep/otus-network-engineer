#!/bin/bash
cd /home/user/ansible
ansible-playbook plays/cisco/sh_run.yml --vault-pass-file vault_pass.txt 
cd /home/user/reports
git add .
git commit -m $(date '+%Y-%m-%d')