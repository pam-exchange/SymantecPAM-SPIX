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
}
