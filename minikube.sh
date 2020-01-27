#!/bin/bash

set -x

KEYCLOAK_HOST=$1

minikube stop || true
minikube delete || true

minikube start
scp -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i $(minikube ssh-key) ./client.pem docker@$(minikube ip):/tmp
ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i $(minikube ssh-key) docker@$(minikube ip) "sudo mv /tmp/client.pem /var/lib/minikube/certs/" 
ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -i $(minikube ssh-key) docker@$(minikube ip) "sudo chmod o+r /var/lib/minikube/certs/client.pem" 
minikube stop

minikube start --v=5 \
    --extra-config=apiserver.oidc-issuer-url=https://$KEYCLOAK_HOST:8443/auth/realms/kubernetes \
    --extra-config=apiserver.oidc-client-id=kubernetes \
    --extra-config=apiserver.oidc-username-claim=email \
    --extra-config=apiserver.oidc-ca-file=/var/lib/minikube/certs/client.pem