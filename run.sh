#!/bin/bash


if [ -z ${SMTP_PORT} ]; then echo "SMTP_PORT missing; using 25"; SMTP_PORT=25; fi


if [ -z ${ALLOW_SUBNET} ]; then
	ALLOW_SUBNET=$(awk 'END{print $1}' /etc/hosts | sed 's/[[:digit:]]*$/0\/24/')
	echo "ALLOW_SUBNET missing; using subnet /24 of containers address: ${ALLOW_SUBNET}"
else
	if ! echo ${ALLOW_SUBNET} | grep -Pq "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$"; then
		echo "ALLOW_SUBNET is wrong format; use CIDR notation; exiting..."
		exit
	fi
fi

if [ -z ${MAIL_DOMAIN} ]; then
	if [[ $(postconf -h mydomain) == "localdomain" || $(postconf -h mydomain) == "container.mail" ]]; then
		echo "MAIL_DOMAIN missing, and default (" $(postconf -h mydomain) ") not valid; exiting..."
		exit
	else
		MAIL_DOMAIN=$(postconf -h mydomain)
	fi
fi
if [ -z ${MAIL_HOSTNAME} ]; then MAIL_HOSTNAME=${MAIL_DOMAIN}; fi


postconf -e "smtp_tcp_port = ${SMTP_PORT}"

if ! postconf -h mynetworks | grep -q -F ${ALLOW_SUBNET}; then
	POSTFIX_MYNETWORKS="$(postconf -h mynetworks)"
	postconf -e "mynetworks = ${POSTFIX_MYNETWORKS} ${ALLOW_SUBNET}"
fi

postconf -e "myhostname = ${MAIL_HOSTNAME}"
postconf -e "mydomain = ${MAIL_DOMAIN}"


if [ -f /postfix/conf/transport-pcre ]; then
	echo "found pcre transpor map; applying..."
	postconf -e 'transport_maps = pcre:/postfix/conf/transport-pcre'
	postmap /postfix/conf/transport-pcre
else
	if [ -f /postfix/conf/transport-pcre ]; then
		echo "found hash transpor map; applying..."
		postconf -e 'transport_maps = hash:/postfix/conf/transport-hash'
		postmap /postfix/conf/transport-hash
	else
		postconf -e 'transport_maps = '
	fi
fi


# start daemon
systemctl start rsyslog
postfix start

echo "started postfix"
echo "mirroring /var/log/mail.log to stdout and /var/log/mail.err to stderr"

tail -f /var/log/mail.log &
tail -f /var/log/mail.err 1>&2 &

trap : TERM INT; sleep infinity & wait
# fallback
tail -f /dev/null
