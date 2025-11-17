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

function Get-SymTargetAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $AccountID,
        [Parameter(Mandatory=$false)][string] $Reason= "SPIX",
        [Parameter(Mandatory=$false)][switch] $Unattended= $false
    )
    
	process {

		try {

            #if ($AccountID -eq "342001") {
            #    write-host "break"
            #}

            #
            # Change PVP if checkout, email notifictions, etc.
            #
            if ($Unattended) {
                $acc= Get-SymTargetAccount -ID $AccountID
                $pvpOrg= Get-SymPVP -ID $acc.passwordViewPolicyID

                if ($pvpOrg.changePasswordOnView -eq 'true' -or 
                    $pvpOrg.reasonRequiredView -eq 'true' -or 
                    $pvpOrg.retrospectiveApprovalRequired -eq 'true' -or 
                    $pvpOrg.emailNotificationRequired -eq 'true' -or 
                    $pvpOrg.exclusiveCheckoutRequired -eq 'true' -or
                    $pvpOrg.authenticationRequiredView -eq 'true')
                {
                    try {
                        $pvpNew= Get-SymPVP -Name "SPIX-PVP" -Single -NoEmptySet
                    }
                    catch {
                        $params= @{
                            action= 'New'
                            name= 'SPIX-PVP'
                            description= 'PVP used by SPIX'
                        }
                        $pvpNew= Sync-SymPVP -params $params
                    }

                    $update= $acc
                    $update.passwordViewPolicyID= $pvpNew.id
                    $update.password= $null
                    $upd= Update-SymTargetAccount -params $update
                }
                else {
                    $pvpNew= $null
                }
            }

            #
            # Fetch password
            #
            $params = @{
                'TargetAccount.ID' = $AccountID
                reason = "Other"
                reasonDetails = $Reason
                referenceCode= $Reason
                }
            #Write-Host "Account ID= $AccountID"
            $res= _Invoke-SymantecCLI -Cmd "viewAccountPassword" -Params $params
            $passwd= $res.'cr.result'.TargetAccount.password

            #
            # Restore PVP
            #
            if ($Unattended) {
                if ($pvpNew) {
                    $update= $acc
                    $update.password= $null
                    $update.passwordViewPolicyID= $pvpOrg.id
                    <#@{
                        ID= $acc.ID
                        userName= $acc.userName
                        passwordViedwPolicyID= $pvpOrg.id
                    }
                    #>
                    $upd= Update-SymTargetAccount -params $update
                }
            }

            return $passwd
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---