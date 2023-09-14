#! /bin/bash

for cert in /certs/*
do
	ALIAS="${cert##*/}"
	keytool -import -noprompt -trustcacerts -storepass changeit -file $cert -alias $ALIAS -keystore /opt/java/openjdk/lib/security/cacerts
	mv $cert /usr/local/share/ca-certificates/$ALIAS.crt
done

chmod 644 /usr/local/share/ca-certificates/*.crt
update-ca-certificates