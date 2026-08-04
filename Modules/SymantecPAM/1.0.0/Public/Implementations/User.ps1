class User : IUser {
    User() {
        $this.ObjectType = "User"
    }
    User([object]$obj) {
        $this.ObjectType = "User"
        $this.ID = [int]$obj.ID
        $this.Action = [string]$obj.Action
        $this.Name = [string]$obj.Name
        $this.Description = [string]$obj.Description
    }
}
