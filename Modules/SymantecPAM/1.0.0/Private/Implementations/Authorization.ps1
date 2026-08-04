class Authorization : IAuthorization {
    Authorization() {
        $this.ObjectType = "Authorization"
    }
    Authorization([object]$obj) {
        $this.ObjectType = "Authorization"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Target = [string]$obj.Target
        $this.Request = [string]$obj.Request
        $this.Script = [string]$obj.Script
        $this.checkExecutionID = [string]$obj.checkExecutionID
        $this.executionUser = [string]$obj.executionUser
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymAuthorization @params
    }

    [object] Set([object]$params) {
        return Sync-SymAuthorization -params $params
    }

    [object] New([object]$params) {
        return Sync-SymAuthorization -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','Target','Request','Script','checkExecutionID','executionUser')
        $ignoreColums = @('targetAlias','requestGroupID','requestServerID','scriptID','targetAliasID','targetGroupID','requestServer')
        Export-SymAuthorization -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
