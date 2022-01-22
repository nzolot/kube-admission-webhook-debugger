#!/usr/bin/env bash

DIR=$1
CN=$2
NAME=$3
NAMESPACE=$4

: ${1?'missing key directory'}



chmod 0700 "$DIR"
cd "$DIR"

if [ ! -f server.conf ]; then
cat >server.conf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
CN = ${NAME}.${NAMESPACE}.svc
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${NAME}.${NAMESPACE}.svc
DNS.2 = ${NAME}
EOF
fi

# Generate the CA cert and private key
if [ ! -f ca.key ] || [ ! -f ca.crt ];then
  openssl req -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=${CN}"
fi
# Generate the private key for the webhook server
if [ ! -f webhook-server-tls.key ] ;then
  openssl genrsa -out webhook-server-tls.key 2048
fi
# Generate a Certificate Signing Request (CSR) for the private key, and sign it with the private key of the CA.
if [ ! -f webhook-server-tls.crt ] ;then
  openssl req -new -key webhook-server-tls.key -subj "/CN=${NAME}.${NAMESPACE}.svc" -config server.conf \
    | openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook-server-tls.crt -extensions v3_req -extfile server.conf
fi
