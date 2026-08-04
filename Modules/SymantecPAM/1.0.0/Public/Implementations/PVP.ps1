class PVP : IPVP {
    PVP() {
        $this.ObjectType = "PVP"
    }
    PVP([object]$obj) {
        $this.ObjectType = "PVP"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}
