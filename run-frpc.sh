#!/bin/bash
exec 2>&1
set -euxo pipefail

# install frp
mkdir -p frp
pushd frp
if [ ! -x frps ]; then
    wget -qOfrp.tgz https://github.com/fatedier/frp/releases/download/v0.34.2/frp_0.34.2_linux_amd64.tar.gz
    tar xf frp.tgz --strip-components=1
fi
popd

# when running in CI override the frpc tls files.
if [ -v FRPC_TLS_CA_CERTIFICATE ]; then
    mkdir -p ca
    cat >ca/github-key.pem <<<"$FRPC_TLS_KEY"
    cat >ca/github.pem <<<"$FRPC_TLS_CERTIFICATE"
    cat >ca/ca.pem <<<"$FRPC_TLS_CA_CERTIFICATE"
    openssl x509 -noout -text -in ca/ca.pem > /dev/null
    openssl x509 -noout -text -in ca/github.pem > /dev/null
fi

if [ -v SSH_PUBLIC_KEY ]; then
    if [ ! -d ~/.ssh ]; then
        install -d -m 700 ~/.ssh
    fi
    if [ ! -f ~/.ssh/authorized_keys ]; then
        install -m 600 /dev/null ~/.ssh/authorized_keys
    fi
    cat >>~/.ssh/authorized_keys <<<"$SSH_PUBLIC_KEY"
    # make sure the home directory has the correct permissions.
    # NB if you do not do this, sshd will not allow you to login
    #    with an ssh public key.
    chmod 775 ~
fi

if [ -v RUNNER_PASSWORD ]; then
    sudo bash <<EOF
usermod -U $USER
echo "$USER:$RUNNER_PASSWORD" | chpasswd
EOF
fi

./frp/frpc -c frpc.ini 2>&1 | sed -E 's,[0-9\.]+:7000,***:7000,ig' || true
