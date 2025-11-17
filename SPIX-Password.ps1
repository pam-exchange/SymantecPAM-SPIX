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


# ----------------------------------------------------------------------------------
param (
    [Parameter(Mandatory=$true,ParameterSetName='Encrypt')][String] $Password,
    [Parameter(Mandatory=$true,ParameterSetName='Decrypt')][String] $EncryptedPassword,

    [AllowEmptyString()]
    [AllowNull()]
    [string] $Key
)

# ----------------------------------------------------------------------------------
begin {
    try {$startTime= (Get-Date -ErrorAction SilentlyContinue)} catch {$startTime= 0}

    $scriptBasePath= $PSScriptRoot
    #$scriptName= $PSCommandPath

    # modulePath
    if (-not $modulePath) { 
        #$modulePath= $scriptBasePath.substring(0,$scriptBasePath.LastIndexOf('\')) 
        $modulePath= $scriptBasePath
    }

    $Global:currentPSModulePath= $env:PSModulePath
    if ($env:PSModulePath -notmatch ";"+$($modulePath.replace("\","\\"))+"\\modules") {
        $env:PSModulePath+=";$modulePath\modules"
    }

    if ($(Get-Module).name -contains 'SymantecPAM') { Remove-Module SymantecPAM }

    Import-Module SymantecPAM -Force
}


# ----------------------------------------------------------------------------------
process {

    try {
        #
        # Prompt for passphrase when "-ShowPassword -key ''" is used
        #
        if (!$key -or $PSBoundParameters.ContainsKey('Key')) {
            # Key parameter WAS passed
            if ([string]::IsNullOrWhiteSpace($Key)) {
                $key= ([Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                        (Read-Host "Enter encryption passphrase" -AsSecureString)
                    )
                ))
                $key2= ([Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                        (Read-Host "Confirm encryption passphrase" -AsSecureString)
                    )
                ))
                if ($key -cne $key2) {
                    Write-Host "Encryption passphrase does not match." -ForegroundColor Yellow
                    return
                }
            }
        }

        if ($password) {
            $EncryptedPassword= Protect-SymPassword -Password $Password -Key $key
            Write-Host $EncryptedPassword
        }
        else {
            $Password= Unprotect-SymPassword -EncryptedPassword $EncryptedPassword -Key $Key
            Write-Host $password
        }

    } 
    catch {
        Write-Host "Exception: $($_.Exception.GetType().FullName)`nMessage: $($_.Exception.Message)`nDetails: $($_.Exception.Details)" -ForegroundColor Yellow
        Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    }
}

# ----------------------------------------------------------------------------------
end {
}

# -- end-of-file ---
