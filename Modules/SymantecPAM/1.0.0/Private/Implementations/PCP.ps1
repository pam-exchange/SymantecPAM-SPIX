class PCP : IPCP {
    PCP() {
        $this.ObjectType = "PCP"
    }
    PCP([object]$obj) {
        $this.ObjectType = "PCP"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Type = [string]$obj.Type
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymPCP @params
    }

    [object] Set([object]$params) {
        return Sync-SymPCP -params $params
    }

    [object] New([object]$params) {
        return Sync-SymPCP -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','type','Description')
        $ignoreColums = @()
        Export-SymGeneric -ObjectType PCP -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
