FROM ubuntu:bionic

ARG DOMAIN=container.mail

RUN	export DEBIAN_FRONTEND=noninteractive && \
	apt-get update && apt-get install -y apt-utils && \
    echo "postfix postfix/mailname string $DOMAIN" | debconf-set-selections &&\
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections &&\
    apt-get install -y mailutils wget

RUN	wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py -O /usr/local/bin/systemctl && \
    chmod +x /usr/local/bin/systemctl && \
    apt-get install -y python-minimal

RUN postconf -e 'mydestination = $myhostname, localhost.$mydomain, $mydomain' && \
    postconf -e 'myorigin = $mydomain' && \
    postconf -e 'smtp_use_tls = no' && \
    postconf -e 'smtp_sasl_auth_enable = no' && \
    postconf -e 'smtp_sasl_security_options = ' && \
    postconf -e 'relay_domains = $mydomain' && \
    postconf -e 'smtpd_tls_security_level = none' && \
    cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

RUN while touch $(postfix set-permissions 2>&1 | grep -oP "'\K.*(?=')") 2> /dev/null ; do :; done; postfix set-permissions && \
    rm -rf /usr/share/man/man8/* && rm -rf /usr/share/man/man5/* && rm -rf /usr/share/man/man1/*

COPY run.sh /postfix/


SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/postfix/run.sh"]
CMD []
