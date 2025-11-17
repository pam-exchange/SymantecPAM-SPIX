$extensionTypeBuiltIn= (
    'activeDirectorySshKey',
    'AwsAccessCredentials',
    'AwsApiProxyCredentials',
    'AzureAccessCredentials',
    'AS400',
    'CiscoSSH',
    'Generic',
    'HPServiceManager',
    'juniper',
    'ldap',
    'mssql',
    'mssqlAzureMI',
    'mysql',
    'nsxcontroller',
    'nsxmanager',
    'nsxproxy',
    'oracle',
    'PaloAlto',
    'RadiusTacacsSecret',
    'remedy',
    'ServiceDeskBroker',
    'ServiceNow',
    'SPML2',
    'sybase',
    'unixII',
    'vcf',
    'vmware',
    'weblogic10',
    'windows',
    'windowsDomainService',
    'windowsRemoteAgent',
    'windowsSshKey',
    'windowsSshPassword',
    'XsuiteApiKey'
)

$extensionTypeTCF= ( 
    'keystorefile',
    'configfile',
    'mongodb',
    'postgresql',
    'pamuser'
)

$extensionType= $extensionTypeBuiltIn+$extensionTypeTCF

function _ExtensionType () 
{
    Param(
        $type
    )

    return $extensionType | Where-Object {$_ -eq $type}
}

function _isBuiltInExtensionType ($type) {
    $found= $extensionTypeBuiltIn | Where-Object {$_ -eq $type}
    return [string]::IsNullOrWhiteSpace($found)
}
