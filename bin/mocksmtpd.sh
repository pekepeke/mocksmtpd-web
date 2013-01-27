#!/bin/bash

cd $(dirname $0)/..

MOCKSMTPD_BIN="/usr/bin/ruby -Imocksmtpd/lib mocksmtpd/bin/mocksmtpd"

exec $MOCKSMTPD_BIN -f conf/mocksmtpd.conf

