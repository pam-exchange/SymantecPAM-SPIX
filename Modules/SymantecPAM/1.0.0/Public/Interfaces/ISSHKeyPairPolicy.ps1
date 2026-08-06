class ISSHKeyPairPolicy {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$Name
    [string]$Description
    [string]$Attribute_keyType
    [string]$Attribute_keyLength

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
