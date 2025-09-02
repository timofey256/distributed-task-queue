## Installation

Install your default package, or if you have Nix package manager, run `nix-shell` from root and set up the node in your `configuration.nix`.

Here is the default config for `configuraiton.nix`:

```
services.zookeeper.enable = true;

services.apache-kafka = {
	enable = true;

	settings = {
		"broker.id" = 0;
		"process.roles" = ["broker" "controller"];
		"node.id" = 0;
	      "controller.quorum.voters" = [ "0@127.0.0.1:9093" ];

		      listeners = [
			"PLAINTEXT://:9092"
			"CONTROLLER://:9093"
			];
			"advertised.listeners" = [ "PLAINTEXT://localhost:9092" ];
		        "controller.listener.names" = ["CONTROLLER"];

			"zookeeper.connect" = [ "localhost:2181" ];
			"log.dirs" = [ "/var/lib/kafka-logs" ];
			"num.partitions" = 1;
			"offsets.topic.replication.factor" = 1;
	};
};
```

---

## Useful commands

Create new topic
```
/usr/local/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic my-new-topic --partitions 1 --replication-factor 1
```

Check list of available topics:
```
/usr/local/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Check if your broker is alive:
```
/usr/local/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

Check on a specific consumer group:
```
/usr/local/kafka/bin/kafka-consumer-groups.sh --bootstrap-server [BROKER HOST:PORT] --describe --group [CONSUMER GROUP NAME]
```

How to start kafka:
```
(base) tymofii@fedora:~/repos/distributed-task-queue$ /usr/local/kafka/bin/kafka-storage.sh random-uuid
4EItA6EfQLurmMmgUgxDPQ


(base) tymofii@fedora:~/repos/distributed-task-queue$ /usr/local/kafka/bin/kafka-storage.sh format -t 4EItA6EfQLurmMmgUgxDPQ -c /usr/local/kafka/config/server.properties --standalone
Formatting dynamic metadata voter directory /tmp/kraft-combined-logs with metadata.version 4.0-IV3.


(base) tymofii@fedora:~/repos/distributed-task-queue$ sudo /usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
```

## Create new topic
```
kafka-topics.sh --bootstrap-server localhost:9092 --create --topic my-new-topic --partitions 1 --replication-factor 1
```

## Check list of available topics:
```
kafka-topics.sh --bootstrap-server localhost:9092 --list
```

## Check if your broker is alive:
```
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

## Check on a specific consumer group:
```
kafka-consumer-groups.sh --bootstrap-server [BROKER HOST:PORT] --describe --group [CONSUMER GROUP NAME]
```

## How to start kafka:
```
kafka-storage.sh random-uuid 4EItA6EfQLurmMmgUgxDPQ

kafka-storage.sh format -t 4EItA6EfQLurmMmgUgxDPQ -c /usr/local/kafka/config/server.properties --standalone
Formatting dynamic metadata voter directory /tmp/kraft-combined-logs with metadata.version 4.0-IV3.

kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
```
