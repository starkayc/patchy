self:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.patchy;
  # Import the package from the flake
  settingsFormat = pkgs.formats.yaml { };
  settingsFile = settingsFormat.generate "patchy-settings.yml" cfg.settings;
  patchy = self.packages.${pkgs.system}.default;
in
{
  options.services.patchy = {
    enable = lib.mkEnableOption "Enable patchy service.";

    package = lib.mkOption {
      type = lib.types.package;
      default = patchy;
      description = "The patchy package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "patchy";
<<<<<<< HEAD
      description = "User account under which http3-ytproxy runs.";
=======
      description = "User account under which patchy runs.";
>>>>>>> upstream/master
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "patchy";
<<<<<<< HEAD
      description = "Group under which http3-ytproxy runs.";
=======
      description = "Group under which patchy runs.";
>>>>>>> upstream/master
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        The settings patchy should use.

        See [config.example.yml](https://codeberg.org/Fijxu/patchy/src/branch/master/config/config.example.yml) for a list of all possible options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "patchy") {
      patchy = {
        description = "patchy user";
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = lib.mkIf (cfg.group == "patchy") {
      patchy = { };
    };

    systemd.services.patchy = {
<<<<<<< HEAD
      description = "Youtube /videoplayback proxy";
=======
      description = "Temporary and light file uploader";
>>>>>>> upstream/master
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/patchy";
        DynamicUser = true;
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
      };
    };
  };
}
