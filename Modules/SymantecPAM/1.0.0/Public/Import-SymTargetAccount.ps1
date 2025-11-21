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


#--------------------------------------------------------------------------------------
function Import-SymTargetAccount (
    [Parameter(Mandatory=$false,ParameterSetName="CSV")][PSCustomObject[]] $InputCsv,
    [switch] $UpdatePassword= $false,
    [string] $Passphrase= ""
)
{
	process {
        $failedImport= New-Object System.Collections.ArrayList
        foreach ($row in $InputCsv) {
            try {
                if ($row.Action -notmatch "^(Update|New|Remove)$") {
                    continue
                }
                $params= $row | Select-Object * -ExcludeProperty cacheAllow,ObjectType,deviceName,PasswordVerified,'Attribute.isProvisionedAccount'

                switch($params.extensionType) {

                {'AwsAccessCredentials','AS400','CiscoSSH','HPServiceManager','juniper','ldap','mssql','mssqlAzureMI',
                 'mysql','oracle','PaloAlto','remedy','ServiceDeskBroker','SPML2','sybase','unixII','vmware','weblogic10',
                 'windows','windowsDomainService','windowsRemoteAgent','XsuiteApiKey' -eq $_} 
                {
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'Attribute.otherAccount')
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'true' -Force
                    } else {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false' -Force
                    }
                    # break <-- no break here
                }

                {'juniper','SPML2','sybase','vmware','weblogic10','windowsDomainService','windowsRemoteAgent','XsuiteApiKey' -eq $_} 
                {
                    $params | Add-Member -NotePropertyName 'Attribute.extensionType' -NotePropertyValue $params.extensionType -Force
                    # break <-- no break here
                }

                {'activeDirectorySshKey','vcf' -eq $_} {
                    if ($params.'Attribute.anotherAccount') {
                        $params.'Attribute.anotherAccount'= _decodeOtherAccount($params.'Attribute.anotherAccount')
                    }
                    break
                }

                'AwsAccessCredentials' {
                    if ($params.'Attribute.awsCredentialType') {$params.'Attribute.awsCredentialType'= $params.'Attribute.awsCredentialType'.ToUpper()}
                    break
                }

                'CiscoSSH' {
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToUpper()}
                    if ($params.'Attribute.pwType') {$params.'Attribute.pwType'= $params.'Attribute.pwType'.ToLower()}
                    
                    if ($params.'Attribute.otherPrivilegedAccount') {
                        $params.'Attribute.otherPrivilegedAccount'= _decodeOtherAccount($params.'Attribute.otherPrivilegedAccount')
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherPrivilegedAccount' -NotePropertyValue 'true' -Force
                    } else {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherPrivilegedAccount' -NotePropertyValue 'false' -Force
                    }
                    break
                }

                'unixII' {
                    if ($params.'Attribute.passwordChangeMethod') {$params.'Attribute.passwordChangeMethod'= $params.'Attribute.passwordChangeMethod'.ToUpper()}
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToUpper()}
                    break
                }

                'windowsRemoteAgent' {
                    if ($params.'Attribute.accountType') {$params.'Attribute.accountType'= $params.'Attribute.accountType'.ToLower()}
                    break
                }

                'windowsSshKey' {
                    if ($params.'Attribute.changeProcess') {$params.'Attribute.changeProcess'= $params.'Attribute.changeProcess'.ToUpper()}
                    if ($params.'Attribute.protocol') {$params.'Attribute.protocol'= $params.'Attribute.protocol'.ToUpper()}
                    break
                }

                'windowsSshPassword' {
                    if ($params.'Attribute.changeProcess') {$params.'Attribute.changeProcess'= $params.'Attribute.changeProcess'.ToUpper()}
                    break
                }
                } # end switch

                # 
                # Some TCF connectors may use 'loginAccount' 
                #
                if (-not $(_isBuiltInExtensionType($params.extensionType))) {
                    if ($params.'Attribute.loginAccount' -match '\|') {
                        $params.'Attribute.loginAccount'= _decodeOtherAccount($params.'Attribute.loginAccount')
                    }
                    if ($params.'Attribute.otherAccount' -match '\|') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'Attribute.otherAccount')
                    }
                }

                #
                # Decrypt password
                #
                if ($params.password -and $params.password.StartsWith('{enc}')) {
                    $params.password= _Decrypt-PBKDF2 -CipherBase64 $params.password.substring(5) -Password $Passphrase
                }

                # Update/New/Remove from PAM
                $res= Sync-SymTargetAccount -params $params

                #
                # Update Password
                #
                if ($updatePassword -and $row.action -eq 'new' -and $row.password -and $row.password -ne '_generate_pass_') {
                    $params= $res
                    $params | Add-Member -NotePropertyName 'Action' -NotePropertyValue 'update' -Force
                    $params.password= '_generate_pass_'
                    $res= Sync-SymTargetAccount -params $params
                }
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