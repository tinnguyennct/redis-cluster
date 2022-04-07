#!/bin/bash
#README
#Copy this script to master redis node, sure was setup ssh key between from master to two slave nodes.
#Excute this script by run command "/path_to_script/install-redis.sh [IP of slave1] [IP of slave2]". Example: /opt/redis/install-redis.sh 10.10.10.10 10.10.10.11
####
#Input address of slave
slave1="$1"
slave2="$2"
r_port=6379
s_port=26379
password="aFx7YuhR6hGm9vPB"
#Get info ip address
deviceNIC=$(ip ad | grep ens | awk 'NR==1{print $2}' | cut -d : -f 1);
masterIP=$(ip addr show $deviceNIC | grep "inet " | awk '{print $2}' | cut -d / -f 1);

#Create file config Master
permission() {
mkdir -p /opt/redis/config
mkdir -p /opt/redis/redis-data
mkdir -p /opt/redis/sentinel-data
chown -R 1001:1001 /opt/redis/redis-data
chown -R 1001:1001 /opt/redis/sentinel-data
}

#Config system parameters
systemconfig() {
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "transparent_hugepage=never" >> /etc/rc.local
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "fs.file-max=500000" >> /etc/sysctl.conf
sysctl -p
}

masterconfig() {
cat <<EOF | sudo tee /opt/redis/config/redis.conf
bind $masterIP
port $r_port
requirepass "$password"
daemonize no
masterauth "$password"
maxclients 40000
timeout 300
tcp-keepalive 60
maxmemory 256mb
maxmemory-policy allkeys-lru
pidfile "/var/run/redis/redis.pid"

#RDB - AOF Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
dbfilename "dump.rdb"

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 80
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
EOF

cat <<EOF | sudo tee /opt/redis/config/sentinel.conf
bind $masterIP
port $s_port
daemonize no
sentinel monitor redis-cluster $masterIP $r_port 2
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
sentinel auth-pass redis-cluster $password
pidfile "/var/run/redis/sentinel.pid"
EOF
}

slaveconfig() {
cat  <<EOF | sudo tee /opt/redis/config/redis.conf
bind $1
port $2
requirepass "$3"
daemonize no
masterauth "$3"
slaveof $4 $5
maxclients 40000
#RDB - AOF Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
dbfilename "dump.rdb"
timeout 300
tcp-keepalive 60
maxmemory 256mb
maxmemory-policy allkeys-lru
pidfile "/var/run/redis/redis.pid"

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 80
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
EOF

cat <<EOF | sudo tee /opt/redis/config/sentinel.conf
bind $6
port $7
daemonize no
sentinel monitor redis-cluster $4 $5 2
sentinel down-after-milliseconds redis-cluster 5000
sentinel parallel-syncs redis-cluster 1
sentinel failover-timeout redis-cluster 10000
sentinel auth-pass redis-cluster $3
pidfile "/var/run/redis/sentinel.pid"
EOF
}

compose() {
cat <<EOF | sudo tee /opt/redis/docker-compose.yml
version: '3.1'
services:
  redis:
    image: redis:5.0.12
    container_name: redis
    restart: always
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - ./redis-data:/data
      - ./config:/usr/local/etc/redis
    network_mode: "host"

  sentinel:
    image: redis:5.0.12
    container_name: sentinel
    restart: always
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - ./config:/usr/local/etc/redis
      - ./sentinel-data:/data
    network_mode: "host"
EOF

#Start redis master
cd /opt/redis
docker-compose up -d
}

#Call func
permission
systemconfig
masterconfig
compose

###########Config on slave
user=root
host=($slave1 $slave2)

#Slave1
typeset -f permission | ssh $user@${host[0]} "$(cat); permission"
typeset -f systemconfig | ssh $user@${host[0]} "$(cat); systemconfig"
typeset -f slaveconfig | ssh $user@${host[0]} "$(cat); slaveconfig ${host[0]} $r_port $password $masterIP $r_port ${host[0]} $s_port"
typeset -f compose | ssh $user@${host[0]} "$(cat); compose"

#Slave2
typeset -f permission | ssh $user@${host[1]} "$(cat); permission"
typeset -f systemconfig | ssh $user@${host[1]} "$(cat); systemconfig"
typeset -f slaveconfig | ssh $user@${host[1]} "$(cat); slaveconfig ${host[1]} $r_port $password $masterIP $r_port ${host[1]} $s_port"
typeset -f compose | ssh $user@${host[1]} "$(cat); compose"
