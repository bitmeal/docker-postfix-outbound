**[probably broken]**

# docker-postfix-outbound
Simple docker container to use postfix for outbound mail sending. Intended for applications that need to send verification/notification mails, but do not need a full mailserver.

## config
arguments for building:
* `DOMAIN` set your domain while building

use following envvars when starting with `--env / -e`:
* `SMTP_PORT`: defaults to 35
* `ALLOW_SUBNET`: subnet in CIDR notation, to accept mails from. will default to the /24 subnet of the containers ip if not given
* `MAIL_DOMAIN`: defaults to domain set while building container (if set and valid)
* `MAIL_HOSTNAME`: optional, will be set to `MAIL_DOMAIN` if missing


example commandline:
```bash
docker run -d --env SMTP_PORT=10025 --env MAIL_DOMAIN=my.domain --name postfix --network mynetwork --network-alias mailsender postfix
```

## build
```bash
docker build --tag postfix .
```