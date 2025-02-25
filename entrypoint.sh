#!/bin/bash
set -e

USERNAME=${USERNAME:-user}
PASSWORD=${PASSWORD:-pass}
ALLOW=${ALLOW:-10.0.0.0/8 192.168.0.0/16 172.16.0.0/12 127.0.0.1/32}
VOLUME=${VOLUME:-/data}

setup_rsyncd(){
	echo "$USERNAME:$PASSWORD" > /etc/rsyncd.secrets
    chmod 0400 /etc/rsyncd.secrets
	[ -f /etc/rsyncd.conf ] || cat > /etc/rsyncd.conf <<EOF
log file = /dev/stdout
timeout = 300
max connections = 10
port = 8873

[volume]
	uid = root
	gid = root
	hosts deny = *
	hosts allow = ${ALLOW}
	read only = false
	path = ${VOLUME}
	comment = ${VOLUME} directory
	auth users = ${USERNAME}
	secrets file = /etc/rsyncd.secrets
	lock file = /etc/rsyncd.lock
	use chroot = false
EOF
}

mkdir -p $VOLUME
setup_rsyncd
exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"

exec "$@"
