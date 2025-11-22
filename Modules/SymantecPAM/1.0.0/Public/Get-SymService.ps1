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

$script:cacheServiceBase= New-Object System.Collections.ArrayList
$script:cacheServiceNyID= New-Object System.Collections.HashTable		# Index into cache array

enum SERVICETYPE {
    ALL
    TCPUDP
    RDPApplication
    SSLVPN
}

#--------------------------------------------------------------------------------------
function Get-SymService () 
{
    Param(
		[Alias("RoleID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $Description,
        [Parameter(Mandatory=$false)][SERVICETYPE] $Type= 'ALL',

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymService" -Operation {   
                if ($Refresh) {
                    $script:cacheServiceBase.Clear()
                    $script:cacheServiceNyID.Clear()
                }
                if (-not $script:cacheServiceBase) {
                    foreach ($t in [SERVICETYPE].GetEnumNames()) {
                        if ($t -eq 'ALL') {continue}

                        $body= @{
                            type= $t
                            fields= '*'
                            limit= 0
                        }

                        $res= _Invoke-SymantecAPI -cmd "/api.php/v1/services.json" -method GET -params $body

                        foreach ($elm in $res.services) {
                            $obj= $elm | Select-Object -Property * -ExcludeProperty createDate,createUser,updateDate,updateUser
                            $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value 'Service'
                            $obj | Add-Member -MemberType NoteProperty -Name 'ServiceType' -Value $t

                            $obj | Add-Member -MemberType NoteProperty -Name 'ID' -Value ([int]($obj.serviceId))
                            $obj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $obj.serviceName
                            $obj.PSObject.Properties.Remove('serviceId')
                            $obj.PSObject.Properties.Remove('serviceName')

							<#
							foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
								$p.Value= $p.value -eq "TRUE"
							}
							#>

                            $idx= $script:cacheServiceBase.Add( $obj )
                            $script:cacheServiceNyID.Add( [int]($obj.ID), [int]($idx) )
                        }
                    }
                }
            }

			# Skip removed entries
            $res= $res | Where-Object {$null -ne $_}
            
            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheServiceNyID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheServiceBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheServiceBase
        		if ($Type -ne 'ALL') {$res= $res | Where-Object {$_.Type -eq $Type}}

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -match $Description}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
                }
			}


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