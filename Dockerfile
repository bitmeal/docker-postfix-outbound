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


COPY run.sh /postfix/


SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/postfix/run.sh"]
CMD []
