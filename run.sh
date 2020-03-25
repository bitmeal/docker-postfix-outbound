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
#postconf -e 'mydestination = $myhostname, localhost.$mydomain, $mydomain'
#postconf -e 'myorigin = $mydomain'
#postconf -e 'smtp_use_tls = no'
#postconf -e 'smtp_sasl_auth_enable = no'
#postconf -e 'smtp_sasl_security_options = '
#postconf -e 'relay_domains = $mydomain'
#postconf -e 'smtpd_tls_security_level = none'


#cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

# start daemon
systemctl start rsyslog
#postfix set-permissions
postfix start

echo "started postfix"

trap : TERM INT; sleep infinity & wait
tail -f /dev/null
