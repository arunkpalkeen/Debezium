# Debezium
NSP setup Debezium

## Setup with single kafka node
podman pod create --name kafkapp -p 9000:9000 -p 9092:9092 -p 8083:8083 -p 2181:2181 -p 29092:29092

zookeeper
podman run --name zookeeper --pod kafkapp -dt -e ZOOKEEPER_CLIENT_PORT=2181 -e ZOOKEEPER_TICK_TIME=2000 confluentinc/cp-zookeeper:7.3.2

kafka
podman run --name kafka --pod kafkapp -dt -e KAFKA_BROKER_ID=1 -e KAFKA_ZOOKEEPER_CONNECT=localhost:2181 -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,PLAINTEXT_INTERNAL://localhost:29092 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 -e TOPIC_AUTO_CREATE=true confluentinc/cp-kafka:7.3.2

Kafdrop
podman run --name kafdrop --pod kafkapp -d -e KAFKA_BROKERCONNECT=localhost:9092 -e JVM_OPTS="-Xms32M -Xmx64M" -e SERVER_SERVLET_CONTEXTPATH="/" docker.io/obsidiandynamics/kafdrop:latest

Postgres
podman run --name postgresql -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=Password54321 -p 5432:5432 -v /home/arun/work/debezium/postgres_data_dir:/var/lib/postgresql/data -d docker.io/library/postgres:15
docker.io/library/postgres:15

Note: Update the wal to logical from replica in postgresql.conf file
wal_level = logical



Kafka connect
podman run -itd --name connect --pod kafkapp -e CONNECT_REST_PORT=8083 -e CONNECT_BOOTSTRAP_SERVERS=localhost:29092 -e CONNECT_GROUP_ID=1 -e CONNECT_KEY_CONVERTER=org.apache.kafka.connect.storage.StringConverter -e CONNECT_VALUE_CONVERTER=io.confluent.connect.avro.AvroConverter -e CONNECT_CONFIG_STORAGE_TOPIC=my_connect_configs -e CONNECT_REST_ADVERTISED_HOST_NAME=localhost -e CONNECT_OFFSET_STORAGE_TOPIC=my_connect_offsets -e CONNECT_STATUS_STORAGE_TOPIC=my_connect_statuses -e CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL='http://localhost:8081' -e   CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR="1" -e CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR="1" -e CONNECT_STATUS_STORAGE_REPLICATION_FACTOR="1" -e CONNECT_PLUGIN_PATH=/usr/share/java,/usr/share/confluent-hub-components,/data/connect-jars,/usr/share/filestream-connectors -v /home/arun/work/debezium/ConnectPlugin:/data/connect-jars docker.io/confluentinc/cp-kafka-connect





Plugin for source connector (Debezium Postgres) Plugin for each database,

curl --location 'http://localhost:8083/connectors' --header 'Content-Type: application/json' --data '{
    "name": "cdcdbpluginfresh",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.user": "postgres",
    "database.dbname": "nsp_fresh",
    "database.port": "5432",
    "plugin.name": "pgoutput",
    "key.converter.schemas.enable": "false",
    "topic.prefix": "NSP.fresh",
    "decimal.handling.mode": "string",
    "database.hostname": "192.168.122.1",
    "database.password": "Password54321",
    "value.converter.schemas.enable": "false",
    "name": "cdcdbpluginfresh",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "slot.name" : "fresh"
  }
}'




=> After executing above curl requests verify that the topics are created on kafka with the db table name on kafdrop UI.


ActiveMQ Setup:
podman run --name activemq -itd  -p 61616:61616 -p 8161:8161 rmohr/activemq

Elasticsearch:

podman network create avelastic

podman run -itd --name avelastic --network avelastic -p 9200:9200 -it -m 4GB -e discovery.type=single-node -e xpack.security.enabled=false -e xpack.security.enrollment.enabled=false docker.elastic.co/elasticsearch/elasticsearch:8.8.2

Run the code :


additi@user-pc:~$ podman exec -it avelastic bash
elasticsearch@9ada0d70e8cb:~$ curl http://localhost:9200/stud_2122/_count
{"count":1,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}

#####
### Setup with 3 node kafka cluster 
====== Kafka cluster with 3 partiton

podman pod create --name kafkapp -p 9000:9000 -p 9092:9092 -p 8083:8083 -p 2181:2181 -p 29092:29092 -p 9093:9093 -p 9094:9094 -p 29093:29093 -p 29094:29094

podman run --name zookeeper --pod kafkapp -dt -e ZOOKEEPER_CLIENT_PORT=2181 -e ZOOKEEPER_TICK_TIME=2000 confluentinc/cp-zookeeper:7.3.2


podman run --name kafka1 --pod kafkapp -dt -e KAFKA_BROKER_ID=1 -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka1:9092,PLAINTEXT_INTERNAL://kafka1:29092 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=3 -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=3 -e TOPIC_AUTO_CREATE=true confluentinc/cp-kafka:7.3.2

podman run --name kafka2 --pod kafkapp -dt -e KAFKA_BROKER_ID=2 -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka2:9093,PLAINTEXT_INTERNAL://kafka2:29093 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=3 -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=3 -e TOPIC_AUTO_CREATE=true confluentinc/cp-kafka:7.3.2

podman run --name kafka3 --pod kafkapp -dt -e KAFKA_BROKER_ID=3 -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_INTERNAL:PLAINTEXT -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka3:9094,PLAINTEXT_INTERNAL://kafka3:29094 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=3 -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=3 -e TOPIC_AUTO_CREATE=true confluentinc/cp-kafka:7.3.2

Kafdrop
podman run --name kafdrop --pod kafkapp -d -e KAFKA_BROKERCONNECT=localhost:9092 -e JVM_OPTS="-Xms32M -Xmx64M" -e SERVER_SERVLET_CONTEXTPATH="/" docker.io/obsidiandynamics/kafdrop:latest


Kafka-connect:

podman run -itd --name connect --pod kafkapp \
    -e CONNECT_REST_PORT=8083 \
    -e CONNECT_BOOTSTRAP_SERVERS=kafka1:29092,kafka2:29093,kafka3:29094 \
    -e CONNECT_GROUP_ID=1 \
    -e CONNECT_KEY_CONVERTER=org.apache.kafka.connect.storage.StringConverter \
    -e CONNECT_VALUE_CONVERTER=io.confluent.connect.avro.AvroConverter \
    -e CONNECT_CONFIG_STORAGE_TOPIC=my_connect_configs \
    -e CONNECT_REST_ADVERTISED_HOST_NAME=localhost \
    -e CONNECT_OFFSET_STORAGE_TOPIC=my_connect_offsets \
    -e CONNECT_STATUS_STORAGE_TOPIC=my_connect_statuses \
    -e CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL='http://localhost:8081' \
    -e CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR="3" \
    -e CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR="3" \
    -e CONNECT_STATUS_STORAGE_REPLICATION_FACTOR="3" \
    -e CONNECT_PLUGIN_PATH=/usr/share/java,/usr/share/confluent-hub-components,/data/connect-jars,/usr/share/filestream-connectors \
    -v /home/arun/work/debezium/ConnectPlugin:/data/connect-jars \
    docker.io/confluentinc/cp-kafka-connect

Plugin for source connector (Debezium Postgres) Plugin for each database,

curl --location 'http://localhost:8083/connectors' --header 'Content-Type: application/json' --data '{
    "name": "cdcdbpluginfresh",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.user": "postgres",
    "database.dbname": "nsp_fresh",
    "database.port": "5432",
    "plugin.name": "pgoutput",
    "key.converter.schemas.enable": "false",
    "topic.prefix": "NSP.fresh",
    "decimal.handling.mode": "string",
    "database.hostname": "192.168.122.1",
    "database.password": "Password54321",
    "value.converter.schemas.enable": "false",
    "name": "cdcdbpluginfresh",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "slot.name" : "fresh",
    "topic.num.partitions": "3"
  }
}'


ActiveMQ Setup:
podman run --name activemq -itd  -p 61616:61616 -p 8161:8161 rmohr/activemq

Elasticsearch:


podman network create avelastic

podman run -itd --name avelastic --network avelastic -p 9200:9200 -it -m 4GB -e discovery.type=single-node -e xpack.security.enabled=false -e xpack.security.enrollment.enabled=false docker.elastic.co/elasticsearch/elasticsearch:8.8.2



curl -XGET 'http://localhost:9200/_cluster/health?pretty'

http://localhost:9200/stud_2122/_count
{"count":8,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}

