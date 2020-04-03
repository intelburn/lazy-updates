#!/bin/bash
./build-inventory.sh
ansible-playbook -i results.yml update.yml
for IP in $(cat results-final); do
    ssh-keygen -R $IP
done