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


# OneOfEachExtension= $list | Group-Object ExtensionType | ForEach-Object { $_.Group[0] }
# $allPossibleAttributes= $OneOfEachExtension | ForEach-Object {$_.PSObject.Properties.Name} | Sort-Object -unique

#--------------------------------------------------------------------------------------
function Export-SymTargetApplication (
    [Parameter(Mandatory=$false)][AllowEmptyString()][PSCustomObject[]] $List= $null,
    [Parameter(Mandatory=$false)][string] $Timestamp,
    [Parameter(Mandatory=$false)][string[]] $fixedColumns= $TargetApplication_fixedColumns,
    [Parameter(Mandatory=$false)][string[]] $ignoreColums= $TargetApplication_ignoreColums,
    [Parameter(Mandatory=$false)][string] $OutputPath= ".\SPIX-output",
    [Parameter(Mandatory=$false)][string] $Delimiter= ",",

    [Parameter(Mandatory=$false)][switch] $Quiet= $false
)
{
	process {
        if (!$List) {
            return
        }

        if (!$Timestamp) {$timestamp= (Get-Date).ToString("yyyyMMdd-HHmmss")}

        $extension= ($List | Select-Object -property extensionType -Unique).extensionType | Sort-Object
        foreach ($ext in $extension) {

            $csv= $List | Where-Object {$_.extensionType -eq $ext} | Sort-Object -Property ID
            if ($ext -eq "") {$ext= "Generic"}

            if (!$Quiet) {Write-Host "... $ext" -ForegroundColor Gray}

            foreach ($obj in $csv) {
                $obj | Add-Member -NotePropertyName 'PCP' -NotePropertyValue (Get-SymPCP -ID $obj.policyID).Name -Force

                switch ($ext) {
                    'windows' {
                        $proxyList= ""
                        foreach ($pid in $($obj.'Attribute.agentId'.split(",").trim())) {
                            if ($proxyList) {$proxyList+= " | "}
                            $proxyList+= (Get-SymTargetServer -ID $pid -Single -NoEmptySet).hostname
                        }
                        $obj | Add-Member -NotePropertyName 'Attribute.Proxy' -NotePropertyValue $proxyList -Force
                        break
                    }
                    {'activeDirectorySshKey','unixII','windowsSshKey' -eq $_} {
                        $obj | Add-Member -NotePropertyName 'Attribute.sshKeyPairPolicy' -NotePropertyValue "" -Force
                        if ($obj.'Attribute.sshKeyPairPolicyID') {
                            $obj.'Attribute.sshKeyPairPolicy'= (Get-SymSSHKeyPairPolicy -ID $obj.'Attribute.sshKeyPairPolicyID' -Single -NoEmptySet).Name
                        }
                        break
                    }
                    {'mssql','mssqlAzureMI' -eq $_} {
                        $obj | Add-Member -NotePropertyName 'Attribute.customWorkflow' -NotePropertyValue "" -Force
                        if ($obj.'Attribute.customWorkflowId') {
                            $obj.'Attribute.customWorkflow'= (Get-SymCustomWorkflow -ID $obj.'Attribute.customWorkflowId' -Single -NoEmptySet).Name
                        }
                        break
                    }
                }
            }

            $outFilename= "$OutputPath\TargetApplication-$ext-$Timestamp.csv"

            $allColumns = $csv[0].PSObject.Properties.Name | Where-Object {$ignoreColums -notcontains $_}
            $AttributeColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -like 'Attribute.*'} | Sort-Object
            $otherColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -notlike 'Attribute.*'} | Sort-Object
            $columnOrder = $fixedColumns + $otherColumns + $AttributeColumns

            $csv | Select-Object $columnOrder | Export-Csv -Path $outFilename -NoTypeInformation -Delimiter $Delimiter
        }
    }
}

# --- end-of-file ---