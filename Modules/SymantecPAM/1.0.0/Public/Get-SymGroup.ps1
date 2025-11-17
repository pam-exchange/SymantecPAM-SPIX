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

$script:cacheGroupBase= New-Object System.Collections.ArrayList
$script:cacheGroupByID= New-Object System.Collections.HashTable		# Index into cache array

enum GROUPTYPE {
    ALL
    TARGET
    REQUESTOR
}

enum DYNAMICTYPE {
    ALL
    DYNAMIC
    STATIC
}

#--------------------------------------------------------------------------------------
function Get-SymGroup () 
{
    Param(
		[Alias("GroupID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $Description,
        [Parameter(Mandatory=$false)][GROUPTYPE] $GroupType= "ALL",
        [Parameter(Mandatory=$false)][DYNAMICTYPE] $DynamicType= "ALL",
        [Parameter(Mandatory=$false)][switch] $isSecret= $false,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymGroup" -Operation {   
                if ($Refresh) {
                    $script:cacheGroupBase.Clear()
                    $script:cacheGroupByID.Clear()
                }
                if (-not $script:cacheGroupBase) {

                    $filters= Get-SymFilter

                    $params= @{
                        'Group.isSecretType'= 'false'
                    }
                    $res= _Invoke-SymantecCLI -cmd "searchGroup" -params $params
                    
                    foreach ($elm in $res.'cr.result'.Group) {
                        #$obj= _Convert-XmlToPS -XML $elm -Filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Group"
                        $obj.ID= [int]($obj.ID)

                        $obj.filters= ($filters | Where-Object {$_.GroupID -eq $obj.ID}).ID -join ","
                        $obj.permissions= $obj.permissions.trim("[]")

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
                            $p.Value= $p.value -eq "TRUE"
                        }
						#>

                        $idx= $script:cacheGroupBase.Add( $obj )
                        $script:cacheGroupByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing Grouping by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheGroupByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheGroupBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheGroupBase

                if ($GroupType -ne "ALL") {$res= $res | Where-Object {$_.type -eq $GroupType}}
                if ($isSecret) {$res= $res | Where-Object {$_.secretType -eq 'true'}}

                if ($DynamicType -ne "ALL") {
                    if ($DynamicType -eq "DYNAMIC") 
                        {$res= $res | Where-Object {$_.dynamic -eq "TRUE"}}
                    else 
                        {$res= $res | Where-Object {$_.dynamic -eq "FALSE"}}
                }

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