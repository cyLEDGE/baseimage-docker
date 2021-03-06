#!/bin/bash
set -e
. /build/buildconfig
. /build/bash-library
. /etc/lsb-release


status "Tweaking environment..."

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot


## Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
	echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi


## Switch default shell to bash
ln -sf /bin/bash /bin/sh



status "Enable Ubuntu Universe, Multiverse, and deb-src for APT main catalog."
sed -i 's/^#\s*\(deb.*main restricted\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list


status "Loading APT catalog..."
apt_update


if [ $DISTRIB_RELEASE == "12.04" ]
then
  ## Install python3 (which is not installed by default in Ubuntu 12.04)
  status "Installing python..."
  apt_install python3 python-anyjson
fi

if [ $DISTRIB_RELEASE == "16.04" ]
then
  ## add apt-utils to suprress warnings while running apt
  apt_install apt-utils 2> /dev/null
  
  ## Mark python3 as installed (otherwise it would get purged by final cleanup since
  ## it was installed as dependency of other packages)
  ##
  ## command ip is not present in Ubuntu 16.04. But it's so handy!!
  ##
  status "Installing python..."
  apt_install python3 iproute2
fi



status "Installing apt tools useful to build images..."
apt_install apt-transport-https ca-certificates software-properties-common



status "Purging ubuntu base packages not used in a container..."
apt_remove_if_installed eject
apt_remove_if_installed ntpdate
apt_remove_if_installed resolvconf




status "Setting up runit & my_init..."

## Install init process.
cp /build/bin/my_init /sbin/
mkdir -p /etc/my_init.d
mkdir -p /etc/container_environment
touch /etc/container_environment.sh
touch /etc/container_environment.json
chmod 700 /etc/container_environment

groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## Install runit.
apt_install runit



status "Adding base-image utlities..."

## Add THE "bash library" into the system
mkdir /usr/local/share/cyledge
cp /build/bash-library /usr/local/share/cyledge/bash-library


## This tool runs a command as another user and sets $HOME.
cp /build/bin/setuser /sbin/setuser


## Add the host ip detector as startup script
cp /build/bin/detect-docker-host /etc/my_init.d/00-detect-docker-host

## Add the container id detector as startup script
cp /build/bin/detect-docker-container-id /etc/my_init.d/00-detect-docker-container-id


cat >> /etc/bash.bashrc << EOT

# ensure container specific environment variables are available in bash sessions
if [ -f /etc/container_environment.sh ]; then
  source /etc/container_environment.sh
fi
EOT
