#!/bin/sh

url=$(ctx node properties url)
jdk=jdk-8u121-linux-x64.tar.gz
wls=fmw_12.2.1.2.0_wls.jar
tmp_path=/tmp/weblogic

install_path=$(ctx node properties install_path)
user=$(ctx node properties user)
password=$(ctx node properties password)

function download()
{
    if command -v wget > /dev/null 2>&1; then
        sudo wget -c -t 5 $1 -O $2
    elif command -v curl > /dev/null 2>&1; then
        sudo curl -L -o $2 $1
    else
        ctx logger error "error: wget/curl not found. cannot download package"
        exit 1
    fi
}

mkdir $tmp_path

# prepare packages
download $url/$jdk $tmp_path/$jdk
download $url/$wls $tmp_path/$wls


# prepare script
cat > /tmp/weblogic/install_wls_append.sh << WLS
#!/bin/sh

echo "========create weblogic directory======="

echo
sed -i 's/PATH=/PATH=\/usr\/java8_121\/bin:/g' /home/weblogic/.bash_profile
echo "cat /home/weblogic/.bash_profile|grep PATH"
cat /home/weblogic/.bash_profile|grep PATH=
echo
echo "\$PATH="$PATH
source /home/weblogic/.bash_profile
echo "java -version"
echo
java -version
echo
echo
echo press Enter to config limits parameter

echo "========config limits parameter======="
sed -i '/export/i\ulimit -n 8192' /home/weblogic/.bash_profile
source /home/weblogic/.bash_profile

echo "ulimit -n"
ulimit -n
echo
echo
echo press Enter to install WLS 12c

touch /tmp/weblogic/oraInst.loc
echo "inventory_loc=""$install_path" >> /tmp/weblogic/oraInst.loc
echo "inst_group=weblogic" >> /tmp/weblogic/oraInst.loc
echo "========install WLS 12c======="
echo "whoami:""`id`"

cd /tmp/weblogic/
echo  > wls.rsp
echo [ENGINE] >> wls.rsp
echo Response File Version=1.0.0.0.0 >> wls.rsp
echo [GENERIC] >> wls.rsp
echo DECLINE_AUTO_UPDATES=true >> wls.rsp
echo ORACLE_HOME="$install_path/"Oracle/Middleware/Oracle_Home >> wls.rsp
echo INSTALL_TYPE=WebLogic Server >> wls.rsp
echo MYORACLESUPPORT_USERNAME= >> wls.rsp
echo DECLINE_SECURITY_UPDATES=true >> wls.rsp
echo SECURITY_UPDATES_VIA_MYORACLESUPPORT=false >> wls.rsp
echo PROXY_HOST= >> wls.rsp
echo PROXY_PORT= >> wls.rsp
echo PROXY_USER= >> wls.rsp
echo COLLECTOR_SUPPORTHUB_URL= >> wls.rsp

java -jar /tmp/weblogic/fmw_12.2.1.2.0_wls.jar -silent -responseFile /tmp/weblogic/wls.rsp -invPtrLoc /tmp/weblogic/oraInst.loc
echo
echo press Enter to end install

echo
echo Starting Create Domains......
echo
cd "$install_path/"Oracle/Middleware/Oracle_Home/oracle_common/common/bin
export MW_HOME="$install_path/"Oracle/Middleware/Oracle_Home
export WL_HOME="$install_path/"Oracle/Middleware/Oracle_Home/wlserver



echo   > /tmp/weblogic/create_domain.py
echo readTemplate"("$install_path/""Oracle/Middleware/Oracle_Home/wlserver/common/templates/wls/wls.jar")" >> /tmp/weblogic/create_domain.py
sed -i 's/(/("/' /tmp/weblogic/create_domain.py
sed -i 's/)/")/' /tmp/weblogic/create_domain.py



echo cd"('Servers/AdminServer')" >> /tmp/weblogic/create_domain.py
echo set"('ListenAddress','')" >> /tmp/weblogic/create_domain.py
echo set"('ListenPort', 7001)" >> /tmp/weblogic/create_domain.py
echo cd"('/')" >> /tmp/weblogic/create_domain.py
echo cd"('Security/base_domain/User/weblogic')" >> /tmp/weblogic/create_domain.py
echo cmo.setName"('$user')" >> /tmp/weblogic/create_domain.py
echo cmo.setPassword"('$password')" >> /tmp/weblogic/create_domain.py
echo setOption"('OverwriteDomain', 'true')" >> /tmp/weblogic/create_domain.py
echo setOption"('ServerStartMode','prod')" >> /tmp/weblogic/create_domain.py
echo writeDomain"('"$install_path/"/Oracle/Middleware/Oracle_Home/user_projects/domais/base_domomain')" >> /tmp/weblogic/create_domain.py
echo closeTemplate"()" >> /tmp/weblogic/create_domain.py
echo exit"()" >> /tmp/weblogic/create_domain.py

./commEnv.sh
./wlst.sh /tmp/weblogic/create_domain.py
echo
echo "the Domains create successfully."
echo
echo press Enter to end create
mkdir -p "$install_path/"Oracle/Middleware/Oracle_Home/user_projects/domais/base_domomain/servers/AdminServer/security/
echo username=$user > "$install_path/"Oracle/Middleware/Oracle_Home/user_projects/domais/base_domomain/servers/AdminServer/security/boot.properties
echo password=$password >> "$install_path/"Oracle/Middleware/Oracle_Home/user_projects/domais/base_domomain/servers/AdminServer/security/boot.properties

WLS
