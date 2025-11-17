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

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

#region Load Private Functions
Try {
    if (Test-Path "$ScriptPath\Private") {
        $PrivateFunctions = @(Get-ChildItem -Path "$ScriptPath\Private" -Filter *.ps1 -ErrorAction SilentlyContinue)
        foreach ($import in $PrivateFunctions) {
            try {
                . $import.FullName
            } catch {
                Write-Warning "Failed to import function $($import.FullName): $_"
            }
        }
    }
} Catch {
    Write-Warning "Failed to import private function: $_"
    Continue
}
#endregion Load Private Functions

#region Load Public Functions
Try {
    $NoExport= @()
    $PublicFunctions = @(Get-ChildItem -Path "$ScriptPath\public" -Filter *.ps1 -ErrorAction SilentlyContinue)
    $ToExport = $PublicFunctions | Where-Object { $_.BaseName -notin $NoExport } | Select-Object -ExpandProperty BaseName

    foreach ($import in $PublicFunctions) {
        try {
            . $import.FullName
        } catch {
            Write-Warning "Failed to import function $($import.FullName): $_"
        }
    }
    Export-ModuleMember -Function $ToExport
}
catch {
    Write-Warning "Failed to import public function: $_"
}
#endregion Load Public Functions
