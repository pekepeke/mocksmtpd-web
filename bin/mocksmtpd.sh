#!/bin/bash

cd $(dirname $0)/..

MOCKSMTPD_BIN="/usr/bin/ruby -Imocksmtpd/lib mocksmtpd/bin/mocksmtpd"

[ -e log/mocksmtpd.pid ] && kill -0 $(cat log/mocksmtpd.pid) || rm log/mocksmtpd.pid

exec $MOCKSMTPD_BIN -f conf/mocksmtpd.conf

