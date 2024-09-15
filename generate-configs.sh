#!/bin/bash

IP_ADDRESS=`curl api.ip.sb`


echo -n "Enter L2TP Username(blank to generate random string): "; read USERNAME
echo -n "Enter L2TP Password(blank to generate random string): "; read PASSWORD
echo -n "Enter L2TP PSK(blank to generate random string): "; read PSK

if [[ ${USERNAME} == '' ]]; then USERNAME=`echo ${RANDOM} | md5sum | head -c 12`; fi
if [[ ${PSK} == '' ]]; then PSK=`echo ${RANDOM} | md5sum | head -c 12`; fi
if [[ ${PASSWORD} == '' ]]; then PASSWORD=`echo ${RANDOM} | md5sum | head -c 12`; fi

cat << EOF > /opt/vpn.env
VPN_USER=${USERNAME}
VPN_PASSWORD=${PASSWORD}
VPN_IPSEC_PSK=${PSK}
VPN_DNS_SRV1=8.8.8.8
VPN_DNS_SRV2=8.8.4.4
EOF

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

IPsec VPN server is now ready for use!

Connect to your new VPN with these details:

Server IP: ${IP_ADDRESS}
Username: ${USERNAME}
Password: ${PASSWORD}
IPsec PSK: ${PSK}
SS URL: ${SS_URL}

A more chinese friendly version:

L2TP_VPN
IP地址: ${IP_ADDRESS}
用户: ${USERNAME}
密码: ${PASSWORD}
密钥: ${PSK}
SS 链接：${SS_URL}
================================================
EOF
cat /root/vpn_config.txt
