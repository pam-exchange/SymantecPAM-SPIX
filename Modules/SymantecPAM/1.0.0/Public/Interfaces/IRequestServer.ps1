class IRequestServer {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$deviceName
    [string]$hostname
    [string]$ipAddress
    [string]$Attribute_descriptor1
    [string]$Attribute_descriptor2

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
