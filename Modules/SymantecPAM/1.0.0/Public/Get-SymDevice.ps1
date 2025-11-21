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

$script:cacheDeviceBase= New-Object System.Collections.ArrayList
$script:cacheDeviceByID= New-Object System.Collections.HashTable		# Index into cache array


#--------------------------------------------------------------------------------------
function Get-SymDevice () 
{
    Param(
		[Alias("DeviceID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Alias("DeviceName")]
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $DomainName,
        [Parameter(Mandatory=$false)][string] $Description,
        [Parameter(Mandatory=$false)][switch] $typeAccess= $false,
        [Parameter(Mandatory=$false)][switch] $typeA2A= $false,
        [Parameter(Mandatory=$false)][switch] $typePassword= $false,
        [Parameter(Mandatory=$false)][switch] $typePamsc= $false,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymDevice" -Operation {   
                if ($Refresh) {
                    $script:cacheDeviceBase.Clear()
                    $script:cacheCustomWorkflowByID.Clear()
                }
                if (-not $script:cacheDeviceBase) {

                    $params= @{
                        limit=0;
                        fields='deviceId%2CdeviceName%2CdomainName%2Cdescription%2Cos%2Ctype%2CtypeAccess%2CtypePassword%2CtypeA2A%2CtypePamsc%2CshortName%2CprovisionType%2CdeviceGroupMembership'
                    }

                    $res= _Invoke-SymantecAPI -cmd "/api.php/v1/devices.json" -method GET
                    foreach ($elm in $res.devices) {
                        $obj= $elm | Select-Object -Property * -ExcludeProperty createDate,createUser,updateDate,updateUser
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Device" -Force
                        $obj | Add-Member -MemberType NoteProperty -Name 'ID' -Value $obj.deviceId -Force
                        $obj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $obj.deviceName -Force
                        $obj.ID= [int]($obj.ID)

                        $idx= $script:cacheDeviceBase.Add( $obj )
                        $script:cacheDeviceByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing Grouping by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheDeviceByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheDeviceBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheDeviceBase

				if ($typeAccess) {$res= $res | Where-Object {$_.typeAccess -eq 't'}}
				if ($typeA2A) {$res= $res | Where-Object {$_.typeA2A -eq 't'}}
				if ($typePassword) {$res= $res | Where-Object {$_.typePassword -eq 't'}}
				if ($typePamsc) {$res= $res | Where-Object {$_.typePamsc -eq 't'}}

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -match $Description}}
					if ($DomainName) {$res= $res | Where-Object {$_.DomainName -match $DomainName}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
					if ($DomainName) {$res= $res | Where-Object {$_.DomainName -like $DomainName}}
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