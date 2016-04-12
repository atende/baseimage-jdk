#!/bin/bash
# Downloads and installs the startssl CA certs into the global Java keystore
# https://sipb.mit.edu/doc/safe-shell/
set -euf -o pipefail

# Check if JAVA_HOME is set
if [ "$JAVA_HOME" = "" ]
then
    echo "ERROR: JAVA_HOME must be set."
    exit 1
fi

# Check if cacerts file is present
if [ ! -f $JAVA_HOME/jre/lib/security/cacerts ]
then
    echo "ERROR: \$JAVA_HOME/jre/lib/security/cacerts not found. JAVA_HOME set correctly?"
    exit 1
fi

##########################################
## just change here the alias and url
##########################################
declare -A certificates=(
    ["startcom.ca"]="http://www.startssl.com/certs/ca.crt" 
    ["startcom.ca-g2"]="https://www.startssl.com/certs/ca-g2.crt"
    ["startcom.ca-sha2"]="https://www.startssl.com/certs/ca-sha2.crt"
    ["letsencrypt.ca"]="https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem"
    )

# 
# this function install one certificat
# usage : installCertificate certificateAlias certificateUrl
# 
function installCertificate() {
    local certificateAlias=$1
    local certificateUrl=$2
    echo "Processing $alias - ${certificates["$alias"]} ...";

    echo "Downloading certs $certificateAlias : $certificateUrl ..."
        curl "$certificateUrl" > $certificateAlias.crt
    
    echo "Deleting cert from cacerts keystore (sudo password required)..."
        sudo keytool -delete -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt -alias $certificateAlias || true
    echo "Adding cert to cacerts keystore (sudo password required)..."
        sudo keytool -import -trustcacerts -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -noprompt -alias $certificateAlias -file $certificateAlias.crt
    
    if [ -f $JAVA_HOME/jre/lib/security/jssecacerts ]
    then
        echo "Deleting cert from jssecacerts keystore (sudo password required)..."
            sudo keytool -delete  -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass changeit -noprompt -alias $certificateAlias || true 
        echo "Adding cert to jssecacerts keystore (sudo password required)..."
            sudo keytool -import -trustcacerts -keystore $JAVA_HOME/jre/lib/security/jssecacerts -storepass changeit -noprompt -alias $certificateAlias -file $certificateAlias.crt
    fi

    rm -f $certificateAlias.crt
}

# loop throw certificates map and call installCertificate
for alias in "${!certificates[@]}"; do 
    installCertificate $alias ${certificates["$alias"]};
done
