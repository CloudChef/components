#!/bin/bash

HOST_NAME=$(ctx node properties host_name)

# download installation package
TAR_PATH=$(ctx node properties websphere_tar)
ctx logger info "$TAR_PATH"
curl -o /opt/was8.5.5.tar.gz  $TAR_PATH -s

# decompress package
tar -zxf /opt/was8.5.5.tar.gz -C /opt

# disable firewall
systemctl stop firewalld
systemctl disable firewalld

# set hostname
hostnamectl set-hostname $HOST_NAME
echo "127.0.0.1   $HOST_NAME" >> /etc/hosts

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# install dependency rpms
/bin/rpm -ivh --nodeps --force /opt/was8.5.5/wasrpms/*.rpm