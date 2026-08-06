class TargetServer : ITargetServer {
    TargetServer() {
        $this.ObjectType = "TargetServer"
    }
    TargetServer([object]$obj) {
        $this.ObjectType = "TargetServer"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
        if ($obj.PSObject.Properties['Attribute.descriptor1']) { $this.Attribute_descriptor1 = [string]$obj.'Attribute.descriptor1' }
        if ($obj.PSObject.Properties['Attribute.descriptor2']) { $this.Attribute_descriptor2 = [string]$obj.'Attribute.descriptor2' }
    }

    [object[]] Get([hashtable]$params) {
        if ($null -eq $params) { $params = @{} }
        return Get-SymTargetServer @params
    }

    [object] Set([object]$params) {
        return New-SymTargetServer -params $params
    }

    [object] New([object]$params) {
        return New-SymTargetServer -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($params)
        $fixedColumns = @('ID','ObjectType','Action','deviceName','hostname','ipAddress','Attribute.descriptor1','Attribute.descriptor2')
        $ignoreColums = @('deviceId')
        Export-SymGeneric -ObjectType TargetServer -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
