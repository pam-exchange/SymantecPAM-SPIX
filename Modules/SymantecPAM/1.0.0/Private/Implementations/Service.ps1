class Service : IService {
    Service() {
        $this.ObjectType = "Service"
    }
    Service([object]$obj) {
        $this.ObjectType = "Service"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.ServiceType = [string]$obj.ServiceType
        $this.localIP = [string]$obj.localIP
        $this.ports = [string]$obj.ports
        $this.comments = [string]$obj.comments
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymService @params
    }

    [object] Set([object]$params) {
        throw "Set is not supported for Service"
    }

    [object] New([object]$params) {
        throw "New is not supported for Service"
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','Name','ServiceType','localIP','ports','comments')
        $ignoreColums = @()
        Export-SymGeneric -ObjectType Service -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
