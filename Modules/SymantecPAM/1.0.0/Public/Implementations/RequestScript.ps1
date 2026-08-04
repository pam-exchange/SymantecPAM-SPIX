class RequestScript : IRequestScript {
    RequestScript() {
        $this.ObjectType = "RequestScript"
    }
    RequestScript([object]$obj) {
        $this.ObjectType = "RequestScript"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.RequestServer = [string]$obj.RequestServer
        $this.Type = [string]$obj.Type
    }
}
