{ pkgs, ... }:
let
  pythonPackages = pkgs.python313.withPackages (ps: with ps; [

  ]);
in
{
  # Add the custom Python environment to system packages
  environment.systemPackages = [ pythonPackages ];
}