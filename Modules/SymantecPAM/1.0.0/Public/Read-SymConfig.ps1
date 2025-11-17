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
function Read-SymConfig {
    param (
        [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
    )
    #
    # Fetch credentials for KeePassXC and PAM
    #
    $runHostname= $([System.Net.DNS]::GetHostByName('').hostname).ToLower()

    $whoami= [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $idx= $whoami.IndexOf("\")
    if ($idx -ge 0) { $whoami= $whoami.substring($whoami.IndexOf("\")+1) }

    if (Test-Path -Path $ConfigPath -PathType Container) {
        $ConfigPath+= "\SPIX-XXXX.properties"
    }

    $finalConfig= New-Object System.Collections.Hashtable

    $configFile= $ConfigPath.replace("XXXX", "$($runHostname)_$($whoami)")
    if (Test-Path -Path $configFile) {
        $configJson= Get-Content -path $configFile

        $config= $configJson | ConvertFrom-Json

        $config | %{
            if ($_.type -eq "SymantecPAM") {
                #
                # PAM API credentials and configuration
                #
                if ($($_.cliPassword)) {
                    $securePwd = $($_.cliPassword) | ConvertTo-SecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
                    $cliPassword= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }
                if ($($_.apiPassword)) {
                    $securePwd = $($_.apiPassword) | ConvertTo-SecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
                    $apiPassword= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }

                $finalConfig.Add("SymantecPAM", [PSCustomObject]@{  DNS= $_.DNS;
                                                                    cliPageSize= $_.cliPageSize;
                                                                    cliUsername= $_.cliUsername; 
                                                                    cliPassword=$cliPassword;
                                                                    cliAlias=$cliAlias;
                                                                    apiUsername= $_.apiUsername;
                                                                    apiPassword=$apiPassword;
                                                                    apiAlias=$apiAlias;
																	tcf= $_.tcf;
                                                                    Delimiter= $_.Delimiter;
                                                                } )
            }
        }
    }

    return $finalConfig
}

# --- end-of-file ---