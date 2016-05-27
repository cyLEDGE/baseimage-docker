#!/bin/bash
set -e
. /build/buildconfig
. /etc/lsb-release

SYSLOG_NG_BUILD_PATH=/build/services/syslog-ng

## Install a syslog daemon.
apt_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.runit /etc/service/syslog-ng/run
cp $SYSLOG_NG_BUILD_PATH/check-syslog-ng.sh /etc/my_init.d/
cp $SYSLOG_NG_BUILD_PATH/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

#
# In Ubuntu 12.04 no syslog user gets created by APT/dpkg
# Let's create it manually
#
if [ $DISTRIB_RELEASE == "12.04" ]
then
  groupadd -r -g 104 syslog
  useradd -r -M -l -u 101 -g 104 -s /bin/false syslog 
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
