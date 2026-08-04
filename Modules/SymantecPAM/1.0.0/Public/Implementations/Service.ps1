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
}
