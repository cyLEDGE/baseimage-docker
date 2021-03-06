#!/bin/bash
set -e
. /build/buildconfig
. /usr/local/share/cyledge/bash-library
. /etc/lsb-release

status "Installing syslog-ng..."

SYSLOG_NG_BUILD_PATH=/build/services/syslog-ng

## Install a syslog daemon.
apt_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp $SYSLOG_NG_BUILD_PATH/run.sh /etc/service/syslog-ng/run
cp $SYSLOG_NG_BUILD_PATH/check.sh /etc/my_init.d/check-syslog-ng.sh

mkdir /etc/syslog-ng/conf-stdout.d
mkdir /etc/syslog-ng/conf-fluent.d

cp $SYSLOG_NG_BUILD_PATH/syslog-ng.conf /etc/syslog-ng/
cp $SYSLOG_NG_BUILD_PATH/log-fluent.conf /etc/syslog-ng/conf-fluent.d/basic.conf
cp $SYSLOG_NG_BUILD_PATH/log-stdout.conf /etc/syslog-ng/conf-stdout.d/basic.conf

#
# Create user syslog manually if not present
#
if ! id -u syslog &> /dev/null
then
  groupadd -r syslog
  useradd -r -M -l -g syslog -s /bin/false syslog 
fi

#
# Syslog-ng version of Ubuntu 12.04 requires older config file version.
#
if [ $DISTRIB_RELEASE == "12.04" ]
then
  echo "downgrading syslog-ng.conf version header to 3.3 (required for Ubuntu 12.04)"
  sed "s/^@version: [[:digit:]].[[:digit:]]/@version: 3.3/" -i /etc/syslog-ng/syslog-ng.conf
fi

chown syslog:syslog /var/lib/syslog-ng

