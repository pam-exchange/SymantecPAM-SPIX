<#
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>
#--------------------------------------------------------------------------------------

enum EXPORTCATEGORY {
    ALL
    Target
    TargetServer
    TargetApplication
    TargetAccount
    A2A
    RequestServer
    RequestScript
    Authorization
    Proxy
    Policy
    PCP
    PVP
    JIT
    CustomWorkflow
    SSHKeyPairPolicy
    User
    UserGroup
    Role
    Filter
    Group
    Secret
    Vault
    VaultSecret
    AccessPolicy
    Service
    Device
}

function Export-Sym (

	[Alias('TargetServerName','Hostname')]
    [AllowEmptyString()]
    [string] 
    $srvName,

	[Alias('TargetApplicationName')]
    [AllowEmptyString()]
    [string] 
    $appName,

	[Alias('TargetAccountName','username')]
    [AllowEmptyString()]
    [string] 
    $accName,

    [Alias('Type')]
    [AllowEmptyString()]
    [string] 
    $extensionType,

    [switch] $showPassword= $false,
    [AllowEmptyString()][string] $Passphrase= "",

    [string] $Timestamp,
    [EXPORTCATEGORY[]] $Category= 'ALL',
    [string] $OutputPath= '.\SPIX-output',

    [switch] $Compress= $false,
    [AllowEmptyString()][string] $Delimiter,

    [switch] $Quiet= $false
)
{
    process {
        #$Delimiter = $Script:Delimiter
        if (!$Delimiter) {
            if ($Script:Delimiter) {$Delimiter= $Script:Delimiter}
            else {$Delimiter= ','}
        }

        if (!$OutputPath) {$OutputPath = (Get-Location).Path}
        if (!(Test-Path $OutputPath)) {
            _GenerateFolder($OutputPath)
        }

        switch ($Category) {
            {'ALL', 'Target','TargetServer' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting TargetServer"}
                $targetServer = Get-SymTargetServer -srvName $srvName
                $fixedColumns = @('ID','ObjectType','Action','deviceName','hostname','ipAddress','Attribute.descriptor1','Attribute.descriptor2')
                $ignoreColums = @('deviceId')
                Export-SymGeneric -ObjectType TargetServer -List $targetServer -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Target','TargetApplication' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting TargetApplication"}
                $targetApplication = Get-SymTargetApplication -srvName $srvName -appName $appName -ExtensionType $ExtensionType
                $fixedColumns = @('ID','ObjectType','Action','ExtensionType','deviceName','hostname','name','PCP','Attribute.descriptor1','Attribute.descriptor2')
                $ignoreColums = @('deviceId','policyID','TargetServerID','overrideDnsType','Attribute.agentId','Attribute.sshKeyPairPolicyID','Attribute.customWorkflowId')
                Export-SymTargetApplication -List $targetApplication -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Compress:$Compress -Delimiter $Delimiter -OutputPath $OutputPath -Quiet:$Quiet
            }

            {'ALL', 'Target','TargetAccount' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting TargetAccount"}
                $targetAccount = Get-SymTargetAccount -srvName $srvName -appName $appName -accName $accName -ExtensionType $ExtensionType
                $fixedColumns = @('ID','ObjectType','Action','ExtensionType','deviceName','hostname','targetApplicationName','username','password')
                $ignoreColums = @('cacheAllowed','cacheBehaviorInt','compoundAccount','compoundServerIDs','ownerUserID','passwordViewPolicyID','parentAccountId','Privileged','ServerkeyID','TargetApplication','TargetApplicationID','TargetServerAlias','TargetServerID','Attribute.useOtherAccountToChangePassword')
                Export-SymTargetAccount -List $targetAccount -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Compress:$Compress -Delimiter $Delimiter -OutputPath $OutputPath -ShowPassword:$ShowPassword -Passphrase $Passphrase -Quiet:$Quiet
            }

            {'ALL', 'A2A','RequestServer' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting RequestServer"}
                $requestServer = Get-SymRequestServer
                $fixedColumns = @('ID','ObjectType','Action','deviceName','hostname','ipAddress','Attribute.descriptor1','Attribute.descriptor2')
                $ignoreColums = @('deviceId','serverKeyId','SiteID')
                Export-SymGeneric -ObjectType RequestServer -List $requestServer -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'A2A','RequestScript' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting RequestScript"}
                $requestScript = Get-SymRequestScript
                $fixedColumns = @('ID','ObjectType','Action','name','RequestServer','type')
                $ignoreColums = @('deviceID','RequestServerID')
                Export-SymGeneric -ObjectType RequestScript -List $requestScript -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'A2A','Authorization' -eq $_}
            {    
                if (!$Quiet) {Write-Host "Exporting Authorization"}
                $authorization= Get-SymAuthorization
                $fixedColumns= @('ID','ObjectType','Action','Target','Request','Script','checkExecutionID','executionUser')
                $ignoreColums= @('targetAlias','requestGroupID','requestServerID','scriptID','targetAliasID','targetGroupID','requestServer')
                Export-SymAuthorization -List $authorization -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Proxy' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Proxy"}
                $proxy= Get-SymProxy
                $fixedColumns= @('ID','ObjectType','Action','deviceName','hostname','ipAddress')
                $ignoreColums= @('serverKeyId','SiteID','pendingAcknowledgement','currentKey','oldKey','lastDigestLoginDate','lastPatchStatusChangeDate')
                Export-SymGeneric -ObjectType Proxy -List $proxy -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Policy', 'PCP' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting PCP"}
                $PCP= Get-SymPCP
                $fixedColumns= @('ID','ObjectType','Action','name','type','Description')
                $ignoreColums= @()
                Export-SymGeneric -ObjectType PCP -List $PCP -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Policy','PVP' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting PVP"}
                $PVP= Get-SymPVP
                $fixedColumns= @('ID','ObjectType','Action','name','Description')
                $ignoreColums= @('approverIDs','emailNotificationUserIDs')
                Export-SymPVP -List $PVP -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Policy', 'SSHKeyPairPolicy' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting SSHKeyPairPolicy"}
                $SSH= Get-SymSSHKeyPairPolicy
                $fixedColumns= @('ID','ObjectType','Action','name','Description','Attribute.keyType','Attribute.keyLength')
                $ignoreColums= @('SSHKeyType','SSHKeyLength','type')
                Export-SymGeneric -ObjectType SSHKeyPairPolicy -List $SSH -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Policy', 'JIT','CustomWorkflow' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting CustomWorkflow"}
                $JIT= Get-SymCustomWorkflow
                $fixedColumns= @('ID','ObjectType','Action','name','applicationType','Description')
                $ignoreColums= @()
                Export-SymCustomWorkflow -List $JIT -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'UserGroup', 'Filter' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Filter"}
                $filter= Get-SymFilter
                $fixedColumns= @('ID','ObjectType','Action')
                $ignoreColums= @('groupID')
                Export-SymFilter -List $filter -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'UserGroup', 'Group' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Group"}
                $group= Get-SymGroup 
                $fixedColumns= @('ID','ObjectType','Action','name','Description')
                $ignoreColums= @('readOnly')
                Export-SymGeneric -ObjectType Group -List $group -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'UserGroup', 'Role' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Role"}
                $role= Get-SymRole
                $fixedColumns= @('ID','ObjectType','Action','name','Description')
                $ignoreColums= @('Readonly')
                Export-SymGeneric -ObjectType Role -List $role -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'UserGroup', 'User' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting User"}
                $user= Get-SymUser
                $fixedColumns= @('ID','ObjectType','Action','name','Description')
                $ignoreColums= @('serverKeyId','userGroupIDs','userID')
                Export-SymGeneric -ObjectType User -List $user -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'UserGroup' -eq $_}
            {    
                if (!$Quiet) {Write-Host "Exporting UserGroup"}
                $userGroup= Get-SymUserGroup
                $fixedColumns= @('ID','ObjectType','Action','name','description','targetGroup','requestorGroup','role')
                $ignoreColums= @('groups','readOnly','groupIDs','roleID')
                Export-SymUserGroup -List $userGroup -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Secret', 'Vault' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Vault"}
                $vault= Get-SymVault
                $fixedColumns= @('ID','ObjectType','Action','name','description')
                $ignoreColums= @()
                Export-SymGeneric -ObjectType Vault -List $vault -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Secret', 'VaultSecret' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting VaultSecret"}
                $vaultSecret= Get-SymVaultSecret
                $fixedColumns= @('ID','ObjectType','Action','vaultName','name','aliases','SecretTypeName','value','format','firstDescriptor','secondDescriptor')
                $ignoreColums= @('ServerKeyID','extensionType')
                Export-SymGeneric -ObjectType VaultSecret -List $vaultSecret -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'AccessPolicy' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting AccessPolicy"}
                $accessPolicy= Get-SymAccessPolicy
                $fixedColumns= @('ID','ObjectType','Action','User','Device')
                $ignoreColums= @()
                Export-SymAccessPolicy -List $accessPolicy -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Service' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Service"}
                $service = Get-SymService
                $fixedColumns = @('ID','ObjectType','Action','Name','ServiceType','localIP','ports','comments')
                $ignoreColums = @()
                Export-SymGeneric -ObjectType Service -List $service -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }

            {'ALL', 'Device' -eq $_}
            {
                if (!$Quiet) {Write-Host "Exporting Device"}
                $device= Get-SymDevice
                $fixedColumns = @('ID','ObjectType','Action','Name')
                $ignoreColums = @('deviceId','deviceName','deviceGroupMembership')
                Export-SymGeneric -ObjectType Device -List $device -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $Timestamp -Delimiter $Delimiter -OutputPath $OutputPath
            }
        }
    }
}

# --- end-of-file ---