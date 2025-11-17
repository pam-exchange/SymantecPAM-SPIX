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

$script:cacheAccessPolicyBase= New-Object System.Collections.ArrayList
$script:cacheAccessPolicyByID= New-Object System.Collections.HashTable		# Index into cache array


#--------------------------------------------------------------------------------------
function Get-SymAccessPolicy () 
{
    Param(
		[Alias("RoleID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $UserName,
        [Parameter(Mandatory=$false)][string] $DeviceName,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymAccessPolicy" -Operation {   
                if ($Refresh) {
                    $script:cacheAccessPolicyBase.Clear()
                    $script:cacheAccessPolicyByID.Clear()
                }
                if (-not $script:cacheAccessPolicyBase) {

                    $params= @{
                        limit=0;
                        fields='id'
                    }
                    
                    $res= _Invoke-SymantecAPI -cmd '/api.php/v1/policies.json' -method GET -Params $params

                    foreach ($paid in $res.policyAssociationInfos) {

                        $elm= _Invoke-SymantecAPI -cmd "/api.php/v1/policies.json/$($paid.id)" -method GET

                        $obj= $elm | Select-Object -Property * -ExcludeProperty createDate,createUser,updateDate,updateUser,lastUpdated
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "AccessPolicy"
                        $obj.ID= [int]($obj.ID)

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(T|F)$"}) {
                            $p.Value= $p.value -eq "T"
                        }
						#>

                        $idx= $script:cacheAccessPolicyBase.Add( $obj )
                        $script:cacheAccessPolicyByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheAccessPolicyByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheAccessPolicyBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheAccessPolicyBase

				if ($useRegex) {
					if ($UserName) {$res= $res | Where-Object {$_.User.Name -match $UserName}}
					if ($DeviceName) {$res= $res | Where-Object {$_.Device.Name -match $DeviceName}}
				}
				else {
					if ($UserName) {$res= $res | Where-Object {$_.User.Name -like $UserName}}
					if ($DeviceName) {$res= $res | Where-Object {$_.Device.Name -like $DeviceName}}
                }
			}


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