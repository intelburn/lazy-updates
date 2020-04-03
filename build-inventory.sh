#!/bin/bash
#File where the creds to the machines can be found
CREDS=creds.csv
#Clean up after any previous run
rm results-dirty results-ips
#IP range where the VMs can be found.
#Change this to match your environmnet
IPRANGE=10.0.5.0/24
#Run nmap to locate VMs
nmap -qqq -Pn -p 22 --open -oG results-dirty $IPRANGE
#Clean up so that only IP addresses remain
cat results-dirty | grep ssh | cut -d ':' -f 2 | cut -d ' ' -f 2 > results-ips
#Located the IP address of the machine running the script
#Any other IP addresses that should be ignored can be added to results-ignores
ip a | grep inet | cut -d '/' -f 1 | tr -d inet | tr -d '6 ' >> results-ignores
#Do a diff to find all IP address that should not be ignored
diff results-ignores results-ips --suppress-common-lines | grep '>' | cut -d ' ' -f 2 > results-final
#Clean up the results inventory file to be used by Ansible
> results.yml
#Set up the inventory file
echo "all:" >> results.yml
echo "  hosts:" >> results.yml
#Loop thru the IP addresses
for IPADDR in $(cat results-final); do
    #Print out the infomration about the host for the user
    cat results-dirty | grep $IPADDR
    #Ask user for creds base on the creds file
    select username in $(cut -d, -f1 $CREDS); do
        USERNAME=$username
        PASSWORD=$(grep $username $CREDS | cut -d, -f2)
        break
    done
    #Make sure that the SSH key is on the VM
    ssh-copy-id $USERNAME@$IPADDR
    #Add the information about the VM to the inventory file
    echo "    $IPADDR:" >> results.yml
    echo "      ansible_user: $USERNAME" >> results.yml
    echo "      ansible_become_password: $PASSWORD" >> results.yml
done
