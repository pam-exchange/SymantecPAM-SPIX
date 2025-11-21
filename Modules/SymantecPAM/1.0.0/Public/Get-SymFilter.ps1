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

$script:cacheFilterBase= New-Object System.Collections.ArrayList
$script:cacheFilterByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-SymFilter () 
{
    Param(
		[Alias("FilterID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
        [Parameter(Mandatory=$false)][string] $Name,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymFilter" -Operation {   
                if ($Refresh) {
                    $script:cacheFilterBase.Clear()
                    $script:cacheFilterByID.Clear()
                }
                if (-not $script:cacheFilterBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "searchFilter"

                    foreach ($elm in $res.'cr.result'.Filter) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|extensionType\b|create\w*|update\w*)[\w\.]+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Filter"
                        $obj.ID= [int]($obj.ID)

                        $idx= $script:cacheFilterBase.Add( $obj )
                        $script:cacheFilterByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing filtering by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheFilterByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheFilterBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheFilterBase

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
                }
			}

			#
			# Check boundary conditions
			#
            if ($null -eq $res) {$cnt= 0}
            elseif ($res.GetType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $res.count}

            if ($NoEmptySet -and $cnt -eq 0) {
				$details= $DETAILS_EXCEPTION_NOT_FOUND_01 -f $($MyInvocation.MyCommand.Name)
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