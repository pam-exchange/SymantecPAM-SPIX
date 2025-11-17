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

$script:cacheUserBase= New-Object System.Collections.ArrayList
$script:cacheUserByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-SymUser () 
{
    Param(
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $FirstName,
        [Parameter(Mandatory=$false)][String] $LastName,
        [Parameter(Mandatory=$false)][int] $UserGroupID= -1,
        [Parameter(Mandatory=$false)][String] $AuthenticationType,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymUser" -Operation {   
                if ($Refresh) {
                    $script:cacheUserBase.Clear()
                    $script:cacheUserByID.Clear()
                }
                if (-not $script:cacheUserBase) {
                    $res= _Invoke-SymantecCLI -cmd "searchUser"

                    foreach ($elm in $res.'cr.result'.User) {
                        $obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|password\b|failedLoginAttempts\b|lastLogin\b|gkUserId\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        #$obj= _Convert-XmlToPS -XML $elm -filter '(?!hash\b|extensionType|password|failedLoginAttempts|lastLogin|gkUserId|create.+|update.+)'
                                                    
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "User" -Force
                        $obj.ID= [int]($obj.ID)
                        
                        $obj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $obj.UserID -Force

                        $obj | Add-Member -MemberType NoteProperty -Name 'userGroup' -Value "" -Force

                        $ugList= ""
                        foreach($grpId in $($obj.userGroupIDs.trim("[]").split(","))) {
                            if ($ugList) {$ugList+= " | "}
                            $ugList+= (Get-SymUserGroup -ID $grpId).name
                        }
                        $obj.userGroup= $ugList

                        $idx= $script:cacheUserBase.Add( $obj )
                        $script:cacheUserByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				$idx= $Script:cacheUserByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheUserBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheUserBase

                if ($UserGroupID -ge 0) {$res= $res | Where-Object {$_.UserID -eq $UserID}}

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($FirstName) {$res= $res | Where-Object {$_.FirstName -match $FirstName}}
					if ($LastName) {$res= $res | Where-Object {$_.LastName -match $LastName}}
					if ($AuthenticationType) {$res= $res | Where-Object {$_.AuthenticationType -match $AuthenticationType}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($FirstName) {$res= $res | Where-Object {$_.FirstName -like $FirstName}}
					if ($LastName) {$res= $res | Where-Object {$_.LastName -like $LastName}}
					if ($AuthenticationType) {$res= $res | Where-Object {$_.AuthenticationType -like $AuthenticationType}}
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