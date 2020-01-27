# Other contants
KEYCLOAK_VERSION=8.0.1
KEYCLOAK_HOST=192-168-0-8.nip.io
DOWNLOAD_URL=https://downloads.jboss.org/keycloak/$(KEYCLOAK_VERSION)/keycloak-$(KEYCLOAK_VERSION).zip
MINIKUBE_IP=192.168.0.8

#Internal variables, do not use or override directly
_FLOW_ID=

.PHONY: cert/clean
cert/clean:
	find . -name "*.keystore" -exec rm -rf {} \;
	find . -name "*.truststore" -exec rm -rf {} \;
	find . -name "*.cer" -exec rm -rf {} \;
	find . -name "*.p12" -exec rm -rf {} \;
	find . -name "*.pem" -exec rm -rf {} \;

.PHONY: cert/generate
cert/generate: cert/clean
	keytool -genkey -noprompt -trustcacerts -keyalg RSA -alias "server" -dname "CN=$(KEYCLOAK_HOST)" -keypass "password" -storepass "password" -keystore "application.keystore"
	keytool -export -keyalg RSA -alias "server" -storepass "password" -file "client.cer" -keystore "application.keystore"
	keytool -import -noprompt -v -trustcacerts -keyalg RSA -alias "server" -file "client.cer" -keypass "password" -storepass "password" -keystore "client.truststore"
	keytool -importkeystore -srckeystore client.truststore -destkeystore client.p12 -srcstoretype jks -deststoretype pkcs12 -srcstorepass "password" -deststorepass "password"
	openssl pkcs12 -in client.p12 -out client.pem -passin pass:password

.PHONY: cert/install
cert/install: cert/generate
	cp ./application.keystore ./keycloak-$(KEYCLOAK_VERSION)/standalone/configuration

.PHONY: cert/verify
cert/verify:
	curl --cacert ./client.pem  -v  https://localhost:8443/auth

.PHONY: keycloak/download
keycloak/download:
	wget -N $(DOWNLOAD_URL)

.PHONY: keycloak/unpack
keycloak/unpack: keycloak/download
	unzip keycloak-$(KEYCLOAK_VERSION).zip

.PHONY: keycloak/user
keycloak/user:
	./keycloak-$(KEYCLOAK_VERSION)/bin/add-user-keycloak.sh -u admin -p admin

.PHONY: keycloak/prepare
keycloak/prepare:
	./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh config credentials --config /tmp/.kcadm.config --server http://$(KEYCLOAK_HOST):8080/auth --realm master --user admin --password admin
	./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create realms --config /tmp/.kcadm.config -f ./keycloak-configuration/realm.json
	#./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create clients --config /tmp/.kcadm.config -f ./keycloak-configuration/client.json
	#./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create users --config /tmp/.kcadm.config -f ./keycloak-configuration/users.json
	#./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create clients --config /tmp/.kcadm.config -f ./keycloak-configuration/kc-client-openshift-web-console.json -s "redirectUris=[\"https://$(MINIKUBE_IP):8443/console/*\",\"https://localhost:9000/*\"]" -s baseUrl=https://$(MINIKUBE_IP):8443/ -s adminUrl=https://$(MINIKUBE_IP):8443/
	#I'm not sure why KC doesn't give you this on the first try...
	#$(shell ./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh get realms/master/authentication/flows --config /tmp/.kcadm.config -r master | jq -c '.[] | select(.alias | contains("http challenge")) | .id' | sed 's/"//g')
	#$(eval FLOW_ID := $(shell ./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh get realms/master/authentication/flows --config /tmp/.kcadm.config -r master | jq -c '.[] | select(.alias | contains("http challenge")) | .id' | sed 's/"//g'))
	#echo "FLOW_ID = $(FLOW_ID)"
	#./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create clients --config /tmp/.kcadm.config -f ./keycloak-configuration/kc-client-openshift-challenging-client.json -s "authenticationFlowBindingOverrides={\"browser\": \"$(FLOW_ID)\"}" -s "redirectUris=[\"https://$(KEYCLOAK_HOST):8443/realms/master/oauth/token/implicit\"]"
	#./keycloak-$(KEYCLOAK_VERSION)/bin/kcadm.sh create clients --config /tmp/.kcadm.config -r master -s clientId=token-review -s enabled=true -s publicClient=false -s "redirectUris=[\"*\"]" -s "attributes={\"x509.subjectdn\": \"CN=$(KEYCLOAK_HOST)\"}" -s clientAuthenticatorType=client-x509

.PHONY: keycloak/clean
keycloak/clean:
	rm -rf ./keycloak-$(KEYCLOAK_VERSION)/standalone/data
	rm -rf ./keycloak-$(KEYCLOAK_VERSION)/standalone/log
	rm -rf ./keycloak-$(KEYCLOAK_VERSION)/standalone/tmp

.PHONY: keycloak/start
keycloak/start:
	./keycloak-$(KEYCLOAK_VERSION)/bin/standalone.sh -b $(KEYCLOAK_HOST) &

.PHONY: minikube/start
minikube/start:
	./minikube.sh $(KEYCLOAK_HOST)

.PHONY: token
token:
	./token.sh $(KEYCLOAK_HOST)
	