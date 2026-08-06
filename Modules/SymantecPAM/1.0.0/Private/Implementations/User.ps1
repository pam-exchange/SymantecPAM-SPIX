class User : IUser {
    User() {
        $this.ObjectType = "User"
    }
    User([object]$obj) {
        $this.ObjectType = "User"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymUser @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for User"
    }

    [object] New([object]$params) {
        throw "New is not supported for User"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','Description')
        $ignoreColums = @('serverKeyId','userGroupIDs','userID')
        Export-SymGeneric -ObjectType User -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
