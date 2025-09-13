FROM ghcr.io/rhino-linux/docker:latest

ARG KVM_GID
ENV DEBIAN_FRONTEND=noninteractive

COPY zlib-ng/* /usr/local/lib/
COPY init.sh /init.sh
RUN sudo bash -e /init.sh ${KVM_GID}
