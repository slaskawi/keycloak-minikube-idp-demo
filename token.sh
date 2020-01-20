#!/bin/bash

set -x

KEYCLOAK_HOST=192-168-0-8.nip.io

TOKEN=$(curl -s --cacert ./client.pem "https://${KEYCLOAK_HOST}:8443/auth/realms/kubernetes/protocol/openid-connect/token" -d grant_type=password -d response_type=id_token -d scope=email -d client_id="kubernetes" -d username="admin" -d password="admin")
ID_TOKEN=$(echo $TOKEN | jq .id_token -r)
REFRESH_TOKEN=$(echo $TOKEN | jq .refresh_token -r)
ACCESS_TOKEN=$(echo $TOKEN | jq .access_token -r)

kubectl config set-credentials "admin@admin.com" \
--auth-provider=oidc \
--auth-provider-arg=idp-certificate-authority="$(pwd)/client.pem" \
--auth-provider-arg=idp-issuer-url="https://$KEYCLOAK_HOST:8443/auth/realms/kubernetes" \
--auth-provider-arg=client-id="kubernetes" \
--token $ACCESS_TOKEN

kubectl config set-context 	admin@admin.com --cluster=minikube --user=admin@admin.com --namespace=default
kubectl config use-context admin@admin.com