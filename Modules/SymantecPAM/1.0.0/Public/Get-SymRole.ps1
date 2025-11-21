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

$script:cacheRoleBase= New-Object System.Collections.ArrayList
$script:cacheRoleByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymRole () 
{
    Param(
		[Alias("RoleID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $Description,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymRole" -Operation {   
                if ($Refresh) {
                    $script:cacheRoleBase.Clear()
                    $script:cacheRoleByID.Clear()
                }
                if (-not $script:cacheRoleBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "searchRole"

                    foreach ($elm in $res.'cr.result'.Role) {
                        #$obj= _Convert-XmlToPS -XML $elm -Filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Role"
                        $obj.ID= [int]($obj.ID)

                        $obj.permissions= $obj.permissions.trim("[]")

                        $idx= $script:cacheRoleBase.Add( $obj )
                        $script:cacheRoleByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing Grouping by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheRoleByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheRoleBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheRoleBase

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -match $Description}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
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