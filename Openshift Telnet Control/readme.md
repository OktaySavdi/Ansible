**Check Syntax**
```
ansible-playbook -i inventory.yaml telnet_control.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml telnet_control.yaml --extra-vars "cluster=ocp-cluster1 namespace=oktay-dev dest=mywebserver port=443 usermail=oktaysavdi@mydomain.com job_id=12431" -vvv
```
