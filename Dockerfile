FROM alpine:latest

COPY mullvad_ca.crt /etc/openvpn/
COPY mullvad.conf /etc/openvpn/
COPY update-resolv-conf /etc/openvpn/
COPY sockd.conf /etc/
COPY run.sh /app/
COPY entrypoint.sh /app/

RUN apk add --no-cache bash openvpn dante-server \
    && chmod +x /etc/openvpn/update-resolv-conf \
    && chmod +x /app/run.sh \
    && chmod +x /app/entrypoint.sh

EXPOSE 1080

ENTRYPOINT  [ "/app/entrypoint.sh" ]
CMD [ "/app/run.sh" ]
