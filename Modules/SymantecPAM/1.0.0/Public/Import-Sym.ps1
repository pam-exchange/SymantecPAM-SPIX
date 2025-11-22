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

function Import-Sym (
    [string] $InputFile,
    [string] $Delimiter,
    [string] $Timestamp,
    [switch] $Synchronize= $false,
    [switch] $UpdatePassword= $false,
    [string] $Passphrase,
    [switch] $Quiet= $false
)
{
	process {
        if (!$InputFile) {
            throw ( New-Object SymantecPamException( $EXCEPTION_INVALID_PARAMETER, $DETAILS_EXCEPTION_CANNOT_IMPORT_02 ) )
        }
        if (!$Timestamp) {$Timestamp= $(Get-Date).ToString('yyyyMMdd-hhmmss')}
        if (!$Delimiter) {
            if ($Script:Delimiter) {$Delimiter= $Script:Delimiter}
            else {$Delimiter= ','}
        }
        
        $dir  = Split-Path $InputFile
        $name = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
        $ext  = [System.IO.Path]::GetExtension($InputFile)
        $FailedInputFile = Join-Path $dir "$name`_Error-$timestamp$ext"

        $InputCsv= Import-Csv -Path $InputFile -Delimiter $Delimiter | Where-Object { $_.ObjectType -ne '' }
        $objectType= ($InputCsv | Select-Object -property objectType -Unique | Sort-Object).objectType

        foreach ($type in $objectType) {
            switch ($type) {
                'Authorization'     { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'Filter'            { }
                'Group'             { }
                'PCP'               { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'Proxy'             { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'PVP'               { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'RequestScript'     { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'RequestServer'     { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'Role'              { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'SSHKeyPairPolicy'  { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'TargetAccount'     { $failed= Import-SymTargetAccount -InputCsv $InputCsv -UpdatePassword:$UpdatePassword -Passphrase $Passphrase; break }
                'TargetApplication' { $failed= Import-SymTargetApplication -InputCsv $InputCsv; break }
                'TargetServer'      { $failed= Import-SymGeneric -InputCsv $InputCsv; break }
                'UserGroup'         { $failed= Import-SymUserGroup -InputCsv $InputCsv; break }
                'Vault'             { }
                'VaultSecret'       { }
            }
            if ($failed) {
                Write-Host "Import with errors. See the file '$FailedInputFile' for details." -ForegroundColor Yellow
                $failed | Export-Csv -Path $FailedInputFile -Delimiter $Delimiter -Append -NoTypeInformation
            }
        }
    }
}

# --- end-of-file ---