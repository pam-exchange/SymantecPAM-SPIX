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

# Get PowerShell version
$global:psVersion = $PSVersionTable.PSVersion.Major

if ($global:psVersion -lt "7") {
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

#--------------------------------------------------------------------------------------
function Start-SymantecPAM (
    [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
)
{
    $config= Read-SymConfig -ConfigPath $ConfigPath

    $DNS= $config[ "SymantecPAM" ].DNS;

    $script:cliURL     = "https://$($DNS)/cspm/servlet/adminCLI"
    $script:cliPageSize= 100000
    $script:cliUsername= $config[ "SymantecPAM" ].cliUsername
    $script:cliPassword= $config[ "SymantecPAM" ].cliPassword
    $script:cliAlias   = $config[ "SymantecPAM" ].cliAlias;
    $script:apiURL     = "https://$($DNS)"
    $script:apiUsername= $config[ "SymantecPAM" ].apiUsername
    $script:apiPassword= $config[ "SymantecPAM" ].apiPassword
    $script:apiAlias   = $config[ "SymantecPAM" ].apiAlias
	$Script:tcf        = $config[ "SymantecPAM" ].tcf
    $script:Delimiter  = $config[ "SymantecPAM" ].Delimiter

    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($($apiUsername+":"+$apiPassword)))
    $script:apiHeaders= @{ 'Authorization' = "Basic $encodedCredentials" }
    $encodedCredentials= ""
}

# --- end-of-file ---