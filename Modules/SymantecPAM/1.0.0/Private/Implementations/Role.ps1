class Role : IRole {
    Role() {
        $this.ObjectType = "Role"
    }
    Role([object]$obj) {
        $this.ObjectType = "Role"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymRole @params
    }

    [object] Set([object]$params) {
        return Sync-SymRole -params $params
    }

    [object] New([object]$params) {
        return Sync-SymRole -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','Description')
        $ignoreColums = @('Readonly')
        Export-SymGeneric -ObjectType Role -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
