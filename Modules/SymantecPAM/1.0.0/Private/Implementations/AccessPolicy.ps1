class AccessPolicy : IAccessPolicy {
    AccessPolicy() {
        $this.ObjectType = "AccessPolicy"
    }
    AccessPolicy([object]$obj) {
        $this.ObjectType = "AccessPolicy"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.User = [string]$obj.User
        $this.Device = [string]$obj.Device
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymAccessPolicy @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for AccessPolicy"
    }

    [object] New([object]$params) {
        throw "New is not supported for AccessPolicy"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','User','Device')
        $ignoreColums = @()
        Export-SymAccessPolicy -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
