#!/bin/bash

MAILLOG=/var/log/mail
DAT1=/tmp/zabbix-postfix-offset.dat
DAT2=$(mktemp)
ZABBIX_CONF=/etc/zabbix/zabbix-agentd.conf
DEBUG=0

# Only /usr/bin and /bin in path
# PFLOGSUMM=$(which pflogsumm)
# ZABBIX_SENDER=$(which zabbix-sender)
PFLOGSUMM=/usr/local/sbin/pflogsumm
ZABBIX_SENDER=/usr/sbin/zabbix-sender
LOGTAIL=$(which logtail)

function zsend {
  key="postfix[`echo "$1" | tr ' -' '_' | tr '[A-Z]' '[a-z]' | tr -cd [a-z_]`]"
  value=`grep -m 1 "$1" $DAT2 | awk '{print $1}'`

  # pflogsumm converts to thousands, but zabbix expects an integer
  if [[ $value == *k ]]; then
      value=$((${value%*k} * 1024))
  fi

  [ ${DEBUG} -ne 0 ] && echo "Send key \"${key}\" with value \"${value}\"" >&2
  $ZABBIX_SENDER -c $ZABBIX_CONF -k "${key}" -o "${value}" 2>&1 >/dev/null
}

$LOGTAIL $MAILLOG $DAT1 | $PFLOGSUMM -h 0 -u 0 --bounce-detail=0 --deferral-detail=0 --reject-detail=0 --no_no_msg_size --smtpd-warning-detail=0 > $DAT2

zsend received
zsend delivered
zsend forwarded
zsend deferred
zsend bounced
zsend rejected
zsend held
zsend discarded
zsend "reject warnings"
zsend "bytes received"
zsend "bytes delivered"
zsend senders
zsend recipients

rm -f $DAT2
