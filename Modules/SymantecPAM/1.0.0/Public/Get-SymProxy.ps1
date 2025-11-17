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

$script:cacheProxyBase= New-Object System.Collections.ArrayList
$script:cacheProxyByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymProxy () 
{
    Param(
		[Alias("ProxyID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Hostname,
        [Parameter(Mandatory=$false)][string] $ipAddress,
		[Parameter(Mandatory=$false)][string] $DeviceName,
		[Parameter(Mandatory=$false)][string] $ClientVersion,
		[Parameter(Mandatory=$false)][string] $Active,
		[Parameter(Mandatory=$false)][string] $ActionRequired,

		[Parameter(Mandatory=$false)][string] $Descriptor1,
		[Parameter(Mandatory=$false)][string] $Descriptor2,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymProxy" -Operation {   
                if ($Refresh) {
                    $script:cacheProxyBase.Clear()
                    $script:cacheProxyByID.Clear()
                }
                if (-not $script:cacheProxyBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "searchAgent"

                    # Object is a type RequestServer, with type=AGENT

                    foreach ($elm in $res.'cr.result'.RequestServer) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Proxy"
                        $obj.ID= [int]($obj.ID)

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
                            $p.Value= $p.value -eq "TRUE"
                        }
						#>

                        $idx= $script:cacheProxyBase.Add( $obj )
                        $script:cacheProxyByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing filtering by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheProxyByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheProxyBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheProxyBase
				
				if ($useRegex) {
					if ($Hostname) {$res= $res | Where-Object {$_.Hostname -match $Hostname}}
					if ($ipAddress) {$res= $res | Where-Object {$_.ipAddress -match $ipAddress}}
					if ($DeviceName) {$res= $res | Where-Object {$_.DeviceName -match $DeviceName}}
					if ($ClientVersion) {$res= $res | Where-Object {$_.ClientVersion -match $ClientVersion}}
					if ($Active) {$res= $res | Where-Object {$_.Active -match $Active}}
					if ($ActionRequired) {$res= $res | Where-Object {$_.ActionRequired -match $ActionRequired}}
				}
				else {
					if ($Hostname) {$res= $res | Where-Object {$_.Hostname -like $Hostname}}
					if ($ipAddress) {$res= $res | Where-Object {$_.ipAddress -like $ipAddress}}
					if ($DeviceName) {$res= $res | Where-Object {$_.DeviceName -like $DeviceName}}
					if ($ClientVersion) {$res= $res | Where-Object {$_.ClientVersion -like $ClientVersion}}
					if ($Active) {$res= $res | Where-Object {$_.Active -like $Active}}
					if ($ActionRequired) {$res= $res | Where-Object {$_.ActionRequired -like $ActionRequired}}
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