You may want a play that runs some tasks, and the handlers they notify, before your roles. You may
also want to run tasks in the play after your normal tasks and handlers run. There are two directives
you can use instead of tasks to do this:

• pre_tasks is a tasks section that runs before the roles section.

• post_tasks is a tasks section that runs after the tasks section and any handlers notified by tasks.

The following playbook provides an example with pre_tasks, roles, tasks, post_tasks, and
handlers sections. It is unusual for a play to contain all of these sections.

```yml
- name: Deploying New Application Version
  hosts: webservers
  pre_tasks:
    # Stop monitoring the web server to avoid sending false alarms
    # while the service is updating.
    - name: Disabling Nagios for this host
      nagios:
        action: disable_alerts
        host: "{{ inventory_hostname }}"
        services: http
      delegate_to: nagios-srv
  
  roles:
    - role: deploy-content
  
  tasks:
    - name: Restarting memcached
      service:
        name: memcached
        status: restarted
      notify: Notifying the support team
  
    # Confirm that the application is fully operational
    # after the update.
    - name: Validating the new deployment
      uri:
        url: "http://{{ inventory_hostname }}/healthz"
        return_content: yes
      register: result
      failed_when: "'OK' not in result.content"
  post_tasks:
    - name: Enabling Nagios for this host
      nagios:
        action: enable_alerts
        host: "{{ inventory_hostname }}"
        services: http
      delegate_to: nagios-srv
  
  handlers:
    # Send a message to the support team through Slack
    # every time the memcached service is restarted.
    - name: Notifying the support team
      slack:
        token: G922VJP25/D923DW937/3Ffe373sfhRE6y52Fg3rvf5GlK
        msg: 'Memcached on {{ inventory_hostname }} restarted'
      delegate_to: localhost
      become: false
```
