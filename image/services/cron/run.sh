#!/bin/sh
. /usr/local/share/cyledge/bash-library

status "starting cron daemon"

# Touch cron files to fix 'NUMBER OF HARD LINKS > 1' issue. See  https://github.com/phusion/baseimage-docker/issues/198
touch -c /var/spool/cron/crontabs/*
touch -c /etc/crontab
touch -c /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/*

exec /usr/sbin/cron -f
