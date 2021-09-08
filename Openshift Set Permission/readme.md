**Check Syntax**
```
ansible-playbook -i inventory.yaml set_permissions.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml set_permissions.yaml --extra-vars "cluster=ocp-cluster1 team=infrastructure namespace=oktay-dev group=CI-Infrastructure and Communication" -vvv
```
