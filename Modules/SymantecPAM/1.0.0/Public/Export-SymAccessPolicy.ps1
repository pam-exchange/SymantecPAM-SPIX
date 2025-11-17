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

function Export-SymAccessPolicy (
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
        $outFilename= "$OutputPath\AccessPolicy-$Timestamp.csv"
        
        $filteredList= $list | Sort-Object -Property ID

        foreach ($obj in $filteredList) {
            $obj.user= $obj.user.name
            $obj.device= $obj.device.name

            $str= ""
            foreach ($elm in $obj.accessMethods) {
                if ($str) {$str+= " | "}
                $str+= $elm.type+"["
                $str2= ""
                foreach ($elm2 in $elm.accountIds) {
                    $acc= Get-SymTargetAccount -ID $elm2.accountId -Single -NoEmptySet
                    if ($str2) {$str2+= " | "}
                    $str2+= "dev="+$acc.DeviceName+", app="+$acc.TargetApplicationName+", acc="+$acc.userName
                }
                $str+= $str2+"]"
            }
            $obj.accessMethods= $str

            $str= ""
            foreach ($elm in $obj.services) {
                if ($str) {$str+= " | "}
                $str+= $elm.name+"["
                $str2= ""
                foreach ($elm2 in $elm.accountIds) {
                    $acc= Get-SymTargetAccount -ID $elm2.accountId -Single -NoEmptySet
                    if ($str2) {$str2+= " | "}
                    $str2+= "dev="+$acc.DeviceName+", app="+$acc.TargetApplicationName+", acc="+$acc.userName
                }
                $str+= $str2+"]"
            }
            $obj.services= $str

            $str= ""
            foreach ($tAcc in $obj.vpnServices) {
            }
            $obj.vpnServices= $str

            $str= ""
            foreach ($elm in $obj.targetAccounts) {
                $acc= Get-SymTargetAccount -ID $elm.accountId -Single -NoEmptySet
                if ($str) {$str+= " | "}
                $str+= "dev="+$acc.DeviceName+", app="+$acc.TargetApplicationName+", acc="+$acc.userName
            }
            $obj.targetAccounts= $str

            foreach ($p in $obj.PSObject.Properties | Where-Object {$_.Value -match '^(t|f)$'}) {
                if ($p.Value -eq "t") {$p.Value= 'true'}
                else {$p.value= 'false'}
            }
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