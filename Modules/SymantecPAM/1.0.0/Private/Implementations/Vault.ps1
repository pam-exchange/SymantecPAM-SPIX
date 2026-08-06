class Vault : IVault {
    Vault() {
        $this.ObjectType = "Vault"
    }
    Vault([object]$obj) {
        $this.ObjectType = "Vault"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymVault @params
    }

    [object] Set([object]$params) {
        return Sync-SymVault -params $params
    }

    [object] New([object]$params) {
        return Sync-SymVault -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','description')
        $ignoreColums = @()
        Export-SymGeneric -ObjectType Vault -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
