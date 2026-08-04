class Filter : IFilter {
    Filter() {
        $this.ObjectType = "Filter"
    }
    Filter([object]$obj) {
        $this.ObjectType = "Filter"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymFilter @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for Filter"
    }

    [object] New([object]$params) {
        throw "New is not supported for Filter"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action')
        $ignoreColums = @('groupID')
        Export-SymFilter -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
