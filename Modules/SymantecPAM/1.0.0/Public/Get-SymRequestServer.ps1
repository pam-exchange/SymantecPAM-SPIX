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

$script:cacheRequestServerBase= New-Object System.Collections.ArrayList
$script:cacheRequestServerByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymRequestServer () 
{
    Param(
		[Alias("RequestServerID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Alias('Name','RequestServerName')]
        [Parameter(Mandatory=$false)][string] $Hostname,
        [Parameter(Mandatory=$false)][string] $ipAddress,
		[Parameter(Mandatory=$false)][string] $DeviceName,
		[Parameter(Mandatory=$false)][string] $ClientVersion,
		[Parameter(Mandatory=$false)][switch] $Active,
		[Parameter(Mandatory=$false)][switch] $ActionRequired,

		[Parameter(Mandatory=$false)][string] $Descriptor1,
		[Parameter(Mandatory=$false)][string] $Descriptor2,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymRequestServer" -Operation {   
                if ($Refresh) {
                    $script:cacheRequestServerBase.Clear()
                    $script:cacheRequestServerByID.Clear()
                }
                if (-not $script:cacheRequestServerBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "searchRequestServer"

                    foreach ($elm in $res.'cr.result'.RequestServer) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "RequestServer"
                        $obj.ID= [int]($obj.ID)

                        $obj.PSObject.Properties.Remove('pendingAcknowledgement')
                        $obj.PSObject.Properties.Remove('currentKey')
                        $obj.PSObject.Properties.Remove('oldKey')
                        $obj.PSObject.Properties.Remove('lastDigestLoginDate')
                        $obj.PSObject.Properties.Remove('lastPatchStatusChangeDate')

                        $idx= $script:cacheRequestServerBase.Add( $obj )
                        $script:cacheRequestServerByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing filtering by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheRequestServerByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheRequestServerBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheRequestServerBase
				
				if ($Active) {$res= $res | Where-Object {$_.Active -eq 'true'}}
				if ($ActionRequired) {$res= $res | Where-Object {$_.ActionRequired -eq 'true'}}

				if ($useRegex) {
					if ($Hostname) {$res= $res | Where-Object {$_.Hostname -match $Hostname}}
					if ($ipAddress) {$res= $res | Where-Object {$_.ipAddress -match $ipAddress}}
					if ($DeviceName) {$res= $res | Where-Object {$_.DeviceName -match $DeviceName}}
					if ($ClientVersion) {$res= $res | Where-Object {$_.ClientVersion -match $ClientVersion}}
					if ($Descriptor1) {$res= $res | Where-Object {$_.descriptor1 -match $Descriptor1}}
					if ($Descriptor2) {$res= $res | Where-Object {$_.descriptor2 -match $Descriptor2}}
				}
				else {
					if ($Hostname) {$res= $res | Where-Object {$_.Hostname -like $Hostname}}
					if ($ipAddress) {$res= $res | Where-Object {$_.ipAddress -like $ipAddress}}
					if ($DeviceName) {$res= $res | Where-Object {$_.DeviceName -like $DeviceName}}
					if ($ClientVersion) {$res= $res | Where-Object {$_.ClientVersion -like $ClientVersion}}
					if ($Descriptor1) {$res= $res | Where-Object {$_.descriptor1 -like $Descriptor1}}
					if ($Descriptor2) {$res= $res | Where-Object {$_.descriptor2 -like $Descriptor2}}
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
                $details= $DETAILS_EXCEPTION_NOT_FOUND_02 -f $($MyInvocation.MyCommand.Name),$Hostname
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