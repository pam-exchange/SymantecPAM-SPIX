class CustomWorkflow : ICustomWorkflow {
    CustomWorkflow() {
        $this.ObjectType = "CustomWorkflow"
    }
    CustomWorkflow([object]$obj) {
        $this.ObjectType = "CustomWorkflow"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.applicationType = [string]$obj.applicationType
        $this.Description = [string]$obj.Description
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymCustomWorkflow @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for CustomWorkflow"
    }

    [object] New([object]$params) {
        throw "New is not supported for CustomWorkflow"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','name','applicationType','Description')
        $ignoreColums = @()
        Export-SymCustomWorkflow -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
