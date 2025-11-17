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

function Update-SymTargetAccount () 
{
    Param(
		[Alias("AccountID","TargetAccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		[Alias("AccountName","TargetAccountName")]
        [Parameter(Mandatory=$false)][string] $userName,
        [Parameter(Mandatory=$false)][String] $TargetApplicationName,
        [Parameter(Mandatory=$false)][int] $TargetApplicationID= -1,
        [Parameter(Mandatory=$false)][String] $TargetServerName,
        [Parameter(Mandatory=$false)][int] $TargetServerID= -1,

        [Parameter(Mandatory=$true)][PSCustomObject] $params,

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            $cliParams= @{}

            if ($Params.ID) { $cliParams+= @{'TargetAccount.ID'= $Params.ID } }
            if ($Params.userName) { $cliParams+= @{'TargetAccount.userName'= $Params.userName} }
            if ($Params.passwordViewPolicyID) { $cliParams+= @{'PasswordViewPolicy.ID'= $Params.passwordViewPolicyID} }
            
            foreach ($p in $params.PSObject.Properties | Where-Object {$_.Name -like 'Attribute*'}) {
                $cliParams+= @{ $p.Name= $p.Value }
            }
            #Write-Host "ID= $($params.ID) - Name=$($params.userName)"
            $res= _Invoke-SymantecCLI -cmd "updateTargetAccount" -params $cliParams

            return $res
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---