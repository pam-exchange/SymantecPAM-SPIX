class PVP : IPVP {
    PVP() {
        $this.ObjectType = "PVP"
    }
    PVP([object]$obj) {
        $this.ObjectType = "PVP"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymPVP @params
    }

    [object] Set([object]$params) {
        return Sync-SymPVP -params $params
    }

    [object] New([object]$params) {
        return Sync-SymPVP -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','Description')
        $ignoreColums = @('approverIDs','emailNotificationUserIDs')
        Export-SymPVP -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
