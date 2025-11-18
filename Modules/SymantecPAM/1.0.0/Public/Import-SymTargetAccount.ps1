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
                'AwsAccessCredentials' {
                    if ($params.'Attribute.awsCredentialType') {$params.'Attribute.awsCredentialType'= $params.'Attribute.awsCredentialType'.ToUpper()}
                    #$params.'Attribute.passphrase'
                    #$params.'Attribute.awsKeyPairName'
                    #$params.'Attribute.accountFriendlyName'
                    #$params.'Attribute.awsAccessKeyAlias'
                    #$params.'Attribute.awsAccessRole'
                    #$params.'Attribute.awsCloudType'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'AS400' {
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'CiscoSSH' {
                    #$params.'Attribute.protocol'
                    #$params.'Attribute.protocol'
                    #$params.'Attribute.pwType'
                    #$params.'Attribute.changeAuxLoginPassword'
                    #$params.'Attribute.changeConsoleLoginPassword'
                    #$params.'Attribute.changeVtyLoginPassword'
                    #$params.'Attribute.numVTYPorts'

                    if (!$params.'Attribute.useOtherPrivilegedAccount') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherPrivilegedAccount' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherPrivilegedAccount') {
                        $params.'Attribute.otherPrivilegedAccount'= _decodeOtherAccount($params.'Attribute.otherPrivilegedAccount')
                        $params.'Attribute.useOtherPrivilegedAccount'= 'true'
                    } else {
                        $params.'Attribute.useOtherPrivilegedAccount'= 'false'
                    }

                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'HPServiceManager' {
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'juniper' {
                    $params.'Attribute.extensionType'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'ldap' {
                    $params.'Attribute.userDN'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'mssql' {
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'mssqlAzureMI' {
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'mysql' {
                    $params.'Attribute.schema'
                    $params.'Attribute.hostNameQualifier'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'oracle' {
                    #$params.'Attribute.schema'
                    #$params.'Attribute.useOid'
                    #$params.'Attribute.sid'
                    #$params.'Attribute.cn'
                    #$params.'Attribute.racService'
                    #$params.'Attribute.sysdbaAccount'
                    #$params.'Attribute.replaceSyntax'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'PaloAlto' {
                    #$params.'Attribute.protocol'
                    #$params.'Attribute.pwType'
                    #$params.'Attribute.useOtherAccountToChangePassword'
                    #$params.'Attribute.otherPrivilegedAccount'
                    #$params.'Attribute.changeAuxLoginPassword'
                    #$params.'Attribute.changeConsoleLoginPassword'
                    #$params.'Attribute.changeVtyLoginPassword'
                    #$params.'Attribute.numVTYPorts'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'SPML2' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'sybase' {
                    #$params.'Attribute.schema'
                    $params.'Attribute.extensionType'= $params.extensionType
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'unixII' {
                    #$params.'Attribute.verifyThroughOtherAccount'
                    #$params.'Attribute.passwordChangeMethod'
                    #$params.'Attribute.protocol'
                    #$params.'Attribute.publicKey'
                    #$params.'Attribute.keyOptions'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'vmware' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'weblogic10' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    #$params.'Attribute.realm'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'windowsDomainService' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    #$params.'Attribute.userDN'
                    #$params.'Attribute.serviceInfo'
                    #$params.'Attribute.tasks'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'windowsRemoteAgent' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    #$params.'Attribute.accountType'
                    #$params.'Attribute.serviceInfo'
                    #$params.'Attribute.tasks'
                    #$params.'Attribute.forcePasswordChange'
                    if (!$params.'Attribute.useOtherAccountToChangePassword') {
                        $params | Add-Member -NotePropertyName 'Attribute.useOtherAccountToChangePassword' -NotePropertyValue 'false'
                    }
                    if ($params.'Attribute.otherAccount') {
                        $params.'Attribute.otherAccount'= _decodeOtherAccount($params.'otherAccount')
                        $params.'Attribute.useOtherAccountToChangePassword'= 'true'
                    } else {
                        $params.'Attribute.useOtherAccountToChangePassword'= 'false'
                    }
                    break
                }
                'windowsSshKey' {
                    $params.'Attribute.extensionType'= $params.extensionType
                    #$params.'Attribute.changeProcess'
                    break
                }

                <#
                'AwsAccessCredentials' {break}
                'Generic' {break}
                'nsxcontroller' {break}
                'nsxmanager' {break}
                'nsxproxy' {break}
                'RadiusTacacsSecret' {break}
                'remedy' {break}
                'ServiceDeskBroker' {break}
                'ServiceNow' {break}
                'vcf' {break}
                'windows' {break}
                'windowsSshPassword' {break}
                'XsuiteApiKey' {break}
                #>

                } # end switch

                # 
                # Some TCF connectors may use 'loginAccount' 
                #
                if ($params.'Attribute.loginAccount') {
                    $params.'Attribute.loginAccount'= _decodeOtherAccount($params.'Attribute.loginAccount')
                }

                #
                # Decrypt password
                #
                if ($params.password -and $params.password.StartsWith('{enc}')) {
                    $params.password= _Decrypt-PBKDF2 -CipherBase64 $params.password -Password $Passphrase
                }

                # Update/New/Remove from PAM
                $res= Sync-SymTargetAccount -params $params
            }
            catch {
                $row | Add-Member -NotePropertyName ErrorMessage -NotePropertyValue "$($_.Exception.Message) -- $($_.Exception.Details)"
                if ($FailedInputFile) {
                    $row | Select-object ErrorMessage,* -ExcludeProperty Status | Export-Csv -Path $FailedInputFile -Delimiter $Delimiter -Append -NoTypeInformation
                }
                else {
                    $failedImport.add( $row ) | Out-Null
                }
            }
        }
        return $failedImport
     }
}

# --- end-of-file ---