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

$script:cacheAuthorizationBase= New-Object System.Collections.ArrayList
$script:cacheAuthorizationByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymAuthorization () 
{
    Param(
		[Alias("AuthorizationID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,

        [AllowEmptyString()]
        [AllowNull()]
        [string] $TargetGroup,

        [AllowEmptyString()]
        [AllowNull()]
        [string] $TargetAlias,

        [AllowEmptyString()]
        [AllowNull()]
        [string] $RequestGroup,

        [AllowEmptyString()]
        [AllowNull()]
        [string] $RequestServer,

        [AllowEmptyString()]
        [AllowNull()]
        [string] $RequestScript,


		[int[]] $RequestServerID= -1,
		[int[]] $RequestScriptID= -1,
		[int[]] $TargetAliasID= -1,
		[int[]] $TargetGroupID= -1,
		[int[]] $RequestGroupID= -1,

        [string] $ExecutionUser,
        [switch] $CheckExecutionUser= $false,
		[switch] $CheckExecutionPath= $false,
		[switch] $CheckFilePath= $false,
		[switch] $CheckScriptHash= $false,

        [switch] $useRegex= $false,
        [switch] $Single= $false,
		[switch] $Refresh= $false,
        [switch] $NoEmptySet= $false
    )
    
	process {
		try {
            _ProtectedOperation -ResourceName "SymAuthorization" -Operation {   
                if ($Refresh) {
                    $script:cacheAuthorizationBase.Clear()
                    $script:cacheAuthorizationByID.Clear()
                }
                if (-not $script:cacheAuthorizationBase) {
                    #
                    # Fetch the lot from PAM
                    #
                    $res= _Invoke-SymantecCLI -cmd "searchAuthorization"

                    foreach ($elm in $res.'cr.result'.Authorization) {
                        $obj= _Convert-XmlToPS -XML $elm -filter '^(?!hash|extensionType|update.+|create.+)'
                        $obj | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Authorization"
                        $obj.ID= [int]($obj.ID)

                        <#
						foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match "^(TRUE|FALSE)$"}) {
                            $p.Value= $p.value -eq "TRUE"
                        }
						#>

                        $idx= $script:cacheAuthorizationBase.Add( $obj )
                        $script:cacheAuthorizationByID.Add( [int]($obj.ID), [int]($idx) )
                    }
                }
            }

            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheAuthorizationByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheAuthorizationBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheAuthorizationBase

                if ($TargetGroup) {$TargetGroupID= (Get-SymGroup -Name $TargetGroup -GroupType TARGET -NoEmptySet).ID}
                if ($RequestGroup) {$RequestGroupID= (Get-SymGroup -Name $RequestGroup -GroupType REQUESTOR -NoEmptySet).ID}
                if ($TargetAlias) {$TargetAliasID= (Get-SymTargetAlias -Name $TargetAlias -NoEmptySet).ID}
                if ($RequestScript) {$RequestScriptID= (Get-SymRequestScript -Name $RequestScript -NoEmptySet).ID}
                if ($RequestServer) {$RequestServerID= (Get-SymRequestServer -Name $RequestServer -NoEmptySet).ID}

				if ($CheckExecutionUser) {$res= $res | Where-Object {$_.CheckExecutionUser -eq "true"}}
				if ($CheckExecutionPath) {$res= $res | Where-Object {$_.CheckExecutionPath -eq "true"}}
				if ($CheckFilePath) {$res= $res | Where-Object {$_.CheckFilePath -eq "true"}}
				if ($CheckScriptHash) {$res= $res | Where-Object {$_.CheckScriptHash -eq "true"}}

				if ($RequestServerID -ge 0) {$res= $res | Where-Object {$_.RequestServerID -in $RequestServerID}}
				if ($RequestScriptID -ge 0) {$res= $res | Where-Object {$_.RequestScriptID -in $RequestScriptID}}
				if ($TargetAliasID -ge 0) {$res= $res | Where-Object {$_.TargetAliasID -in $TargetAliasID}}
				if ($TargetGroupID -ge 0) {$res= $res | Where-Object {$_.TargetGroupID -in $TargetGroupID}}
				if ($RequestGroupID -ge 0) {$res= $res | Where-Object {$_.RequestGroupID -in $RequestGroupID}}

				if ($useRegex) {
					if ($ExecutionUser) {$res= $res | Where-Object {$_.ExecutionUser -match $ExecutionUser}}
				}
				else {
					if ($ExecutionUser) {$res= $res | Where-Object {$_.ExecutionUser -like $ExecutionUser}}
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