#!/usr/bin/env bash

set -euo pipefail

NAME="kube-admission-webhook-debugger"
NAMESPACE="playground"

BASE_DIR="$(dirname "$0")/deployment"
KEY_DIR="${BASE_DIR}/keys"
mkdir -p ${KEY_DIR}

# Generate keys into a temporary directory.
echo "Generating TLS keys ..."
"${BASE_DIR}/generate-keys.sh" "$KEY_DIR" "Flask Webhook Test CA" "${NAME}" "${NAMESPACE}"

# Create the `webhook-demo` namespace. This cannot be part of the YAML file as we first need to create the TLS secret,
# which would fail otherwise.
echo "Creating Kubernetes objects ..."
sed -e 's@${NAMESPACE}@'"${NAMESPACE}"'@g' <"${BASE_DIR}/template-ns.yaml" \
    | kubectl apply -f -

# Create the TLS secret for the generated keys.
kubectl -n ${NAMESPACE} create secret tls webhook-server-tls \
    --cert "${KEY_DIR}/webhook-server-tls.crt" \
    --key "${KEY_DIR}/webhook-server-tls.key" \
    -o yaml --dry-run=client \
    | kubectl apply -f -

# Read the PEM-encoded CA certificate, base64 encode it, and replace the `${CA_PEM_B64}` placeholder in the YAML
# template with it. Then, create the Kubernetes resources.
CA_PEM_B64="$(openssl base64 -A <"${KEY_DIR}/ca.crt")"

cat deployment/template-deployment.yaml \
  | sed -e 's@${CA_PEM_B64}@'"$CA_PEM_B64"'@g' \
  | sed -e 's@${NAME}@'"$NAME"'@g' \
  | sed -e 's@${NAMESPACE}@'"$NAMESPACE"'@g' \
  | kubectl apply -f -

# Delete the key directory to prevent abuse (DO NOT USE THESE KEYS ANYWHERE ELSE).
#rm -rf "$KEY_DIR"

echo "The webhook server has been deployed and configured!"
