**Check Syntax**
```
ansible-playbook -i inventory.yaml tcp_dump.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook -i inventory.yaml tcp_dump.yaml --extra-vars "cluster=lab-cluster1 pod_name: ark-cache-api-v0-13-d426r ftp_server=myftpserver ftp_path=tcpdump" -vvv
```
