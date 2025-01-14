{ config, pkgs, ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "/Applications/Alacritty.app"
        "/Applications/Firefox.app"
        "/Applications/Obsidian.app"
        "/Applications/Spotify.app"
        "/Applications/Discord.app"
        "/Applications/Google Chrome.app"
      ];
    };
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.GuestEnabled = false;
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };
}
