# Other contants
KEYCLOAK_VERSION=8.0.1
KEYCLOAK_HOST=192.168.0.8
DOWNLOAD_URL=https://downloads.jboss.org/keycloak/$(KEYCLOAK_VERSION)/keycloak-$(KEYCLOAK_VERSION).zip


.PHONY: download
download:
	wget -N $(DOWNLOAD_URL)

.PHONY: download
unpack:
	unzip keycloak-$(KEYCLOAK_VERSION).zip

.PHONY: cert/generate
cert/generate:
	find . -name "*.keystore" -exec rm -rf {} \;
	find . -name "*.truststore" -exec rm -rf {} \;
	find . -name "*.cer" -exec rm -rf {} \;
	find . -name "*.p12" -exec rm -rf {} \;
	find . -name "*.pem" -exec rm -rf {} \;
	keytool -genkey -noprompt -trustcacerts -keyalg RSA -alias "$(KEYCLOAK_HOST)" -dname "CN=$(KEYCLOAK_HOST), OU=Keycloak, O=JBoss, L=Red Hat, ST=World, C=WW" -keypass "password" -storepass "password" -keystore "application.keystore"
	keytool -genkey -noprompt -trustcacerts -keyalg RSA -alias "server" -dname "CN=$(KEYCLOAK_HOST), OU=Keycloak, O=JBoss, L=Red Hat, ST=World, C=WW" -keypass "password" -storepass "password" -keystore "application.keystore"
	keytool -export -keyalg RSA -alias "server" -storepass "password" -file "client.cer" -keystore "application.keystore"
	keytool -import -noprompt -v -trustcacerts -keyalg RSA -alias "server" -file "client.cer" -keypass "password" -storepass "password" -keystore "client.truststore"
	keytool -importkeystore -srckeystore client.truststore -destkeystore client.p12 -srcstoretype jks -deststoretype pkcs12 -srcstorepass "password" -deststorepass "password"
	openssl pkcs12 -in client.p12 -out client.pem

.PHONY: cert/install
cert/install:
	cp ./application.keystore ./keycloak-$(KEYCLOAK_VERSION)/standalone/configuration

.PHONY: keycloak/prepare
keycloak/prepare:
	./keycloak-$(KEYCLOAK_VERSION)/bin/add-user-keycloak.sh -u admin -p admin

.PHONY: keycloak/start
keycloak/prepare:
	./keycloak-$(KEYCLOAK_VERSION)/bin/standalone.sh