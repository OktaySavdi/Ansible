**Check Syntax**
```
ansible-playbook -i inventory.yaml set_permissions.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml group.yaml --extra-vars "new_quota=ml new_quota2=xl namespace=oktay prj_action=update" -vvv
```
```
ansible-playbook -i inventory.yaml group.yaml --extra-vars "new_quota=ml new_quota2=xl namespace=oktay prj_action=get" -vvv
```
