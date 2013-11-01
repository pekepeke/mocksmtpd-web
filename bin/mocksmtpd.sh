#!/bin/bash

cd $(dirname $0)/..

MOCKSMTPD_BIN="/usr/bin/ruby -Imocksmtpd/lib mocksmtpd/bin/mocksmtpd"

[ -e log/mocksmtpd.pid ] && kill -0 $(cat log/mocksmtpd.pid) || rm log/mocksmtpd.pid
if [ -e log/mocksmtpd.pid ]; then
  PID=$(cat log/mocksmtpd.pid)
  running_found=0
  for running_pid in $(ps x | grep mocksmtpd | grep -v grep | awk '{print $1}'); do
    if [ $PID -eq $running_pid ]; then
      running_found=1
    fi
  done
  [ $running_found -eq 0 ] && rm log/mocksmtpd.pid
fi

export LANG=UTF-8
exec $MOCKSMTPD_BIN -f conf/mocksmtpd.conf

