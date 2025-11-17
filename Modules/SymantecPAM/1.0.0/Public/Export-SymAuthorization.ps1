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

function Export-SymAuthorization (
    [Parameter(Mandatory=$false)][AllowEmptyString()][PSCustomObject[]] $List= $null,
    [Parameter(Mandatory=$false)][string] $Timestamp,
    [Parameter(Mandatory=$false)][string[]] $fixedColumns,
    [Parameter(Mandatory=$false)][string[]] $ignoreColums,
    [Parameter(Mandatory=$false)][string] $OutputPath= ".\SPIX-output",
    [Parameter(Mandatory=$false)][string] $Delimiter= ","
)
{
	process {

        if (!$List) {
            return
        }

        if (!$Timestamp) {$timestamp= (Get-Date).ToString("yyyyMMdd-HHmmss")}
        $outFilename= "$OutputPath\Authorization-$Timestamp.csv"
        
        $filteredList= $list | Sort-Object -Property ID
        if ($null -eq $filteredList -or $filteredList.Length -eq 0) {
            return
        }

        #
        # Map internal IDs to names
        #
        foreach ($obj in $filteredList) {
            $obj | Add-Member -MemberType NoteProperty -Name 'targetGroup' -Value '' -Force
            $obj | Add-Member -MemberType NoteProperty -Name 'requestGroup' -Value '' -Force

            if ($obj.TargetGroupID -ne -1)   { $obj.targetGroup= (Get-SymGroup -ID $obj.TargetGroupID).Name }
            if ($obj.requestGroupID -ne -1)  { $obj.requestGroup= (Get-SymGroup -ID $obj.requestGroupID).Name }
            if ($obj.requestServerID -ne -1) { $obj.RequestServer= (Get-SymRequestServer -ID $obj.requestServerID).Hostname }
            if ($obj.targetAliasID -ne -1)   { $obj.targetAlias= (Get-SymTargetAlias -ID $obj.targetAliasID).name }
            if ($obj.scriptID -ne -1)        { $obj.script= (Get-SymRequestScript -ID $obj.scriptID).Name }
        }

        #>
        #$allColumns = $filteredList[0].PSObject.Properties.Name | Where-Object {$ignoreColums -notcontains $_}
        $allColumns= $filteredList | ForEach-Object { $_.PSObject.Properties.Name } | Where-Object {$ignoreColums -notcontains $_} | Sort-Object -Unique
        $AttributeColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -like 'Attribute.*'} | Sort-Object
        $otherColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -notlike 'Attribute.*'} | Sort-Object
        $columnOrder = $fixedColumns + $otherColumns + $AttributeColumns

        $filteredList | Select-Object $columnOrder | Export-Csv -Path $outFilename -NoTypeInformation -Delimiter $Delimiter
    }
}

# --- end-of-file ---