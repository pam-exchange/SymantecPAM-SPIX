class RequestServer : IRequestServer {
    RequestServer() {
        $this.ObjectType = "RequestServer"
    }
    RequestServer([object]$obj) {
        $this.ObjectType = "RequestServer"
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
        return Get-SymRequestServer @params
    }

    [object] Set([object]$params) {
        return Sync-SymRequestServer -params $params
    }

    [object] New([object]$params) {
        return Sync-SymRequestServer -params $params
    }

    [void] Export([hashtable]$params) {
        $list = $this.Get($null)
        $fixedColumns = @('ID','ObjectType','Action','deviceName','hostname','ipAddress','Attribute.descriptor1','Attribute.descriptor2')
        $ignoreColums = @('deviceId','serverKeyId','SiteID')
        Export-SymGeneric -ObjectType RequestServer -List $list -fixedColumns $fixedColumns -ignoreColums $ignoreColums -Timestamp $params.Timestamp -Delimiter $params.Delimiter -OutputPath $params.OutputPath
    }
}
