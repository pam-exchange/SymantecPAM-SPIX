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

class SymantecPAMCrypto {
    static [string] Protect([string]$Password, [string]$Passphrase) {
        return Protect-SymPassword -Password $Password -Passphrase $Passphrase
    }

    static [string] Unprotect([string]$EncryptedPassword, [string]$Passphrase) {
        return Unprotect-SymPassword -EncryptedPassword $EncryptedPassword -Passphrase $Passphrase
    }
}

#--------------------------------------------------------------------------------------

class SymantecPAMConfig {
    [string]$DNS
    [object]$cliPageSize
    [string]$cliUsername
    [string]$cliPassword
    [string]$apiUsername
    [string]$apiPassword
    [object]$tcf
    [object]$limit
    [string]$Delimiter

    SymantecPAMConfig() {}

    static [SymantecPAMConfig] Read([string]$configPath) {
        $rawConfig = Read-SymConfig -ConfigPath $configPath
        if ($null -eq $rawConfig -or !$rawConfig.ContainsKey("SymantecPAM")) {
            throw "Configuration for SymantecPAM not found in path: $configPath"
        }
        $configObj = $rawConfig["SymantecPAM"]

        $config = [SymantecPAMConfig]::new()
        $config.DNS = $configObj.DNS
        $config.cliPageSize = $configObj.cliPageSize
        $config.cliUsername = $configObj.cliUsername
        $config.cliPassword = $configObj.cliPassword
        $config.apiUsername = $configObj.apiUsername
        $config.apiPassword = $configObj.apiPassword
        $config.tcf = $configObj.tcf
        $config.limit = $configObj.limit
        $config.Delimiter = $configObj.Delimiter
        return $config
    }
}

#--------------------------------------------------------------------------------------

class SymantecPAM {
    [string]$ConfigPath
    [SymantecPAMConfig]$Config
    [string]$cliURL
    [object]$cliPageSize
    [string]$cliUsername
    [string]$cliPassword
    [string]$apiURL
    [string]$apiUsername
    [string]$apiPassword
    [object]$tcf
    [string]$Delimiter
    [hashtable]$apiHeaders

    # Constructors
    SymantecPAM() {
        $this.ConfigPath = "c:\temp"
        $this.Start()
    }

    SymantecPAM([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.Start()
    }

    # Methods
    [void] Start() {
        # Fetch the configuration using our helper config class
        $this.Config = [SymantecPAMConfig]::Read($this.ConfigPath)

        $this.cliURL      = "https://$($this.Config.DNS)/cspm/servlet/adminCLI"
        $this.cliPageSize = $this.Config.limit
        $this.cliUsername = $this.Config.cliUsername
        $this.cliPassword = $this.Config.cliPassword
        $this.apiURL      = "https://$($this.Config.DNS)"
        $this.apiUsername = $this.Config.apiUsername
        $this.apiPassword = $this.Config.apiPassword
        $this.tcf         = $this.Config.tcf
        $this.Delimiter   = $this.Config.Delimiter

        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($($this.apiUsername + ":" + $this.apiPassword)))
        $this.apiHeaders = @{ 'Authorization' = "Basic $encodedCredentials" }

        # For backwards compatibility with internal functions using $script: variables, we also set the module script scope variables:
        $script:cliURL      = $this.cliURL
        $script:cliPageSize = $this.cliPageSize
        $script:cliUsername = $this.cliUsername
        $script:cliPassword = $this.cliPassword
        $script:apiURL      = $this.apiURL
        $script:apiUsername = $this.apiUsername
        $script:apiPassword = $this.apiPassword
        $script:tcf         = $this.tcf
        $script:Delimiter   = $this.Delimiter
        $script:apiHeaders  = $this.apiHeaders
    }

    [void] Stop() {
        $this.cliURL      = $null
        $this.cliPageSize = $null
        $this.cliUsername = $null
        $this.cliPassword = $null
        $this.apiURL      = $null
        $this.apiUsername = $null
        $this.apiPassword = $null
        $this.tcf         = $null
        $this.Delimiter   = $null
        $this.apiHeaders  = $null

        $script:cliURL      = $null
        $script:cliPageSize = $null
        $script:cliUsername = $null
        $script:cliPassword = $null
        $script:apiURL      = $null
        $script:apiUsername = $null
        $script:apiPassword = $null
        $script:tcf         = $null
        $script:Delimiter   = $null
        $script:apiHeaders  = $null
    }

    [void] Export([hashtable]$params) {
        # Check if the properties file custom Delimiter should override
        if (-not $params.ContainsKey('Delimiter') -or [string]::IsNullOrWhiteSpace($params['Delimiter'])) {
            $params['Delimiter'] = $this.Delimiter
        }
        Export-Sym @params
    }

    [object] Import([hashtable]$params) {
        # Check if the properties file custom Delimiter should override
        if (-not $params.ContainsKey('Delimiter') -or [string]::IsNullOrWhiteSpace($params['Delimiter'])) {
            $params['Delimiter'] = $this.Delimiter
        }
        return Import-Sym @params
    }
}
