class PCP : IPCP {
    PCP() {
        $this.ObjectType = "PCP"
    }
    PCP([object]$obj) {
        $this.ObjectType = "PCP"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Type = [string]$obj.Type
        $this.Description = [string]$obj.Description
    }
}
