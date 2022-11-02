{ config, pkgs, ... }:

{
  users.users = {
    "54l1m" = {
      home = "/Users/54L1M";              # Home directory path.
      description = "User 54L1M";         # User description.
    };
};
}
