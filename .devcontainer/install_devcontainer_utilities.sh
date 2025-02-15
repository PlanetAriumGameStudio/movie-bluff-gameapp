#!/bin/bash

TF_ENV_VERSION="v3.0.0"

apt update -y
apt install -y python3-pip

pip3 install pre-commit

mkdir /apps/
git clone --depth=1 -b $TF_ENV_VERSION https://github.com/tfutils/tfenv.git /apps/.tfenv
chmod 777 /apps/.tfenv

curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip

echo 'source /scripts/configure_devcontainer_environment.sh' >> /home/vscode/.bashrc

echo 'source /scripts/devcontainer_runtime_startup.sh' >> /home/vscode/.bashrc
