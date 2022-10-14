**Check Syntax**
```
ansible-playbook -i inventory.yaml commvault.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml commvault.yaml --extra-vars "cluster_ip=100.100.100.100 cluster_name=test-commvault commvault_env=stg username=my-stg-sp@mydomain.com password=*** webUrl=my-commvault-stg.comsa_token=hfsjkdfhjksdhfjks..." -vvv
```
