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
}
