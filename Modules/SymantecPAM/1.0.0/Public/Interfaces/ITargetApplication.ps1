class ITargetApplication {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$ExtensionType
    [string]$deviceName
    [string]$hostname
    [string]$Name
    [string]$PCP
    [string]$Attribute_descriptor1
    [string]$Attribute_descriptor2

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
