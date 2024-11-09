#!/bin/bash

IP_ADDRESS=`curl api.ip.sb`

SS_PASSWORD=`tr -dc 'A-Za-z0-9!@$%#^' </dev/urandom | head -c 13`

cat << EOF > /opt/shadowsocks-config.json
{
    "server":"0.0.0.0",
    "server_port":9000,
    "password":"${SS_PASSWORD}",
    "timeout":300,
    "method":"aes-256-gcm",
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF

docker compose up -d
if [[ $? -ne 0 ]]; then
  echo "having error deployment"; exit 1

else
  echo "deployments run successfully"
fi

sleep 2

SS_URL=`docker exec -it ss-rust ssurl --encode /etc/shadowsocks-rust/config.json| sed "s|0.0.0.0|${IP_ADDRESS}|"`
echo "${SS_URL}"

cat << EOF > /root/vpn_config.txt
================================================
SS URL: ${SS_URL}
================================================
EOF
cat /root/vpn_config.txt
