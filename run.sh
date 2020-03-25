#!/bin/bash


if [ -z ${SMTP_PORT} ]; then echo "SMTP_PORT missing; using 25"; SMTP_PORT=25; fi

if [ -z ${MAIL_DOMAIN} ]; then
	if [[ $(postconf -h mydomain) == "localdomain" || $(postconf -h mydomain) == "container.mail" ]]; then
		echo "MAIL_DOMAIN missing and default (" $(postconf -h mydomain) ") not valid; exiting..."
		exit
	else
		MAIL_DOMAIN=$(postconf -h mydomain)
	fi
fi
if [ -z ${MAIL_HOSTNAME} ]; then MAIL_HOSTNAME=${MAIL_DOMAIN}; fi


postconf -e "smtp_tcp_port = ${SMTP_PORT}"
postconf -e "myhostname = ${MAIL_HOSTNAME}"
postconf -e "mydomain = ${MAIL_DOMAIN}"
postconf -e 'mydestination = $myhostname, localhost.$mydomain, $mydomain'
postconf -e 'myorigin = $mydomain'
postconf -e 'smtp_use_tls = no'
postconf -e 'smtp_sasl_auth_enable = no'
postconf -e 'smtp_sasl_security_options = '



# start daemon
systemctl start postfix

echo "started postfix"

trap : TERM INT; sleep infinity & wait
tail -f /dev/null
