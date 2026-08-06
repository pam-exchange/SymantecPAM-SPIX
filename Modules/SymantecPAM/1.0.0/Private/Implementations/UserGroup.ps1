class UserGroup : IUserGroup {
    UserGroup() {
        $this.ObjectType = "UserGroup"
    }
    UserGroup([object]$obj) {
        $this.ObjectType = "UserGroup"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
        $this.targetGroup = [string]$obj.targetGroup
        $this.requestorGroup = [string]$obj.requestorGroup
        $this.Role = [string]$obj.Role
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymUserGroup @params
    }

    [object] Set([object]$params) {
        return Sync-SymUserGroup -params $params
    }

    [object] New([object]$params) {
        return Sync-SymUserGroup -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','description','targetGroup','requestorGroup','role')
        $ignoreColums = @('groups','readOnly','groupIDs','roleID')
        Export-SymUserGroup -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
