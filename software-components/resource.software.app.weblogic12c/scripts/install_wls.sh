#!/bin/sh

install_path=$(ctx node properties install_path)
password=$(ctx node properties password)

echo "make sure that weblogic install files are at /tmp/weblogic/ directory!"
echo
echo press Enter to create weblogic user

set weblogic user
echo "========config weblogic user======="
groupadd -g 510 weblogic
useradd -u 510 -g weblogic weblogic
echo "weblogic:$password"|chpasswd
echo
echo
echo the weblogic user properity is
id weblogic
echo
echo
echo press Enter to install JDK

echo "========install JDK======="
#cd /weblogic/installmedium/
chmod 755 /tmp/weblogic/jdk-8u121-linux-x64.tar.gz
tar -xvzf /tmp/weblogic/jdk-8u121-linux-x64.tar.gz
mv ./jdk1.8.0_121/ /usr/java8_121
echo
sed -i "s/securerandom.source=file:\/dev\/random/securerandom.source=file:\/dev\/.\/urandom/g" /usr/java8_121/jre/lib/security/java.security
echo
echo java install sucessfully
/usr/java8_121/bin/java -version
echo
echo change the max file size of weblogic
sed -i '/End of file/i\weblogic hard nofile 8192' /etc/security/limits.conf
cat /etc/security/limits.conf|grep weblogic
echo
echo
echo press Enter to create weblogic directory

mkdir -p $install_path

echo =============================================================
echo $install_path
chown -R weblogic:weblogic "$install_path"
chown -R weblogic:weblogic /tmp/weblogic

su - weblogic -c"sh /tmp/weblogic/install_wls_append.sh"