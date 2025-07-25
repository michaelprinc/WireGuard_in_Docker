FROM alpine:latest

RUN apk add --no-cache gettext

RUN apk update && apk add --no-cache wireguard-tools gettext bash dos2unix iptables ip6tables tcpdump iproute2 curl

COPY entrypoint.sh /entrypoint.sh
COPY wg0.conf.tpl /wg0.conf.tpl

# Přidej výchozí .env soubor
COPY .env.template /wg/.env
RUN dos2unix /wg/.env && chmod +x /wg/.env

# Oprava řádkování na Unix LF
RUN dos2unix /entrypoint.sh && chmod +x /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
