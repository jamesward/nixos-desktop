{ config, lib, pkgs, ... }:

let
  p1Profile = builtins.path {
    path = "${./nbfc}/Lenovo ThinkPad P1 Gen 3.json";
    name = "lenovo-thinkpad-p1-gen3.json";
  };

  # Pinned to 0.5.3 (Lua hook support, tested on this laptop). The NixOS
  # 26.05 channel still ships 0.3.19, which has no Lua support at all.
  nbfcP1 = pkgs.nbfc-linux.overrideAttrs (old: {
    version = "0.5.3";
    src = pkgs.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-linux";
      tag = "0.5.3";
      hash = "sha256-x2boeFlTDnoVnazzQkCukZxZBFIW2rLjglarflNy334=";
    };

    nativeBuildInputs = [ pkgs.autoreconfHook pkgs.pkg-config ];
    buildInputs = [ pkgs.lua5_4 pkgs.curl pkgs.libxml2 pkgs.openssl ];
    configureFlags = [ "--bindir=${placeholder "out"}/bin" ];

    patches = [
      ./patches/nbfc-linux-lua-sleep-ms.patch
    ];

    postInstall = (old.postInstall or "") + ''
      install -Dm644 ${p1Profile} \
        "$out/share/nbfc/configs/Lenovo ThinkPad P1 Gen 3.json"
    '';
  });

  serviceConfig = pkgs.writeText "nbfc-p1-gen3.json" (builtins.toJSON {
    SelectedConfigId = "Lenovo ThinkPad P1 Gen 3";
    EmbeddedControllerType = "ec_sys";
  });

  startNbfc = pkgs.writeShellScript "start-nbfc-p1-gen3" ''
    set -eu

    product_name=$(cat /sys/class/dmi/id/product_name)
    product_version=$(cat /sys/class/dmi/id/product_version)
    if [ "$product_name" != "20THCTO1WW" ] ||
       [ "$product_version" != "ThinkPad P1 Gen 3" ]; then
      echo "Refusing to start NBFC with the P1 Gen 3 EC profile on $product_name ($product_version)" >&2
      exit 1
    fi

    if [ ! -r /sys/module/ec_sys/parameters/write_support ] ||
       [ "$(cat /sys/module/ec_sys/parameters/write_support)" != "Y" ]; then
      echo "Refusing to start NBFC: ec_sys write_support is not enabled" >&2
      exit 1
    fi

    # Never preserve a fixed manual speed across service restarts. Start from
    # profile-controlled auto mode every time.
    rm -f /var/lib/nbfc/state.json

    exec ${nbfcP1}/bin/nbfc_service \
      --embedded-controller ec_sys \
      --config-file ${serviceConfig}
  '';

  fallbackFirmwareAuto = pkgs.writeShellScript "nbfc-fallback-firmware-auto" ''
    # Normal SIGTERM cleanup uses the profile's delayed ResetLuaCode for both
    # fans. This is a best-effort independent fallback if startup or cleanup
    # fails before that hook can run.
    if [ -w /proc/acpi/ibm/fan ]; then
      echo level auto > /proc/acpi/ibm/fan || true
    fi
  '';
in
{
  # NBFC owns the P1 Gen 3's multiplexed EC fan registers. Never run another
  # fan controller or asynchronous fan-tach reader at the same time.
  services.thinkfan.enable = false;

  boot.kernelModules = [ "ec_sys" ];
  # fan_control=1 lets the ExecStopPost fallback write "level auto" to
  # /proc/acpi/ibm/fan if NBFC's own reset hooks don't run.
  boot.extraModprobeConfig = ''
    options ec_sys write_support=1
    options thinkpad_acpi fan_control=1
  '';

  environment.systemPackages = [ nbfcP1 ];

  systemd.services.nbfc_service = {
    description = "NBFC-Linux dual-fan control for ThinkPad P1 Gen 3";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    conflicts = [ "thinkfan.service" "fancontrol.service" ];
    path = [ pkgs.coreutils ];

    serviceConfig = {
      Type = "simple";
      ExecStart = startNbfc;
      ExecStopPost = fallbackFirmwareAuto;
      StateDirectory = "nbfc";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "30s";

      # NBFC itself also requests -1000 and allocates runtime memory up front.
      OOMScoreAdjust = -1000;
      NoNewPrivileges = true;
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  # Vitals is patched (patches/vitals-nbfc-fans.patch, applied in
  # configuration.nix) to read fan speeds from `nbfc status` instead of the
  # thinkpad hwmon fan*_input files, which race NBFC on EC selector 0x31.
  # Keep the fan display enabled; the original hot-sensors (with
  # __fan_avg__) in configuration.nix apply unchanged.
  home-manager.users.jw.dconf.settings."org/gnome/shell/extensions/vitals" = {
    show-fan = true;
  };
}
