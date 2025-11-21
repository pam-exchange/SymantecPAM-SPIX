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

function Sync-SymTargetAccount () 
{
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject] $params
    )
    
	process {
        if ($params.action -notmatch '^(new|update|remove)$') {return $null}

        $srv= $null
        $app= $null
        try {
            if ($params.action -match 'update|remove') {
                $current= Get-SymTargetAccount -ID $params.ID -Single -NoEmptySet
            }

            if ($params.action -eq 'new') {
                if (!$Params.hostname) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'hostName'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }
                if (!$params.TargetApplicationName) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'TargetApplicationName'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }
                if (!$params.userName) {
                    $details= $DETAILS_EXCEPTION_INVALID_PARAMETER_01 -f 'userName'
                    throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $details ) )
                }

                $srv= Get-SymTargetServer -Hostname $params.hostname -Single -NoEmptySet
                $app= Get-SymTargetApplication -TargetServerID $srv.ID -Name $params.TargetApplicationName -Single -NoEmptySet
                $current= Get-SymTargetAccount -TargetApplicationID $app.ID -userName $params.userName -Single -NoEmptySet

                $details= $DETAILS_EXCEPTION_DUPLICATE_APPL_01 -f $params.hostname, $params.TargetApplicationName
                throw ( New-Object SymantecPamException( $EXCEPTION_DUPLICATE, $details ) )
            }
        } catch {
            if ($_.Exception.Message -eq $EXCEPTION_DUPLICATE) {
                throw
            }
        }

        if (!$app) {$app= Get-SymTargetApplication -ID $current.TargetApplicationID -NoEmptySet}
        #$isBuiltInExtensionType= _isBuiltInExtensionType($app.type)

        if (!$srv) {$srv= Get-SymTargetServer -ID $app.TargetServerID -NoEmptySet}


		#
		# Build new parameters
		#
        $newParams= @{}

        if ($params.action -match '(update|remove)') { $newParams+= @{ 'TargetAccount.ID'= $current.ID } }

        if ($params.action -match '(new|update)') {
            $newParams+= @{'TargetApplication.ID'= $app.ID}

            if ($Params.userName) {$newParams+= @{'TargetAccount.userName'= $params.userName}}
            if ($Params.password) {$newParams+= @{'TargetAccount.password'= $params.password}}
            if ($Params.PasswordViewPolicy) {$newParams+= @{'TargetAccount.PasswordViewPolicyID'= (Get-SymPVP -Name $params.PasswordViewPolicy).ID}}

            $newParams+= @{'TargetAccount.privileged'= 'true'}
            if ($Params.cacheBehavior -or $params.cacheDuration -or $params.aliases) {
                $newParams.'TargetAccount.privileged'= 'false'
            }

            if ($Params.cacheBehavior) {$newParams+= @{'TargetAccount.cacheBehavior'= $params.cacheBehavior}}
            if ($Params.cacheDuration) {$newParams+= @{'TargetAccount.cacheDuration'= $params.cacheDuration}}
            if ($Params.aliases) {
                $newParams+= @{'TargetAlias.name'= $params.aliases}
                $newParams+= @{useTargetAliasNameParameter= 'true'}
            } else {
                $newParams+= @{useTargetAliasNameParameter= 'false'}
            }

            if ($Params.accessType) {$newParams+= @{'TargetAccount.accessType'= $params.accessType}}

            if ($Params.compoundServerIDs) {
                $newParams+= @{'TargetAccount.compoundServerIDs'= $params.compoundServerIDs}
                $newParams+= @{'TargetAccount.compoundAccount'= 'true'}
            }

            if ($Params.synchronize -and -not $newParams.'TargetAccount.compoundAccount') {
                $newParams+= @{'TargetAccount.synchronize'= $params.synchronize.ToLower()}
            }

            # Add all 'Attribute' parameters
            foreach ($p in $($params.PSobject.Properties | Where-Object {$_.Name -like 'Attribute*'})) {
                if ($p.value -match '^(TRUE|FALSE)$') {$p.value = $p.value.toLower()} 
                $newParams+= @{ $p.Name= $p.value }
            }
        }

        #
        # Call CLI to add/update account
        #
        switch ($params.action) {
        'new' {
            $res= _Invoke-SymantecCLI -cmd "addTargetAccount" -params $newParams
            break
        } 
        'update' {
            $res= _Invoke-SymantecCLI -cmd "updateTargetAccount" -params $newParams
            break
        }
        'remove' {
            $res= _Invoke-SymantecCLI -cmd "deleteTargetAccount" -params $newParams
            break
        }
        }

        $elm= $res.'cr.result'.TargetAccount
        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|update.+|create.+|last.+)'
		$obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetAccount"
        $obj.ID= [int]($obj.ID)
                    
        if ($obj.extensionType -eq "") {
            $obj.extensionType= "Generic"
        }

        $obj.Password= "N/A"

        if ($obj.privileged -eq "TRUE") {
            # TargetAccount is not A2A
            $obj.cacheAllow= $null
            $obj.cacheBehavior= $null
            $obj.cacheBehaviorInt= $null
            $obj.cacheDuration= $null
        }

        if ($obj.compoundServerList -eq "[]") {$obj.compoundServerList= $null}
        if ($obj.ownerUserID -eq "-1") {$obj.ownerUserID= $null}
        if ($obj.parentAccountId -eq "-1") {$obj.parentAccountId= $null}

        $obj | Add-Member -MemberType NoteProperty -Name 'TargetApplicationName' -Value $app.name
        $obj | Add-Member -MemberType NoteProperty -Name 'TargetServerID' -Value $srv.ID
        $obj | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $srv.hostname
        $obj | Add-Member -MemberType NoteProperty -Name 'deviceName' -Value $srv.deviceName

        #$pvp= Get-SymPVP -ID $obj.PasswordViewPolicyID
        $obj | Add-Member -MemberType NoteProperty -Name 'PasswordViewPolicy' -Value (Get-SymPVP -ID $obj.PasswordViewPolicyID).name

        $obj.PSObject.Properties.Remove('Attribute.extensionType')
        $obj.PSObject.Properties.Remove('Attribute.ldapObjectID')
        $obj.PSObject.Properties.Remove('targetApplication')
        $obj.PSObject.Properties.Remove('targetServer')
        $obj.PSObject.Properties.Remove('targetServerAlias')
        #$obj.PSObject.Properties.Remove('compoundServerList')
        #$obj.PSObject.Properties.Remove('password')

        switch ($params.action) {
        'new' {
            $idx= $script:cacheTargetAccountBase.Add( $obj )
            $script:cacheTargetAccountByID.Add( [int]($obj.ID), [int]($idx) )
            break
        } 
        'update' {
            $idx= $script:cacheTargetAccountByID[ [int]($obj.ID) ]
            $script:cacheTargetAccountBase[ $idx ]= $obj
            break
        }
        'remove' {
            $idx= $script:cacheTargetAccountByID[ [int]($obj.ID) ]
            $script:cacheTargetAccountBase[ $idx ]= $null
            break
        }
        }

        return $obj
    }
}
# --- end-of-file ---