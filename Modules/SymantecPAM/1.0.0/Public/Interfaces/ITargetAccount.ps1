class ITargetAccount {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$ExtensionType
    [string]$deviceName
    [string]$hostname
    [string]$targetApplicationName
    [string]$userName
    [string]$password

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
