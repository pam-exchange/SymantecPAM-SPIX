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

$script:cacheTargetAliasBase= New-Object System.Collections.ArrayList
$script:cacheTargetAliasByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-SymTargetAlias () 
{
    Param(
		[Alias("AliasID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		[Alias("AliasName")]
        [Parameter(Mandatory=$false)][string] $Name,
        [Parameter(Mandatory=$false)][string] $UserName,
        
        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymTargetAlias" -Operation {   
                if ($Refresh) {
                    $script:cacheTargetAliasBase.Clear()
                    $script:cacheTargetAliasByID.Clear()
                }
                if (-not $script:cacheTargetAliasBase) {
                    $res= _Invoke-SymantecCLI -cmd "searchTargetAlias"

                    foreach ($elm in $res.'cr.result'.TargetAlias) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|type\b|extensionType\b|create\w*|update\w*|last\w*)\w+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|last.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "TargetAlias"
                        $obj.ID= [int]($obj.ID)

                        $obj.PSObject.Properties.Remove('account')

                        $idx= $script:cacheTargetAliasBase.Add( $obj )
                        $script:cacheTargetAliasByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheTargetAliasByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheTargetAliasBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheTargetAliasBase

                if ($TargetApplicationID -ge 0) {$res= $res | Where-Object {$_.TargetApplicationID -eq $TargetApplicationID}}				
				if ($useRegex) {
					if ($userName) {$res= $res | Where-Object {$_.userName -match $userName}}
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
				}
				else {
					if ($userName) {$res= $res | Where-Object {$_.userName -like $userName}}
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
				}
			}

			#
			# Check boundary conditions
			#
            if ($null -eq $res) {$cnt= 0}
            elseif ($res.GetType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $res.count}

            if ($NoEmptySet -and $cnt -eq 0) {
                $details= $DETAILS_EXCEPTION_NOT_FOUND_02 -f $($MyInvocation.MyCommand.Name),$userName
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