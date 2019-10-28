

# Ansible Kafka Cluster

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6
-   Kafka Cluster
  
![kafka cluster](https://user-images.githubusercontent.com/3519706/67663697-2513f480-f977-11e9-9855-bc6bfe735a99.png)

## Getting started

Below are a few example playbooks and configurations for deploying a variety of Kafka architectures.
This role expects to be run as root

## Installation

I use a **nexus server** because my computer cannot access the **internet**. 
you may not use nexus so install the version you want to download **.rpm** 
files and put them to the address below.

> jdk-*_linux-x64_bin.rpm : [JDK11 Download](https://www.oracle.com/technetwork/java/javase/downloads/jdk11-downloads-5066655.html)
>  kafka.tgz : [Kafka Download](https://www.apache.org/dist/kafka/2.3.0/kafka_2.12-2.3.0.tgz)

    roles/rbtmq_install/files

and change this field

    roles/rbtmq_install/vars/main.yml

> **rbmq_rpm :** jdk-11.0.5_linux-x64_bin.rpm
> **kafka.tgz :** kafka.tgz

**Check Syntax**

    ansible-playbook playbook.yml -i inventor.txt --syntax-check

**Run Playbook**

    ansible-playbook playbook.yml -i inventor.txt

## Check Kafka Cluster

Create Topic

    /opt/kafka/bin/kafka-topics.sh --zookeeper master:2181/kafka --create --topic test --partitions 3 --replication-factor 2

List Topic

    /opt/kafka/bin/kafka-topics.sh --zookeeper master:2181/kafka --topic test --describe

![Kafka Cluster Topic](https://user-images.githubusercontent.com/3519706/67664239-4cb78c80-f978-11e9-82e0-2935df31e4b2.png)

## Service Status

    systemctl status kafka
    systemctl status zookeeper
