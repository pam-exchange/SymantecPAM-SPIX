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

#--------------------------------------------------------------------------------------
# Resource Model Classes
#--------------------------------------------------------------------------------------

class AccessPolicy {
    [int]$ID
    [string]$ObjectType = "AccessPolicy"
    [string]$Action
    [string]$User
    [string]$Device

    AccessPolicy() {}
    AccessPolicy([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.User = [string]$obj.User
        $this.Device = [string]$obj.Device
    }
}

class Authorization {
    [int]$ID
    [string]$ObjectType = "Authorization"
    [string]$Action
    [string]$Target
    [string]$Request
    [string]$Script
    [string]$checkExecutionID
    [string]$executionUser

    Authorization() {}
    Authorization([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Target = [string]$obj.Target
        $this.Request = [string]$obj.Request
        $this.Script = [string]$obj.Script
        $this.checkExecutionID = [string]$obj.checkExecutionID
        $this.executionUser = [string]$obj.executionUser
    }
}

class CustomWorkflow {
    [int]$ID
    [string]$ObjectType = "CustomWorkflow"
    [string]$Action
    [string]$Name
    [string]$applicationType
    [string]$Description

    CustomWorkflow() {}
    CustomWorkflow([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.applicationType = [string]$obj.applicationType
        $this.Description = [string]$obj.Description
    }
}

class Device {
    [int]$ID
    [string]$ObjectType = "Device"
    [string]$Action
    [string]$Name

    Device() {}
    Device([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
    }
}

class Filter {
    [int]$ID
    [string]$ObjectType = "Filter"
    [string]$Action

    Filter() {}
    Filter([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
    }
}

class Group {
    [int]$ID
    [string]$ObjectType = "Group"
    [string]$Action
    [string]$Name
    [string]$Description

    Group() {}
    Group([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}

class PCP {
    [int]$ID
    [string]$ObjectType = "PCP"
    [string]$Action
    [string]$Name
    [string]$Type
    [string]$Description

    PCP() {}
    PCP([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Type = [string]$obj.Type
        $this.Description = [string]$obj.Description
    }
}

class PVP {
    [int]$ID
    [string]$ObjectType = "PVP"
    [string]$Action
    [string]$Name
    [string]$Description

    PVP() {}
    PVP([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}

class Proxy {
    [int]$ID
    [string]$ObjectType = "Proxy"
    [string]$Action
    [string]$deviceName
    [string]$hostname
    [string]$ipAddress

    Proxy() {}
    Proxy([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
    }
}

class RequestScript {
    [int]$ID
    [string]$ObjectType = "RequestScript"
    [string]$Action
    [string]$Name
    [string]$RequestServer
    [string]$Type

    RequestScript() {}
    RequestScript([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.RequestServer = [string]$obj.RequestServer
        $this.Type = [string]$obj.Type
    }
}

class RequestServer {
    [int]$ID
    [string]$ObjectType = "RequestServer"
    [string]$Action
    [string]$deviceName
    [string]$hostname
    [string]$ipAddress
    [string]$Attribute_descriptor1
    [string]$Attribute_descriptor2

    RequestServer() {}
    RequestServer([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
        if ($obj.PSObject.Properties['Attribute.descriptor1']) { $this.Attribute_descriptor1 = [string]$obj.'Attribute.descriptor1' }
        if ($obj.PSObject.Properties['Attribute.descriptor2']) { $this.Attribute_descriptor2 = [string]$obj.'Attribute.descriptor2' }
    }
}

class Role {
    [int]$ID
    [string]$ObjectType = "Role"
    [string]$Action
    [string]$Name
    [string]$Description

    Role() {}
    Role([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}

class Service {
    [int]$ID
    [string]$ObjectType = "Service"
    [string]$Action
    [string]$Name
    [string]$ServiceType
    [string]$localIP
    [string]$ports
    [string]$comments

    Service() {}
    Service([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.ServiceType = [string]$obj.ServiceType
        $this.localIP = [string]$obj.localIP
        $this.ports = [string]$obj.ports
        $this.comments = [string]$obj.comments
    }
}

class SSHKeyPairPolicy {
    [int]$ID
    [string]$ObjectType = "SSHKeyPairPolicy"
    [string]$Action
    [string]$Name
    [string]$Description
    [string]$Attribute_keyType
    [string]$Attribute_keyLength

    SSHKeyPairPolicy() {}
    SSHKeyPairPolicy([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
        if ($obj.PSObject.Properties['Attribute.keyType']) { $this.Attribute_keyType = [string]$obj.'Attribute.keyType' }
        if ($obj.PSObject.Properties['Attribute.keyLength']) { $this.Attribute_keyLength = [string]$obj.'Attribute.keyLength' }
    }
}

class TargetAccount {
    [int]$ID
    [string]$ObjectType = "TargetAccount"
    [string]$Action
    [string]$ExtensionType
    [string]$deviceName
    [string]$hostname
    [string]$targetApplicationName
    [string]$userName
    [string]$password

    TargetAccount() {}
    TargetAccount([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.ExtensionType = [string]$obj.ExtensionType
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.targetApplicationName = [string]$obj.targetApplicationName
        $this.userName = [string]$obj.userName
        $this.password = [string]$obj.password
    }
}

class TargetAlias {
    [int]$ID
    [string]$ObjectType = "TargetAlias"
    [string]$Action
    [string]$Name
    [string]$userName
    [int]$targetApplicationID

    TargetAlias() {}
    TargetAlias([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.userName = [string]$obj.userName
        if ($obj.PSObject.Properties['TargetApplicationID']) { $this.targetApplicationID = [int]$obj.TargetApplicationID }
    }
}

class TargetApplication {
    [int]$ID
    [string]$ObjectType = "TargetApplication"
    [string]$Action
    [string]$ExtensionType
    [string]$deviceName
    [string]$hostname
    [string]$Name
    [string]$PCP
    [string]$Attribute_descriptor1
    [string]$Attribute_descriptor2

    TargetApplication() {}
    TargetApplication([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.ExtensionType = [string]$obj.ExtensionType
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.Name = [string]$obj.Name
        $this.PCP = [string]$obj.PCP
        if ($obj.PSObject.Properties['Attribute.descriptor1']) { $this.Attribute_descriptor1 = [string]$obj.'Attribute.descriptor1' }
        if ($obj.PSObject.Properties['Attribute.descriptor2']) { $this.Attribute_descriptor2 = [string]$obj.'Attribute.descriptor2' }
    }
}

class TargetServer {
    [int]$ID
    [string]$ObjectType = "TargetServer"
    [string]$Action
    [string]$deviceName
    [string]$hostname
    [string]$ipAddress
    [string]$Attribute_descriptor1
    [string]$Attribute_descriptor2

    TargetServer() {}
    TargetServer([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
        if ($obj.PSObject.Properties['Attribute.descriptor1']) { $this.Attribute_descriptor1 = [string]$obj.'Attribute.descriptor1' }
        if ($obj.PSObject.Properties['Attribute.descriptor2']) { $this.Attribute_descriptor2 = [string]$obj.'Attribute.descriptor2' }
    }
}

class User {
    [int]$ID
    [string]$ObjectType = "User"
    [string]$Action
    [string]$Name
    [string]$Description

    User() {}
    User([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}

class UserGroup {
    [int]$ID
    [string]$ObjectType = "UserGroup"
    [string]$Action
    [string]$Name
    [string]$Description
    [string]$targetGroup
    [string]$requestorGroup
    [string]$Role

    UserGroup() {}
    UserGroup([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
        $this.targetGroup = [string]$obj.targetGroup
        $this.requestorGroup = [string]$obj.requestorGroup
        $this.Role = [string]$obj.Role
    }
}

class Vault {
    [int]$ID
    [string]$ObjectType = "Vault"
    [string]$Action
    [string]$Name
    [string]$Description

    Vault() {}
    Vault([object]$obj) {
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}
