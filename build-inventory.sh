#!/bin/bash
CREDS=creds.csv
rm results-dirty results-ips
IPRANGE=10.0.5.0/24
nmap -qqq -Pn -p 22 --open -oG results-dirty $IPRANGE
cat results-dirty | grep ssh | cut -d ':' -f 2 | cut -d ' ' -f 2 > results-ips
ip a | grep inet | cut -d '/' -f 1 | tr -d inet | tr -d '6 ' >> results-ignores
diff results-ignores results-ips --suppress-common-lines | grep '>' | cut -d ' ' -f 2 > results-final
> results.yml
echo "all:" >> results.yml
echo "  hosts:" >> results.yml
for IPADDR in $(cat results-final); do
    cat results-dirty | grep $IPADDR
    select username in $(cut -d, -f1 $CREDS); do
        USERNAME=$username
        PASSWORD=$(grep $username $CREDS | cut -d, -f2)
        break
    done
    ssh-copy-id $USERNAME@$IPADDR
    echo "    $IPADDR:" >> results.yml
    echo "      ansible_user: $USERNAME" >> results.yml
    echo "      ansible_become_password: $PASSWORD" >> results.yml
done
