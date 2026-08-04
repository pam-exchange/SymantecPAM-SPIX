class UserGroup : IUserGroup {
    UserGroup() {
        $this.ObjectType = "UserGroup"
    }
    UserGroup([object]$obj) {
        $this.ObjectType = "UserGroup"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
        $this.targetGroup = [string]$obj.targetGroup
        $this.requestorGroup = [string]$obj.requestorGroup
        $this.Role = [string]$obj.Role
    }
}
