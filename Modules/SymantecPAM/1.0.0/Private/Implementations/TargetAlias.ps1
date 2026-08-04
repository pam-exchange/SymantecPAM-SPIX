class TargetAlias : ITargetAlias {
    TargetAlias() {
        $this.ObjectType = "TargetAlias"
    }
    TargetAlias([object]$obj) {
        $this.ObjectType = "TargetAlias"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.userName = [string]$obj.userName
        if ($obj.PSObject.Properties['TargetApplicationID']) { $this.targetApplicationID = [int]$obj.TargetApplicationID }
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymTargetAlias @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for TargetAlias"
    }

    [object] New([object]$params) {
        throw "New is not supported for TargetAlias"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','Name','userName','TargetApplicationID')
        $ignoreColums = @()
        Export-SymGeneric -ObjectType TargetAlias -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
