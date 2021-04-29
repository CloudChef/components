$runhome="$PWD"
$MSSQL_INSTALL_CONFIG_FILE="$PWD\MSSQLSetup.ini"
$SQL_SYSADMIN_ACCOUNT_SYSTEM="NT AUTHORITY\SYSTEM"
function createMSSQLConfigFile ($MSSQL_INSTALL_CONFIG_FILE) {
    New-Item -Force -ItemType file $MSSQL_INSTALL_CONFIG_FILE
     echo ';SQL Server 2012 Configuration File
[OPTIONS]
ACTION="Install"
ENU="True"
QUIET="True"
QUIETSIMPLE="False"
IACCEPTSQLSERVERLICENSETERMS="True"
UpdateEnabled="False"
FEATURES="SQLENGINE,Tools"
HELP="False"
INDICATEPROGRESS="False"
X86="False"
INSTALLSHAREDDIR="#BINARYDISKMOUNTPOINT#\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="#BINARYDISKMOUNTPOINT#\Program Files (x86)\Microsoft SQL Server"
INSTANCENAME= "#INSTANCENAME#"
INSTANCEID="#INSTANCENAME#"
SQMREPORTING="False"
ERRORREPORTING="False"
INSTANCEDIR="#BINARYDISKMOUNTPOINT#\Program Files\Microsoft SQL Server"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
AGTSVCSTARTUPTYPE="Manual"
COMMFABRICPORT="0"
COMMFABRICNETWORKLEVEL="0"
COMMFABRICENCRYPTION="0"
MATRIXCMBRICKCOMMPORT="0"
SQLSVCSTARTUPTYPE="Automatic"
FILESTREAMLEVEL="0"
SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
SQLSVCACCOUNT="NT AUTHORITY\SYSTEM"
INSTALLSQLDATADIR="#BINARYDISKMOUNTPOINT#\Program Files\Microsoft SQL Server"
SQLBACKUPDIR="#ARCHIVEDISKMOUNTPOINT#\Program Files\Microsoft SQL Server\MSSQL11.#INSTANCENAME#\MSSQL\Backup"
SQLUSERDBDIR="#DATADISKMOUNTPOINT#\Program Files\Microsoft SQL Server\MSSQL11.#INSTANCENAME#\MSSQL\Data"
SQLUSERDBLOGDIR="#REDOLOGDISKMOUNTPOINT#\Program Files\Microsoft SQL Server\MSSQL11.#INSTANCENAME#\MSSQL\Data"
SQLTEMPDBDIR="#DATADISKMOUNTPOINT#\Program Files\Microsoft SQL Server\MSSQL11.#INSTANCENAME#\MSSQL\Data"
SQLTEMPDBLOGDIR="#REDOLOGDISKMOUNTPOINT#\Program Files\Microsoft SQL Server\MSSQL11.#INSTANCENAME#\MSSQL\Data"
SQLSYSADMINACCOUNTS="NT AUTHORITY\SYSTEM"
SAPWD="#SAPASSWORD#"
SECURITYMODE=sql
TCPENABLED="1"
NPENABLED="0"
PID="#SNNUMBER#"
BROWSERSVCSTARTUPTYPE="Automatic"
FTSVCACCOUNT="NT Service\MSSQLFDLauncher"
' | out-file -Force -filepath $MSSQL_INSTALL_CONFIG_FILE
}

function updateInstallConfigSettings ($ConfigurationFile, $oldPara, $newPara) {
    (get-content $ConfigurationFile) | foreach-object {$_ -replace "$oldPara", "$newPara"} | set-content $ConfigurationFile
}

createMSSQLConfigFile $MSSQL_INSTALL_CONFIG_FILE

$binaryDiskMountPoint =ctx node properties binarydisk
$dataDiskMountPoint   =ctx node properties datadisk
$redologDiskMountPoint=ctx node properties redolog
$archiveDiskMountPoint=ctx node properties archivedisk
$INSTANCE_NAME=ctx node properties instancename
$SA_PWD=ctx node properties sapwd
$SNNumber=ctx node properties sn
$LocalPath="C:\Users\Administrator\Desktop\sql2012.iso"
$ImagePath=ctx node properties isopath


updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#INSTANCENAME#"          ${INSTANCE_NAME}
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#SAPASSWORD#"            ${SA_PWD}
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#DATADISKMOUNTPOINT#"    ${dataDiskMountPoint}":"
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#REDOLOGDISKMOUNTPOINT#" ${redologDiskMountPoint}":"
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#ARCHIVEDISKMOUNTPOINT#" ${archiveDiskMountPoint}":"
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#BINARYDISKMOUNTPOINT#"  ${binaryDiskMountPoint}":"
updateInstallConfigSettings $MSSQL_INSTALL_CONFIG_FILE "#SNNUMBER#"  $SNNumber

$sqlserverExist = Test-Path "${binaryDiskMountPoint}:\Program Files\Microsoft SQL Server"
If (${sqlserverExist}) {
    ctx logger info "Configuration file exists, skip to install"
    Exit
}

$WIN_MINOR_VERSION=[System.Environment]::OSVersion.Version.Minor
if (${WIN_MINOR_VERSION} -eq 1) {
    Import-Module ServerManager
    Add-WindowsFeature -Name net-framework
}

ctx logger info "Begin to Download ISO  ${ImagePath}"
(New-Object System.Net.WebClient).DownloadFile($ImagePath, $LocalPath)

ctx logger info "Begin to mount ISO  ${LocalPath}"
Mount-DiskImage -ImagePath ${LocalPath} -StorageType ISO
$ISODrive=(Get-DiskImage -ImagePath ${LocalPath} | Get-Volume).DriveLetter

If([String]::IsNullOrEmpty(${ISODrive}))
{
    ctx logger error "Mount ISO failed"
    Exit 1
}

ctx logger info "Begin to Setup SQL, ISODrive: ${ISODrive}"
cd ${ISODrive}":"
.\setup.exe /CONFIGURATIONFILE=${MSSQL_INSTALL_CONFIG_FILE}
$exitCode=$LastExitCode
ctx logger info "ExitCode=${exitCode}"
cd ${runhome}

ctx logger info "Begin to DisMount ISO ${ImagePath}"

DisMount-DiskImage -ImagePath ${ImagePath}
if (${exitCode} -eq 0) {
    ctx logger info  ("SQL Server 2012 Enterprise Edition installation succeeded!")
    Exit
} elseif (${exitCode} -eq 3010) {
    ctx logger info  ("SQL Server 2012 Enterprise Edition installation succeeded! But a restart is required!")
    ctx logger info  ("Restart your computer now ......")
    Restart-Computer -Force
    Exit
} else {
    ctx logger info  ("SQL Server 2012 Enterprise Edition installation failed!")
    Exit 1
}