class ITargetAlias {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$Name
    [string]$userName
    [int]$targetApplicationID

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
