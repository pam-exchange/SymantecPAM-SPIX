class Role : IRole {
    Role() {
        $this.ObjectType = "Role"
    }
    Role([object]$obj) {
        $this.ObjectType = "Role"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}
