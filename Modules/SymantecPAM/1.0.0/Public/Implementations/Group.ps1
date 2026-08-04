class Group : IGroup {
    Group() {
        $this.ObjectType = "Group"
    }
    Group([object]$obj) {
        $this.ObjectType = "Group"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}
