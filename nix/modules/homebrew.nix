{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "firefox"
      "chatgpt"
    ];
    masApps = {
    };
    onActivation.cleanup = "zap";
  };
}