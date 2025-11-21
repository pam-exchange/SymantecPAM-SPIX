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

$script:cacheVaultSecretBase= New-Object System.Collections.ArrayList
$script:cacheVaultSecretByID= New-Object System.Collections.HashTable		# Index into cache array

enum SECRETTYPE {
    ALL
    GENERIC                        # 1
    TOKEN                          # 2
    DATABASE_CONNECTION            # 3
    KUBERNETES_CONFIGURATION       # 4
    SSL_CERTIFICATE                # 5
    KEYS                           # 6
    ENDPOINTS                      # 7
    SAFE                           # 8
    S3_CONFIGURATION               # 9
}

#--------------------------------------------------------------------------------------
function Get-SymVaultSecret () 
{
    Param(
		[Alias("SecretID")]
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
            _ProtectedOperation -ResourceName "SymVaultSecret" -Operation {   
                if ($Refresh) {
                    $script:cacheVaultSecretBase.Clear()
                    $script:cacheVaultSecretByID.Clear()
                }
                if (-not $script:cacheSecretBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "listSecrets"

                    foreach ($elm in $res.'cr.result'.secret) {
                        #$obj= _Convert-XmlToPS -XML $elm -filter "\b(?!hash\b|type\b|create\w*|update\w*|last\w*)\w+\b"
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+|last.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "VaultSecret"
                        $obj.ID= [int]($obj.ID)

                        $obj.value= ""
                        if ($obj.autoExpire -eq "FALSE") {$obj.autoExpire= ""}
                        if ($obj.autoDelete -eq "FALSE") {$obj.autoDelete= ""}

                        $idx= $script:cacheVaultSecretBase.Add( $obj )
                        $script:cacheVaultSecretByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            #
            # To-Do: Needs a complete rework allowing Grouping by AccountName, etc...
            #

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheVaultSecretByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheVaultSecretBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheVaultSecretBase

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($Description) {
                        $res= $res | Where-Object {$_.firstDescription -match $Description}
                        $res= $res | Where-Object {$_.secondDescription -match $Description}
                    }
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($Description) {
                        $res= $res | Where-Object {$_.firstDescription -like $Description}
                        $res= $res | Where-Object {$_.secondDescription -like $Description}
                    }
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