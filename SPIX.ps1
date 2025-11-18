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
    [Parameter(ParameterSetName='Help')][switch] $Help= $false,

    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Import')]
    [string] $ConfigPath= ".\",

    [Parameter(Mandatory=$true,ParameterSetName='Export')][switch] $Export= $false,
    [Parameter(ParameterSetName='Export')][string] $OutputPath= '.\SPIX-output',
    [Parameter(ParameterSetName='Export')][string] $Category= 'ALL',
    [Parameter(ParameterSetName='Export')][switch] $ShowPassword= $false,
    [Parameter(ParameterSetName='Export')][string] $SrvName= '',
    [Parameter(ParameterSetName='Export')][string] $AppName= '',
    [Parameter(ParameterSetName='Export')][string] $AccName= '',
    [Parameter(ParameterSetName='Export')][string] $ExtensionType= '',

    [Parameter(Mandatory=$true,ParameterSetName='Import')][switch] $Import= $false,
    [Parameter(Mandatory=$true,ParameterSetName='Import')][string] $InputFile,
    [Parameter(ParameterSetName='Import')][switch] $Synchronize= $false,
    [Parameter(ParameterSetName='Import')][switch] $UpdatePassword= $false,

    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Import')]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $Passphrase,

    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Import')]
    [string] 
    $Delimiter= ';',

    [Parameter(ParameterSetName='Export')]
    [Parameter(ParameterSetName='Import')]
    [switch] $Quiet= $false
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
        Start-SymantecPAM -ConfigPath $ConfigPath

        $Timestamp= $startTime.ToString('yyyyMMdd-HHmmss')

        #
        # Prompt for passphrase when "-ShowPassword -Passphrase ''" is used
        #
        if ($ShowPassword -and $PSBoundParameters.ContainsKey('Passphrase')) {
            # Key parameter WAS passed
            if ([string]::IsNullOrWhiteSpace($Passphrase)) {
                $Passphrase= ([Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                        (Read-Host "Enter encryption passphrase" -AsSecureString)
                    )
                ))
                $Passphrase2= ([Runtime.InteropServices.Marshal]::PtrToStringBSTR(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                        (Read-Host "Confirm encryption passphrase" -AsSecureString)
                    )
                ))
                if ($Passphrase -cne $Passphrase2) {
                    Write-Host "Encryption passphrase does not match." -ForegroundColor Yellow
                    return
                }
            }
        }

        if ($Export) {
            Export-Sym -Timestamp $Timestamp -OutputPath $OutputPath -Category $Category -SrvName $HostName -AppName $AppName -AccName $AccName -ExtensionType $ExtensionType -showPassword:$ShowPassword -Passphrase $Passphrase -Quiet:$Quiet
        }
        elseif ($Import) {
            $res= Import-Sym -InputFile $InputFile -Delimiter $Delimiter -Timestamp $Timestamp -Synchronize:$Synchronize -UpdatePassword:$UpdatePassword -Passphrase $Passphrase
        }
        else {
            Write-Host 'some help' -ForegroundColor Green
        }

    } 
    catch {
        Write-Host "Exception: $($_.Exception.GetType().FullName)`nMessage: $($_.Exception.Message)`nDetails: $($_.Exception.Details)" -ForegroundColor Yellow
        Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    }
    finally {
        Stop-SymantecPAM
    }

}


# ----------------------------------------------------------------------------------
end {
    try {
        # --- Elapsed time ---
        $t= $([int]((Get-Date -ErrorAction SilentlyContinue)-$startTime).TotalSeconds)

        $h= [int][Math]::Floor( $t / 3600 )
        $m= [int][Math]::Floor( ($t - $h*3600) / 60 )
        $s= [int][Math]::Floor( $t - $h*3600 -$m*60 )

        if ($h -gt 0)     {Write-Host "Run time: $h hours, $m minutes, $s seconds" -ForegroundColor Gray}
        elseif ($m -gt 0) {Write-Host "Run time: $m minutes, $s seconds" -ForegroundColor Gray}
        else              {Write-Host "Run time: $s seconds" -ForegroundColor Gray}
    } catch {}

    Write-Host 'Done' -ForegroundColor White
}

# -- end-of-file ---
