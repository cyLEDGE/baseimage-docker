# cyLEDGE Base Image

Base image to be used as source (Dockerfile:FROM) for other images.
It is based on the well tested [Phusion Baseimage](http://phusion.github.io/baseimage-docker/).
Applause for the baseimage-docker contributors!

Though the file structure is evolved many tweaks and optimizations are still used from the original images.
Also the whole my_init/runit stuff is still the same.




## RTFM

Please dive into the nature of this image by reading the [README of phusion/base-image](https://github.com/phusion/baseimage-docker/blob/567a53db24b1b5e47c7aa41a8444011cd4bb99cd/README.md)


## Building

Please use (and maybe read through before) the `build.py` script to build this image. It handles rewriting of `Dockerfile` for different Ubuntu releases.


## Syslog-ng

The modified syslog-ng configuration logs either to stdout of the container or to a [fluentd](https://www.fluentd.org/) service.
To control the logging destination set the env variable "LOG_TO" to either "stdout" (default, if not set) or to "fluent".

To send logs to a fluentd service the env variables FLUENT_HOST and FLUENT_SYSLOG_PORT are used.
Logs are sent as RFC5424 messages via a TCP connection and contain a faked HOSTNAME header part:
It uses the value of the env variable DOCKER_HOST_NAME - which might be set to the real (bare metal)
host name in order to see more valuable results in the fluentd collector. (The container ID gets also
sent in the message as structured data.)

Set the targeting variables FLUENT_HOST and FLUENT_SYSLOG_PORT to match your infrastructure.

