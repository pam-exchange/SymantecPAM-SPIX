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
    [Parameter(ParameterSetName='Export')][string[]] $Category= 'ALL',
    [Parameter(ParameterSetName='Export')][switch] $ShowPassword= $false,
    [Parameter(ParameterSetName='Export')][string] $SrvName= '',
    [Parameter(ParameterSetName='Export')][string] $AppName= '',
    [Parameter(ParameterSetName='Export')][string] $AccName= '',
    [Parameter(ParameterSetName='Export')][string] $ExtensionType= '',
    [Parameter(ParameterSetName='Export')][switch] $Compress= $false,

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
            Export-Sym -Timestamp $Timestamp -OutputPath $OutputPath -Category $Category -SrvName $SrvName -AppName $AppName -AccName $AccName -ExtensionType $ExtensionType -Compress:$Compress -showPassword:$ShowPassword -Passphrase $Passphrase -Quiet:$Quiet
        }
        elseif ($Import) {
            $res= Import-Sym -InputFile $InputFile -Delimiter $Delimiter -Timestamp $Timestamp -Synchronize:$Synchronize -UpdatePassword:$UpdatePassword -Passphrase $Passphrase
        }
        else {
Write-Host @"
SPIX - Symantec PAM Import/Export Tool
======================================

SPIX is a PowerShell-based utility for exporting and importing
Credential Management data from Symantec PAM. It extends functionality
originally provided by the legacy xsie tool and supports new PAM
features, API/CLI updates, and modern extension types.

SPIX uses both CLI and API calls. All operations are limited to the
permissions assigned to the authenticated CLI/API users.

Usage:
  SPIX.ps1 [-Help]
  SPIX.ps1 -Export   [options]
  SPIX.ps1 -Import   [options]

Commands:
  -Help                     Show this help text
  -Export                   Export objects from Symantec PAM
  -Import                   Import objects from CSV

General Options:
  -ConfigPath <path>        Path to SPIX properties file.
                            Default: .\
  -Delimiter <char>         CSV delimiter override.
  -Quiet                    Reduce console output.

----------------------------------------------------------------------
Export Options
----------------------------------------------------------------------

SPIX.ps1 -Export [options]

  -OutputPath <path>        Directory where exported CSV files are saved.
                            Default: .\SPIX-output

  -Category <name>          One or more categories to export:
                            ALL
                            Target               (TargetServer, TargetApplication, TargetAccount)
                            A2A                 (RequestServer, RequestScript, Authorization)
                            Proxy
                            Policy              (PCP, PVP, SSHKeyPairPolicy, JIT, CustomWorkflow)
                            UserGroup           (Filter, Group, Role, User, UserGroup)
                            Secret              (Vault, VaultSecret)
                            AccessPolicy
                            Service
                            Device

  -SrvName <filter>         Filter by server name. Supports '*'.
  -AppName <filter>         Filter by application name. Supports '*'.
  -AccName <filter>         Filter by account name. Supports '*'.
  -ExtensionType <filter>   Filter by extension type. Supports '*'.

  -ShowPassword             Retrieve and export passwords in clear text.
                            Requires temporary assignment of SPIX-PVP
                            if PVP requires checkout/approval/notifications.

  -Passphrase <passphrase>  With -ShowPassword, encrypt passwords using
                            a passphrase-derived key. Empty ('') prompts.

  -Compress                 Combine application and account data into a
                            single simplified file (no extension details).

Extension Types:
  Built-in extension types include: activeDirectorySshKey, AS400, AwsAccessCredentials,
  AwsApiProxyCredentials, AzureAccessCredentials, CiscoSSH, Generic, genericSecretType,
  HPServiceManager, juniper, ldap, mssql, oracle, PaloAlto, nsxcontroller, nsxmanager,
  nsxproxy, remedy, SPML2, unixII, vmware, windows, windowsDomainService, windowsSshKey,
  windowsSshPassword, weblogic10, sybase, vcf, ServiceDeskBroker, ServiceNow, RadiusTacacsSecret,
  and more.

  Custom connector names from the 'tcf' property are also supported (case sensitive).

----------------------------------------------------------------------
Import Options
----------------------------------------------------------------------

SPIX.ps1 -Import [options]

  -InputFile <file>         CSV file to import.
  -Passphrase <passphrase>  Decrypt encrypted passwords beginning with {enc}.
                            Empty ('') prompts for input.
  -UpdatePassword           For TargetAccounts, after creation replaces known
                            endpoint password with PAM-generated password.

Import Notes:
  * "password" = _generate_pass_ → PAM generates a password using the PCP.
  * Valid Action values in CSV: New, Update, Remove, Empty.
  * Import supported for:
      Authorization, PCP, Proxy, PVP, RequestScript, RequestServer,
      Role, SSHKeyPairPolicy, TargetAccount, TargetApplication,
      TargetServer, UserGroup.
  * Proxies cannot be created by CLI/API; they register when launched.
  * Failed rows are written to a separate error CSV with ErrorMessage column.
"@
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
