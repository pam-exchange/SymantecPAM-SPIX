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


# OneOfEachExtension= $list | Group-Object ExtensionType | ForEach-Object { $_.Group[0] }
# $allPossibleAttributes= $OneOfEachExtension | ForEach-Object {$_.PSObject.Properties.Name} | Sort-Object -unique

enum DONOTIMPORT {
    AzureAccessCredentials
    AwsApiProxyCredentials
    AwsAccessCredentials
    nsxcontroller
    nsxmanager
    nsxproxy
}


#--------------------------------------------------------------------------------------
function Import-SymTargetApplication (
    [Parameter(Mandatory=$false,ParameterSetName="CSV")][PSCustomObject] $InputCsv
)
{
	process {
        $failedImport= New-Object System.Collections.ArrayList
        foreach ($row in $InputCsv) {
            try {
                if ($row.Action -notmatch "^(Update|New)$") {
                    continue
                }

                if ($row.extensionType -in [DONOTIMPORT].GetEnumNames()) {
                    $details= $DETAILS_EXCEPTION_CANNOT_IMPORT_01 -f $row.extensionType
                    throw ( New-Object SymantecPAMException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }

                $params= $row | Select-Object * -ExcludeProperty ObjectType,deviceName

                #if ($params.extensionType) {$params | Add-Member -NotePropertyName 'TargetApplication.type' -NotePropertyValue $params.extensionType}
                #if ($params.name) {$params | Add-Member -NotePropertyName 'TargetApplication.name' -NotePropertyValue $params.name}
                if ($params.hostName) {
                    $params | Add-Member -NotePropertyName 'TargetServer.hostName' -NotePropertyValue $params.hostName -Force
                }
                if ($params.PCP) {
                    $params | Add-Member -NotePropertyName 'PasswordPolicy.ID' -NotePropertyValue (Get-SymPcp -name $params.PCP -Single -NoEmptySet).ID
                } 

                foreach ($p in $params.PSObject.Properties | Where-Object {$_.Name -like 'Attribute*'}) {
                    if ($p.Value -match "^(TRUE|FALSE)$") {$p.Value= $p.Value.toLower()}
                }

                switch($params.extensionType) {
                'activeDirectorySshKey' {
                    if ($params.'Attribute.sshKeyPairPolicy') {
                        $params | Add-Member -NotePropertyName 'Attribute.sshKeyPairPolicyID' -NotePropertyValue (Get-SymSSHKeyPairPolicy -Name $params.'Attribute.sshKeyPairPolicy').ID -Force
                        $params.PSObject.Properties.Remove('Attribute.sshKeyPairPolicy')
                    }
                    break
                }
                'CiscoSSH' {
                    if ($params.'Attribute.useUpdateScriptType') {$params.'Attribute.useUpdateScriptType'= $params.'Attribute.useUpdateScriptType'.ToUpper()}
                    if ($params.'Attribute.useVerifyScriptType') {$params.'Attribute.useVerifyScriptType'= $params.'Attribute.useVerifyScriptType'.ToUpper()}
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToUpper()}
                    if ($params.'Attribute.pwType') {$params.'Attribute.pwType'= $params.'Attribute.pwType'.ToLower()}
                    break
                }
                {'juniper',
                 'oracle',
                 'vmware',
                 'weblogic10',
                 'windowsRemoteAgent',
                 'windowsSshPassword' -eq $_} {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    break
                }
                'ldap' {
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToLower()}
                    break
                }
                {'mssql',
                 'mssqlAzureMI' -eq $_} {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    if ($params.'Attribute.customWorkflow') {
                        $params | Add-Member -NotePropertyName 'Attribute.customWorkflowId' -NotePropertyValue (Get-SymCustomWorkflow -Name $params.'Attribute.customWorkflow' -Single -NoEmptySet).ID
                        $params.PSObject.Properties.Remove('Attribute.customWorkflow')
                    }
                    break
                }
                'ServiceNow' {
                    if ($params.'Attribute.serviceNowApiType') {$params.'Attribute.serviceNowApiType'= $params.'Attribute.serviceNowApiType'.ToUpper()}
                    if ($params.'Attribute.serviceNowAuthType') {$params.'Attribute.serviceNowAuthType'= $params.'Attribute.serviceNowAuthType'.ToUpper()}
                    break
                }
                'SPML2' {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToLower()}
                    break
                }
                'unixII' {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    if ($params.'Attribute.sshKeyPairPolicy') {
                        $params | Add-Member -NotePropertyName 'Attribute.sshKeyPairPolicyID' -NotePropertyValue (Get-SymSSHKeyPairPolicy -Name $params.'Attribute.sshKeyPairPolicy').ID -Force
                        $params.PSObject.Properties.Remove('Attribute.sshKeyPairPolicy')
                    }
                    break
                }
                'windows' {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    # resolve proxy agents
                    $proxyId= ""
                    foreach ($name in $($row.'Attribute.proxy'.split("|").trim())) {
                        if ($proxyId) {$proxyId+= ","}
                        $proxyId+= (Get-SymTargetServer -Name $name).ID
                    }
                    $params | Add-Member -NotePropertyName 'Attribute.agentId' -NotePropertyValue $proxyId -Force
                    break
                }
                'windowsSshKey' {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    if ($params.'Attribute.sshKeyPairPolicy') {
                        $params | Add-Member -NotePropertyName 'Attribute.sshKeyPairPolicyID' -NotePropertyValue (Get-SymSSHKeyPairPolicy -Name $params.'Attribute.sshKeyPairPolicy').ID -Force
                        $params.PSObject.Properties.Remove('Attribute.sshKeyPairPolicy')
                    }
                    break
                }
                }

                $res= Sync-SymTargetApplication -params $params
            }
            catch {
                $row | Add-Member -NotePropertyName ErrorMessage -NotePropertyValue "$($_.Exception.Message) -- $($_.Exception.Details)" -Force
                $failedImport.add( $row ) | Out-Null
            }
        }
        return $failedImport
    }
}

# --- end-of-file ---