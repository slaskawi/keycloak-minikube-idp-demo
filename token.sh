#!/bin/bash

set -x

KEYCLOAK_HOST=$1

TOKEN=$(curl -s --cacert ./client.pem "https://${KEYCLOAK_HOST}:8443/auth/realms/kubernetes/protocol/openid-connect/token" -d grant_type=password -d response_type=id_token -d scope=email -d client_id="kubernetes" -d username="test" -d password="test")
ID_TOKEN=$(echo $TOKEN | jq .id_token -r)
REFRESH_TOKEN=$(echo $TOKEN | jq .refresh_token -r)
ACCESS_TOKEN=$(echo $TOKEN | jq .access_token -r)

kubectl config set-credentials "test@test.com" \
--auth-provider=oidc \
--auth-provider-arg=idp-certificate-authority="$(pwd)/client.pem" \
--auth-provider-arg=idp-issuer-url="https://$KEYCLOAK_HOST:8443/auth/realms/kubernetes" \
--auth-provider-arg=client-id="kubernetes" \
--token $ACCESS_TOKEN

kubectl config set-context 	test@test.com --cluster=minikube --user=test@test.com --namespace=default
kubectl config use-context test@test.com