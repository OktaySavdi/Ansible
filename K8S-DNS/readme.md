
## Creating DNS A record for Kubernetes API cluster IP 
**Check Syntax**
```
ansible-playbook DNSRecord.yaml --syntax-check
```
**Run Playbook**
```
ansible-playbook DNSRecord.yaml --extra-vars "env=stg cluster_name=test-commvault ip_address=10.10.10.10" -vvv
```
**Module**

https://github.com/ansilabnl/micetro

**Examples**
DNS record setting example

```yaml
- name: Set DNS record in zone for a defined name
  ansilabnl.micetro.dnsrecord:
    state: present
    name: beatles
    data: 172.16.17.2
    rrtype: A
    dnszone: example.net.
    mm_provider: "{{ mm_provider }}"
  delegate_to: localhost

- name: Set PTR record in zone for a defined name
  ansilabnl.micetro.dnsrecord:
    state: present
    name: "2.17.16.172.in-addr.arpa."
    data: beatles.example.net.
    rrtype: PTR
    dnszone: "17.16.172.in-addr.arpa."
    mm_provider: "{{ mm_provider }}"
  delegate_to: localhost

- name: Set MX record
  ansilabnl.micetro.dnsrecord:
    state: present
    name: beatles
    rrtype: MX
    dnszone: example.net.
    data: "10 ringo"
    ttl: 86400
    mm_provider: "{{ mm_provider }}"
  delegate_to: localhost
```