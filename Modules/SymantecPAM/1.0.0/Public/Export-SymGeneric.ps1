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

function Export-SymGeneric (
    #[Parameter(Mandatory=$true)][OBJECTTYPE] $Objecttype,
    [Parameter(Mandatory=$true)][String] $Objecttype,
    [Parameter(Mandatory=$false)][String] $Extension,
    [Parameter(Mandatory=$false)][AllowEmptyString()][PSCustomObject[]] $List= $null,
    [Parameter(Mandatory=$false)][string] $Timestamp,
    [Parameter(Mandatory=$false)][string[]] $fixedColumns,
    [Parameter(Mandatory=$false)][string[]] $ignoreColums,
    [Parameter(Mandatory=$false)][string] $OutputPath= ".\SPIX-Output",
    [Parameter(Mandatory=$false)][string] $Delimiter= ","
)
{
	process {
        if (!$List) {
            return
        }
        
        #Start-Sleep -Seconds 15

        if (!$Timestamp) {$timestamp= (Get-Date).ToString("yyyyMMdd-HHmmss")}
        $outFilename= "$OutputPath\$ObjectType"
        if ($extension) {$outFilename+= "-$Extension"}
        $outFilename+= "-$Timestamp.csv"
        
        $filteredList= $list | Sort-Object -Property ID

        foreach ($obj in $filteredList) {
            foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match '^(t|f)$'}) {
                if ($p.Value -eq "t") {$p.Value= 'true'}
                else {$p.value= 'false'}
            }
        }

        #$allColumns = $filteredList[0].PSObject.Properties.Name | Where-Object {$ignoreColums -notcontains $_}
        $allColumns= $filteredList | ForEach-Object { $_.PSObject.Properties.Name } | Where-Object {$ignoreColums -notcontains $_} | Sort-Object -Unique
        $AttributeColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -like 'Attribute.*'} | Sort-Object
        $otherColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -notlike 'Attribute.*'} | Sort-Object
        $columnOrder = $fixedColumns + $otherColumns + $AttributeColumns

        $filteredList | Select-Object $columnOrder | Export-Csv -Path $outFilename -NoTypeInformation -Delimiter $Delimiter
    }
}

# --- end-of-file ---