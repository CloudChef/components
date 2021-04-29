#!/bin/bash

WAS_LOG=$(ctx node properties websphere_log)
PROFILE_NAME=$(ctx node properties profile_name)
SERVER_NAME=$(ctx node properties server_name)
NODE_NAME=$(ctx node properties node_name)
CELL_NAME=$(ctx node properties cell_name)
HOST_NAME=$(ctx node properties host_name)
ADMIN_USERNAME=$(ctx node properties admin_username)
ADMIN_PASSWORD=$(ctx node properties admin_password)
ERR_NUM=$(ctx node properties err_num)
ERR_SIZE=$(ctx node properties err_size)
OUT_NUM=$(ctx node properties out_num)
OUT_SIZE=$(ctx node properties out_size)



date >> $WAS_LOG
echo "Begin to install WebSphere Application Server" >> $WAS_LOG

# preparation
mkdir -p /opt/IMS/eclipse
mkdir -p /opt/IBM/WebSphere/AppServer

# install Installation manager
/opt/was8.5.5/wasims/userinstc -installationDirectory /opt/IMS/eclipse -acceptLicense

# install WebSphere Application Server Full
repo=$(/opt/IMS/eclipse/tools/imcl listAvailablePackages -repositories /opt/was8.5.5/wassource)
/opt/IMS/eclipse/tools/imcl install ${repo} -repositories /opt/was8.5.5/wassource/repository.config -installationDirectory /opt/IBM/WebSphere/AppServer -sharedResourcesDirectory /opt/IBM/IMShared -properties cic.selector.nl=zh -acceptLicense -showVerboseProgress

# create app server profile
/opt/IBM/WebSphere/AppServer/bin/manageprofiles.sh -create -serverName $SERVER_NAME -nodeName $NODE_NAME -cellName $CELL_NAME -hostName $HOST_NAME -profileName $PROFILE_NAME -profilePath /opt/IBM/WebSphere/AppServer/profiles/$PROFILE_NAME -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/default -enableAdminSecurity true -adminUserName $ADMIN_USERNAME -adminPassword $ADMIN_PASSWORD

# install WAS SDK Java7
/opt/IMS/eclipse/tools/imcl install com.ibm.websphere.IBMJAVA.v70_7.0.4001.20130510_2103  -repositories /opt/was8.5.5/wasjdk7/repository.config -installationDirectory /opt/IBM/WebSphere/AppServer -sharedResourcesDirectory /opt/IBM/IMShared -properties cic.selector.nl=zh -acceptLicense -showVerboseProgress

# enable profile for app server
/opt/IBM/WebSphere/AppServer/bin/managesdk.sh -enableProfile -profileName $PROFILE_NAME -sdkName 1.7_64


# update log config
sed -i "s/SystemErr.log\" rolloverType=\"SIZE\" maxNumberOfBackupFiles=\"5\" rolloverSize=\"1\"/SystemErr.log\" rolloverType=\"SIZE\" maxNumberOfBackupFiles=\"$ERR_NUM\" rolloverSize=\"$ERR_SIZE\"/g" \
/opt/IBM/WebSphere/AppServer/profiles/$PROFILE_NAME/config/cells/${CELL_NAME}/nodes/${NODE_NAME}/servers/${SERVER_NAME}/server.xml


sed -i "s/SystemOut.log\" rolloverType=\"SIZE\" maxNumberOfBackupFiles=\"5\" rolloverSize=\"1\"/SystemOut.log\" rolloverType=\"SIZE\" maxNumberOfBackupFiles=\"$OUT_NUM\" rolloverSize=\"$OUT_SIZE\"/g" \
/opt/IBM/WebSphere/AppServer/profiles/$PROFILE_NAME/config/cells/${CELL_NAME}/nodes/${NODE_NAME}/servers/${SERVER_NAME}/server.xml

# start server
/opt/IBM/WebSphere/AppServer/bin/startServer.sh $SERVER_NAME


date >> $WAS_LOG
# remove installation package
ps ax | grep websphere | grep -v grep > /dev/null

if [ $? -eq 0 ];then
    echo "[Success] Start WebSphere Application Server Successfully!" >> $WAS_LOG
    rm -f /opt/was8.5.5.tar.gz
    echo "Remove was installation package!" >> $WAS_LOG
else
    echo "[Failed]Start WebSphere Application Server Failed!!!" >> $WAS_LOG
fi