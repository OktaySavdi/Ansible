**Check Syntax**
```
ansible-playbook -i inventory.yaml CIS-Bencmark.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml CIS-Bencmark.yaml --extra-vars "cluster_master1=100.100.100.100" -vvv
```
