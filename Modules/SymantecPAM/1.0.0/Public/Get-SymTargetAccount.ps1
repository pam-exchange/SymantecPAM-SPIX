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

$script:cacheTargetAccountBase= New-Object System.Collections.ArrayList
$script:cacheTargetAccountByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-SymTargetAccount () 
{
    Param(
		[Alias('AccountID')]
        [Parameter(Mandatory=$false)]
		[int] 
		$ID= -1,

		[Alias('AccountName','Name','accName')]
        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[string] 
		$userName,

		[Alias('extensionType')]
        [Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[String] 
		$Type,

		[Alias('appID')]
        [Parameter(Mandatory=$false)]
		[int] 
		$TargetApplicationID= -1,

		[Alias('appName')]
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string] 
        $TargetApplicationName,

		[Alias('srvName','Hostname')]
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string] 
        $TargetServerName,

        #[switch] $ShowPassword= $false,
        #[AllowEmptyString()][string] $Key= "",
        
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymTargetAccount" -Operation {   
                if ($Refresh) {
                    $script:cacheTargetAccountBase.Clear()
                    $script:cacheTargetAccountByID.Clear()
                }
                
                if (-not $script:cacheTargetAccountBase) {
                    $res= _Invoke-SymantecCLI -cmd "searchTargetAccount"
                    foreach ($elm in $res.'cr.result'.TargetAccount) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|type\b|create\w*|update\w*|last\w*)\w+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|update.+|create.+|last.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetAccount" -Force
                        $obj.ID= [int]($obj.ID)
                        
                        if ($obj.extensionType -eq "") {
                            $obj.extensionType= "Generic"
                        }

                        $obj.Password= ""

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

                        $ta= Get-SymTargetApplication -ID $obj.TargetApplicationID
                        $ts= Get-SymTargetServer -ID $ta.TargetServerID

                        $obj | Add-Member -MemberType NoteProperty -Name 'TargetApplicationName' -Value $ta.name
                        $obj | Add-Member -MemberType NoteProperty -Name 'TargetServerID' -Value $ts.ID
                        $obj | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $ts.hostname
                        $obj | Add-Member -MemberType NoteProperty -Name 'deviceName' -Value $ts.deviceName

                        #$pvp= Get-SymPVP -ID $obj.PasswordViewPolicyID
                        $obj | Add-Member -MemberType NoteProperty -Name 'PasswordViewPolicy' -Value (Get-SymPVP -ID $obj.PasswordViewPolicyID).name

                        $obj.PSObject.Properties.Remove('Attribute.extensionType')
                        $obj.PSObject.Properties.Remove('Attribute.ldapObjectID')
                        #$obj.PSObject.Properties.Remove('targetServer')
                        #$obj.PSObject.Properties.Remove('targetServerAlias')
                        #$obj.PSObject.Properties.Remove('targetApplication')
                        #$obj.PSObject.Properties.Remove('compoundServerList')
                        #$obj.PSObject.Properties.Remove('password')

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
                            $p.Value= $p.value -eq "TRUE"
                        }
						#>

                        $idx= $script:cacheTargetAccountBase.Add( $obj )
                        $script:cacheTargetAccountByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheTargetAccountByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheTargetAccountBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheTargetAccountBase

                if ($TargetApplicationID -ge 0) {$res= $res | Where-Object {$_.TargetApplicationID -eq $TargetApplicationID}}				
				if ($useRegex) {
					if ($Type) {$res= $res | Where-Object {$_.extensionType -match $Type}}
					if ($TargetServerName) {$res= $res | Where-Object {$_.Hostname -match $TargetServerName}}
					if ($TargetApplicationName) {$res= $res | Where-Object {$_.TargetApplicationName -match $TargetApplicationName}}
					if ($userName) {$res= $res | Where-Object {$_.userName -match $userName}}
				}
				else {
					if ($Type) {$res= $res | Where-Object {$_.extensionType -like $Type}}
					if ($TargetServerName) {$res= $res | Where-Object {$_.Hostname -like $TargetServerName}}
					if ($TargetApplicationName) {$res= $res | Where-Object {$_.TargetApplicationName -like $TargetApplicationName}}
					if ($userName) {$res= $res | Where-Object {$_.userName -like $userName}}
				}
			}

			# Skip removed entries
            $res= $res | Where-Object {$null -ne $_}
            
			#
			# Check boundary conditions
			#
            if ($null -eq $res) {$cnt= 0}
            elseif ($res.GetType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $res.count}

            if ($NoEmptySet -and $cnt -eq 0) {
                $details= $DETAILS_EXCEPTION_NOT_FOUND_01
                throw ( New-Object SymantecPamException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            if ($single -and $cnt -ne 1) {
                # More than one managed system found with -single option 
                $details= $DETAILS_EXCEPTION_NOT_SINGLE_01
                throw ( New-Object SymantecPamException( $EXCEPTION_NOT_SINGLE, $details ) )
            }

            return $res
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---