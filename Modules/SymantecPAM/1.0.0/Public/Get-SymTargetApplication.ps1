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

$script:cacheTargetApplicationBase= New-Object System.Collections.ArrayList
$script:cacheTargetApplicationByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-SymTargetApplication () 
{
    Param(
		[Alias('TargetApplicationID','appID')]
        [Parameter(Mandatory=$false)]
        [int] 
        $ID= -1,

		[Alias('TargetApplicationName','appName')]
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string] 
        $Name,

        [Alias('extensionType')]
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string] 
        $Type,

        [Parameter(Mandatory=$false)]
        [int] 
        $DeviceID= -1,

        [Parameter(Mandatory=$false)]
        [String] 
        $DeviceName,

		[Alias('srvID')]
        [Parameter(Mandatory=$false)]
        [int] 
        $TargetServerID= -1,

		[Alias('srvName')]
        [Parameter(Mandatory=$false)]
        [String] 
        $hostName,

        [Parameter(Mandatory=$false)][int] $PcpID= -1,
        [Parameter(Mandatory=$false)][String] $PcpName,
        
        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymTargetApplication" -Operation {
                if ($Refresh) {
                    $script:cacheTargetApplicationBase.Clear()
                    $script:cacheTargetApplicationByID.Clear()
                }
                if (-not $script:cacheTargetApplicationBase) {
                    $res= _Invoke-SymantecCLI -cmd 'searchTargetApplication'

                    foreach ($elm in $res.'cr.result'.TargetApplication) {

                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|type|targetServer\b|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetApplication"
                        $obj.ID= [int]($obj.ID)

                        #if ($obj."Attribute.isSecretType" -eq "true") {continue}

                        if ($obj.extensionType -eq "") {
                            $obj.extensionType= "Generic"
                        }

                        $srv= Get-SymTargetServer -ID $obj.TargetServerID

                        $obj | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $srv.hostname
                        $obj | Add-Member -MemberType NoteProperty -Name 'deviceName' -Value $srv.deviceName

                        $obj.PSObject.Properties.Remove('Attribute.extensionType')
                        #$obj.PSObject.Properties.Remove('policyID')

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
                            $p.Value= $p.value -eq "TRUE"
                        }
						#>

                        $idx= $script:cacheTargetApplicationBase.Add( $obj )
                        $script:cacheTargetApplicationByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheTargetApplicationByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheTargetApplicationBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheTargetApplicationBase


                if ($PcpName) { $PcpID= (Get-SymPCP -Name $PcpName -Single -NoEmptySet).ID }

				if ($DeviceID -ge 0) {$res= $res | Where-Object {$_.DeviceID -eq $DeviceID}}
				if ($TargetServerID -ge 0) {$res= $res | Where-Object {$_.TargetServerID -eq $TargetServerID}}
				if ($PcpID -ge 0) {$res= $res | Where-Object {$_.policyID -eq $PcpID}}

				if ($useRegex) {
					if ($name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($deviceName) {$res= $res | Where-Object {$_.deviceName -match $deviceName}}
					if ($hostname) {$res= $res | Where-Object {$_.hostname -match $hostname}}
                    #if ($PcpName) {$res= $res | Where-Object {$_.policyName -match $PcpName}}
					if ($Type) {$res= $res | Where-Object {$_.extensionType -match $Type}}
				}
				else {
					if ($name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($deviceName) {$res= $res | Where-Object {$_.deviceName -like $deviceName}}
					if ($hostname) {$res= $res | Where-Object {$_.hostname -like $hostname}}
                    #if ($PcpName) {$res= $res | Where-Object {$_.policyName -like $PcpName}}
					if ($Type) {$res= $res | Where-Object {$_.extensionType -like $Type}}
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
                $details= $DETAILS_EXCEPTION_NOT_FOUND_02 -f $($MyInvocation.MyCommand.Name),$Name
                throw ( New-Object SymantecPamException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            if ($single -and $cnt -ne 1) {
                # More than one managed system found with -single option 
                $details= $DETAILS_EXCEPTION_NOT_SINGLE_02 -f $($MyInvocation.MyCommand.Name)
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