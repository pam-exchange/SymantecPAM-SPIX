class RequestScript : IRequestScript {
    RequestScript() {
        $this.ObjectType = "RequestScript"
    }
    RequestScript([object]$obj) {
        $this.ObjectType = "RequestScript"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.RequestServer = [string]$obj.RequestServer
        $this.Type = [string]$obj.Type
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymRequestScript @params
    }

    [object] Set([object]$params) {
        return Sync-SymRequestScript -params $params
    }

    [object] New([object]$params) {
        return Sync-SymRequestScript -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','RequestServer','type')
        $ignoreColums = @('deviceID','RequestServerID')
        Export-SymGeneric -ObjectType RequestScript -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
