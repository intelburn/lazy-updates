#!/bin/bash
#Run the script to build the inventory file
./build-inventory.sh
#run the Ansible playbook
ansible-playbook -i results.yml update.yml
#remove the SSH fingerprints from the server
for IP in $(cat results-final); do
    ssh-keygen -R $IP
done