# redis-cluster
## Config redis sentinel and haproxy

![redis-ha-with-haproxy-2](https://user-images.githubusercontent.com/56550682/117958281-11579580-b345-11eb-8f12-4618de5aea7d.jpg)

IPMASTER  master    sentinel 1

IPSLAVE1  slave-1   sentinel 2

IPSLAVE2  slave-2   sentinel 3

### Config Redis
1. Install redis on all servers
```bash
yum update -y
yum groupinstall -y 'Development Tools'
yum install -y wget
cd /opt
wget download.redis.io/releases/redis-5.0.5.tar.gz
tar -xf redis-5.0.5.tar.gz
cd redis-5.0.5
make
make install
mkdir -p /etc/redis /var/run/redis /var/log/redis /var/redis/
cp redis.conf redis.conf.bak
cp redis.conf /etc/redis/redis.conf
adduser redis -M -g daemon
passwd -l redis
chown -R redis:daemon /opt/redis-5.0.5
chown -R redis:daemon /var/run/redis
chown -R redis:daemon /var/log/redis
chown -R redis:daemon /var/redis/
```
2. Config Redis on Master Server
```bash
mv /etc/redis/redis.conf /etc/redis/redis.conf.bk
vim /etc/redis/redis.conf
```
  Add to file redis.conf, remember change to your IP
```bash
>>>
bind IPMASTER
port 6379
daemonize yes
pidfile "/var/run/redis/redis.pid"
logfile "/var/log/redis/redis.log"
dir "/var/redis/"
<<<
```
3. Config Redis on Slave-1
```bash
mv /etc/redis/redis.conf /etc/redis/redis.conf.bk
vim /etc/redis/redis.conf
```
  Add to file redis.conf, remember change to your IP
```bash
>>>
bind IPSALVE1
port 6380
daemonize yes
pidfile "/var/run/redis/redis.pid"
logfile "/var/log/redis/redis.log"
dir "/var/redis/"
slaveof IPMASTER 6379
<<<
```

4. Config Redis on slave-2
```bash
mv /etc/redis/redis.conf /etc/redis/redis.conf.bk
vim /etc/redis/redis.conf
```
  Add to file redis.conf, remember change to your IP
```bash
>>>
bind IPSALVE2
port 6381
daemonize yes
pidfile "/var/run/redis/redis.pid"
logfile "/var/log/redis/redis.log"
dir "/var/redis/"
slaveof IPMASTER 6379
<<<
```
5. Config file system & run redis on 3 nodes
  Copy file redis.service to /etc/systemd/system/
```bash
chown -R redis:daemon /etc/redis/redis.conf
systemctl start redis.service
systemctl enable redis.service
```
6. Test replication
  
  On Master Server
```bash
/usr/local/bin/redis-cli -h IPMASTER -p 6379
IPMASTER:6379> set foo thichanxoai
```

  On Slave Server
```bash
/usr/local/bin/redis-cli -h IPSLAVE -p [port redis slave]
IPMASTER:6379> get foo
"thichanxoai"
```

### Config Redis Sentinel
1. Config Redis Sentinel on Master

  Add to file /etc/redis/sentinel.conf, remember change to your IP
```bash
>>>
bind IPMASTER
port 16379
protected-mode no
daemonize yes
sentinel monitor redis-cluster IPMASTER 6379 2
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
pidfile "/var/run/redis/sentinel.pid"
logfile "/var/log/redis/sentinel.log"
dir "/var/redis/"
<<<
```
  Run command:
```bash
chown -R redis:daemon /etc/redis/sentinel.conf
```

2. Config Redis Sentinel on Slave-1

  Add to file /etc/redis/sentinel.conf, remember change to your IP
```bash
>>>
bind IPSLAVE1
port 16380
protected-mode no
daemonize yes
sentinel monitor redis-cluster IPMASTER 6379 2
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
pidfile "/var/run/redis/sentinel.pid"
logfile "/var/log/redis/sentinel.log"
dir "/var/redis/"
<<<
```
  Run command:
```bash
chown -R redis:daemon /etc/redis/sentinel.conf
```

3. Config Redis Sentinel on Slave-2

  Add to file /etc/redis/sentinel.conf, remember change to your IP
```bash
>>>
bind IPSLAVE2
port 16381
protected-mode no
daemonize yes
sentinel monitor redis-cluster IPMASTER 6379 2
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
pidfile "/var/run/redis/sentinel.pid"
logfile "/var/log/redis/sentinel.log"
dir "/var/redis/"
<<<
```
  Run command:
```bash
chown -R redis:daemon /etc/redis/sentinel.conf
```

4. Config file system & run redis on 3 nodes
  Copy file sentinel.service to /etc/systemd/system/
```bash
chown -R redis:daemon /etc/redis/sentinel.conf
systemctl start sentinel.service
systemctl enable sentinel.service
```

5. Test failover
  On Master server
Command enable mode debug, tailf /var/log/redis/sentinel.log to see process select master node
```bash
/usr/local/bin/redis-cli -h IPMASTER -p 16379
IPMASTER:16379>DEBUG sleep 60
```

Command switch preventive master node 
```bash
IPMASTER:16379>SENTINEL failover <master cluster name>
```

Show present master
```bash
IPMASTER:16379>SENTINEL masters
```

### Config HAProxy
Add all line from haproxy.cfg to your present config

Web stat only green on master node
