class IAuthorization {
    [int]$ID
    [string]$ObjectType
    [string]$Action
    [string]$Target
    [string]$Request
    [string]$Script
    [string]$checkExecutionID
    [string]$executionUser

    [object[]] Get([hashtable]$params) { return $null }
    [object] Set([object]$params) { return $null }
    [object] New([object]$params) { return $null }
    [void] Export([hashtable]$params) {}
}
