FROM debian:sid-slim

ARG UID
ARG GID
ARG KVM_GID

COPY zlib-ng/. /usr/local/lib/
COPY init.sh /init.sh
RUN bash -e /init.sh ${UID} ${GID} ${KVM_GID}

USER debian
WORKDIR /mnt
