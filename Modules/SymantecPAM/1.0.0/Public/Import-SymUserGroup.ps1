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


function Import-SymUserGroup (
    [PSCustomObject[]] $InputCsv,
    [switch] $Quiet= $false
)
{
	process {
        $failedImport= New-Object System.Collections.ArrayList
        foreach ($row in $InputCsv) {
            try {
                if ($row.Action -notmatch "^(Update|New)$") {
                    continue
                }

                $params= $row | Select-Object * -ExcludeProperty ObjectType

                if ($params.role) {
                    $params | Add-Member -NotePropertyName 'roleID' -NotePropertyValue (Get-SymRole -Name $params.role -Single -NoEmptySet).ID -Force
                }

                $groupsStr= ""
                if ($params.targetGroup) {
                    $groupsStr+= (Get-SymGroup -Name $params.targetGroup -Single -NoEmptySet).ID
                }
                if ($params.requestorGroup) {
                    if ($groupsStr) {$groupsStr+=","}
                    $groupsStr+= (Get-SymGroup -Name $params.requestorGroup -Single -NoEmptySet).ID
                }
                $params | Add-Member -NotePropertyName 'groups' -NotePropertyValue $groupsStr -Force

                $res= Sync-SymUserGroup -params $params
            }
            catch {
                $row | Add-Member -NotePropertyName ErrorMessage -NotePropertyValue "$($_.Exception.Message) -- $($_.Exception.Details)" -Force
                $failedImport.add( $row ) | Out-Null
            }
        }
        return $failedImport
     }
}

# --- end-of-file ---