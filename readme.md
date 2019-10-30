
# Ansible Installation Automation

-   Ansible 2.8.5
-   Compatible with most versions of RHEL 7.6


## Redis Cluster + Stunnel
Redis Cluster is a distributed implementation of Redis with the following goals, in order of importance in the design:

-   High performance and linear scalability up to 1000 nodes. There are no proxies, asynchronous replication is used, and no merge operations are performed on values.
-   An acceptable degree of write safety: the system tries (in a best-effort way) to retain all the writes originating from clients connected with the majority of the master nodes. Usually, there are small windows where acknowledged writes can be lost. Windows to lose acknowledged writes are larger when clients are in a minority partition.
-   Availability: Redis Cluster is able to survive partitions where the majority of the master nodes are reachable and there is at least one reachable slave for every master node that is no longer reachable. Moreover using  _replicas migration_, masters no longer replicated by any slave will receive one from a master which is covered by multiple slaves.

## Redis-Sentinel + Stunnel
Redis Sentinel is a high availability solution for  [Redis](https://redis.io/), an open-source, in-memory data structure store that can be used as a non-relational key-value database. The goal of Redis Sentinel is to manage Redis instances via three different functions: monitoring your Redis deployment, sending notifications if something is amiss, and automatically handling the failover process by creating a new master node.

As a distributed system, Redis Sentinel is intended to run together with other Sentinel processes. This reduces the likelihood of false positives when detecting that a master node has failed, and also inoculates the system against the failure of any single process.

The creators of Redis Sentinel recommend that you have at least three Sentinel instances in order to have a robust Sentinel deployment. These instances should be distributed across computers that are likely to fail independently of each other, such as those that are located in different geographical areas.


## Elasticsearch Cluster + Kibana

**What is Elasticsearch used for?**

The speed and scalability of Elasticsearch and its ability to index many types of content mean that it can be used for a number of use cases:

-   Application search
-   Website search
-   Enterprise search
-   Logging and log analytics
-   Infrastructure metrics and container monitoring
-   Application performance monitoring
-   Geospatial data analysis and visualization
-   Security analytics
-   Business analytics

**What is Kibana used for?**

Kibana is a data visualization and management tool for Elasticsearch that provides real-time histograms, line graphs, pie charts, and maps. Kibana also includes advanced applications such as Canvas, which allows users to create custom dynamic infographics based on their data, and Elastic Maps for visualizing geospatial data.

## RabbitMQ Cluster

RabbitMQ is one part of Message Broker that implemented Advance Message Queue Protocol (AMQP), that help your application to communicate each other, when you extends your application scale.


![](https://miro.medium.com/max/1206/1*HoAG-7IhLaXShPJG-g9kvA.png)

RabbitMQ also called as middleware build using  [**Erlang**](https://www.erlang.org/), due it can be both micro-services and an app.  **RabbitMQ support multiple protocols**, here is the protocol that RabbitMQ support:  
- AMQP  
- HTTP  
- STOMP  
- MQTT

## Kafka Cluster
Apache Kafka is a community distributed event streaming platform capable of handling trillions of events a day. Initially conceived as a messaging queue, Kafka is based on an abstraction of a distributed commit log. Since being created and open sourced by LinkedIn in 2011, Kafka has quickly evolved from messaging queue to a full-fledged event streaming platform.

[Kafka](https://kafka.apache.org/)’s growth is exploding. More than one-third of all Fortune 500 companies use Kafka. These companies include the top ten travel companies, seven of the top ten banks, eight of the top ten insurance companies, nine of the top ten telecom companies, and much more. LinkedIn, Microsoft, and Netflix process four-comma messages a day with Kafka (1,000,000,000,000).

**Kafka is used for real-time streams of data, to collect big data, or to do real time analysis (or both)**. Kafka is used with in-memory microservices to provide durability and it can be used to feed events to **CEP** (complex event streaming systems) and IoT/IFTTT-style automation systems.
