class Proxy : IProxy {
    Proxy() {
        $this.ObjectType = "Proxy"
    }
    Proxy([object]$obj) {
        $this.ObjectType = "Proxy"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.deviceName = [string]$obj.deviceName
        $this.hostname = [string]$obj.hostname
        $this.ipAddress = [string]$obj.ipAddress
    }
}
