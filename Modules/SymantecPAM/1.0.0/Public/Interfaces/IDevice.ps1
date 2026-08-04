class IDevice {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$Name

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
