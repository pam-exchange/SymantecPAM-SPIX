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
function Export-SymTargetAccount (
    [Parameter(Mandatory=$false)][AllowEmptyString()][PSCustomObject[]] $List= $null,
    [Parameter(Mandatory=$false)][string] $Timestamp,
    [Parameter(Mandatory=$false)][string[]] $fixedColumns,
    [Parameter(Mandatory=$false)][string[]] $ignoreColums,
    [Parameter(Mandatory=$false)][string] $OutputPath= ".\SPIX-output",

    [switch] $ShowPassword= $false,
    [AllowEmptyString()][string] $Key= "",

    [Parameter(Mandatory=$false)][string] $Delimiter= ",",

    [Parameter(Mandatory=$false)][switch] $Quiet= $false
)
{
	process {

        if (!$List) {return}

        if (!$Timestamp) {$timestamp= (Get-Date).ToString("yyyyMMdd-HHmmss")}

        $extension= ($List | Select-Object -property extensionType -Unique).extensionType | Sort-Object
        foreach ($ext in $extension) {

            $csv= $List | Where-Object {$_.extensionType -eq $ext} | Sort-Object -Property ID
            if ($ext -eq "") {$ext= "Generic"}

            if ($null -eq $csv) {
                continue
            }

            if (!$Quiet) {Write-Host "... $ext" -ForegroundColor Gray}

            # resolve compoundServers
            #foreach ($obj in $($script:cacheTargetAccountBase | Where-Object {$_.compoundServerIDs})) {
            #foreach ($obj in $($List | Where-Object {$_.compoundServerIDs})) {
            foreach ($obj in $($csv | Where-Object {$_.compoundServerIDs})) {
                if ($obj.compoundServerIDs) {
                    $csList= ""
                    foreach ($tsid in $($obj.compoundServerIDs.trim(",").split(","))) {
                        if ($csList) {$csList+= " | "}
                        $csList+= (Get-SymTargetAccount -ID $tsid).hostname
                    }
                    $obj.compoundServerList= $csList
                }
            }

            #
            # Find password
            #
            if ($showPassword) {
                #foreach ($obj in $List) {
                foreach ($obj in $csv) {
                    $obj.Password= Get-SymTargetAccountPassword -AccountID $obj.ID -Unattended
                    if ($Key) {
                        $enc= _Encrypt-PBKDF2 -PlainText $obj.Password -Password $Key
                        $obj.Password= "{enc}"+$enc
                    }
                }
            }

            #
            # Replace 'otherAccount' IDs with reference to targetServer,targetApplication and username
            # Different extensionType uses different names for attribute
            #
            #foreach ($obj in $List) {
            foreach ($obj in $csv) {
                foreach ($property in $($obj.PSObject.Properties | Where-Object {$_.Name -in @('Attribute.otherAccount', 'Attribute.loginAccount', 'Attribute.otherPrivilegedAccount','Attribute.anotherAccount') -and $_.value})) {
                    if ($property.Value -eq -1) {$property.Value= ""} 
                    else {
                        $oth= Get-SymTargetAccount -ID $property.Value
                        $othStr= $oth.Hostname+" | "+$oth.TargetApplicationName+" | "+$oth.username
                        $property.Value= $othStr
                    }
                }
            }

            $outFilename= "$OutputPath\TargetAccount-$ext-$Timestamp.csv"

            $allColumns = $csv[0].PSObject.Properties.Name | Where-Object {$ignoreColums -notcontains $_}

            $AttributeColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -like 'Attribute.*'} | Sort-Object
            $otherColumns= $allColumns | Where-Object { $fixedColumns -notcontains $_ -and $_ -notlike 'Attribute.*'} | Sort-Object
            $columnOrder = $fixedColumns + $otherColumns + $AttributeColumns

            $csv | Select-Object $columnOrder | Export-Csv -Path $outFilename -NoTypeInformation -Delimiter $Delimiter
        }
    }
}

# --- end-of-file ---