class Group : IGroup {
    Group() {
        $this.ObjectType = "Group"
    }
    Group([object]$obj) {
        $this.ObjectType = "Group"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymGroup @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for Group"
    }

    [object] New([object]$params) {
        throw "New is not supported for Group"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','Description')
        $ignoreColums = @('readOnly')
        Export-SymGeneric -ObjectType Group -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
