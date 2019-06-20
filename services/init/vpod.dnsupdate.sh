#!/usr/bin/env bash
exec > >(tee -a /var/tmp/nsupdate-init_$$.log) 2>&1
. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/agent_util.sh

DEPLOYMENT_NAME="$parentJobName"
#APP_NAME="$cliqrAppName"
APP_NAME=$DEPLOYMENT_NAME
TIER_NAME="$cliqrAppTierName"
NODE_NAME="$cliqrNodeHostname"

hostip=$(ip -o -4 a s scope global | egrep -v 'docker' | head -n 1 | awk '{print $4}' | cut -d '/' -f1)
hostshortname=$(hostname -s)
domainname=$(grep "search" /etc/resolv.conf | cut -d' ' -f2 | cut -d',' -f1)


DNS_A_RECORD=${hostshortname}.${domainname}
DNS_CNAME_RECORD=${DEPLOYMENT_NAME}.${domainname}

exit 0

if ! host ${DNS_A_RECORD} > /dev/null 2>&1 ; then
  echo -e "update add ${DNS_A_RECORD} 86400 A ${hostip}\nsend" | nsupdate
  [ ! $? -eq 0 ] && agentSendLogMessage "DNS A Record Addition FAILED: ${DNS_A_RECORD} => ${hostip}" && exit 1
  agentSendLogMessage "DNS A Record Added: ${DNS_A_RECORD} => ${hostip}"
fi

if [ "$1" == "deploymentcname" ]; then
  echo -e "update add ${DNS_CNAME_RECORD} 600 cname ${DNS_A_RECORD}.\nsend" | nsupdate
  [ ! $? -eq 0 ] && agentSendLogMessage "DNS CNAME Record Addition FAILED: ${DNS_CNAME_RECORD} => ${DNS_A_RECORD}" && exit 1
  agentSendLogMessage "DNS CNAME Record Added: ${DNS_CNAME_RECORD} => ${DNS_A_RECORD}"
fi

