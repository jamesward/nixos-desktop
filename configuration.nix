# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.kernelParams = [ "ipv6.disable=1" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Can't figure out how to make nix use a different dir for builds
# Using /tmp on tmpfs can easily cause "now space left on device" errors
#
#  boot.tmpOnTmpfs = true;
#  boot.tmpOnTmpfsSize = "5%";

#  boot.blacklistedKernelModules = [ "bluetooth" "btusb" ];

  networking.hostName = "nixos"; # Define your hostname.
  networking.enableIPv6 = false;

  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    wifi.scanRandMacAddress = false;
  };

  time.timeZone = "America/Denver";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "jw";
  };

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.xserver.excludePackages = [ pkgs.xterm ];

  services.printing = {
    enable = true;
    listenAddresses = [ "localhost:631" ];
    browsing = false;
    defaultShared = false;
  };

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.openFirewall = true;

# Doesn't seem to do much
#  services.throttled.enable = true;

#  sound.enable = true;
#  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = false;
  hardware.enableRedistributableFirmware = true;
  security.rtkit.enable = true;
#  services.pipewire = {
#    enable = true;
#    alsa.enable = true;
#    alsa.support32Bit = true;
#    pulse.enable = true;
#  };
  services.logind.lidSwitch = "ignore";

  users.users.jw = {
    isNormalUser = true;
    description = "James Ward";
#    extraGroups = [ "networkmanager" "wheel" "docker"];
    extraGroups = [ "networkmanager" "wheel" "docker" "tty"];
  };

  home-manager.users.jw = { pkgs, lib, ... }: {
    home.stateVersion = "24.11";

    nixpkgs.config = {
      allowUnfree = true;
      packageOverrides = pkgs: {
        unstable = import <nixos-unstable> {
          config = config.nixpkgs.config;
        };
        bashGitPrompt = (import ./bash-git-prompt.nix);
      };
    };

    home.sessionVariables = {
      NIX_SHELL_PRESERVE_PROMPT=1;
      GIT_PROMPT_THEME="Custom";
      GIT_PROMPT_ONLY_IN_REPO=1;
#      NIXOS_OZONE_WL = "1";
    };

    home.packages = [
      pkgs.google-chrome
      pkgs.trash-cli
      pkgs.maven
      pkgs.jdk
      pkgs.gnome-tweaks
      pkgs.gnomeExtensions.vitals
      pkgs.gnomeExtensions.dash-to-panel
      pkgs.unstable.jetbrains.idea-ultimate
      pkgs.unstable.httptap
      pkgs.unzip
      pkgs.nix-index
      pkgs.steam-run
      pkgs.inetutils
      pkgs.bashGitPrompt
      pkgs.gimp
      pkgs.audacity
      pkgs.gh
#      pkgs.unstable.zed-editor
      pkgs.unstable.rain
      pkgs.unstable.amazon-q-cli
      pkgs.unstable.pkl
    ];

    programs.bash.enable = true;
    programs.bash.shellAliases = {
       rm = "trash-put";
       mvn-release = "mvn release:prepare release:perform -Darguments=-Dgpg.passphrase=\"\"";
       mvn-package = "mvn clean package";
       q = "amazon-q chat";
       yolo = "amazon-q chat --no-interactive --accept-all \$@";
    };
    programs.bash.initExtra = ''
      PS1="\w $ "
      PROMPT_COMMAND="echo -ne \"\033]0;''${PWD/#$HOME/\~}\007\""
      source ${pkgs.bashGitPrompt}/gitprompt.sh
    '';

    # Use `dconf watch /` to track stateful changes you are doing
    dconf.settings = {
      "org/gnome/desktop/peripherals/touchpad" = {
        send-events = "disabled";
      };
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-battery-type = "nothing";
        sleep-inactive-ac-type = "nothing";
        idle-dim = false;
      };
      "org/gnome/desktop/session" = {
        idle-delay = lib.hm.gvariant.mkUint32 0;
      };
      "org/gnome/desktop/screensaver" = {
        lock-enabled = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "sloppy";
      };
      "org/gnome/desktop/search-providers" = {
        disable-external = true;
      };
      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
      };
      "org/gnome/mutter" = {
        edge-tiling = false;
      };
      "org/gnome/desktop/interface" = {
        clock-format = "12h";
      };
      "org/gtk/settings/file-chooser" = {
        clock-format = "12h";
      };
      "org/gnome/desktop/wm/preferences" = {
        auto-raise = true;
      };
      "org/gnome/Console" = {
        theme = "auto";
      };
      "org/gnome/terminal/legacy" = {
        new-terminal-mode = "tab";
      };
      "org/gnome/terminal/legacy/keybindings" = {
        reset-and-clear = "<Primary><Shift>k";
      };
      "org/gnome/desktop/wm/keybindings" = {
        switch-applications = [];
        switch-applications-backward = [];
        switch-windows = [];
        switch-windows-backward = [];
        cycle-windows = ["<Alt>Tab"];
        cycle-windows-backward = ["<Shift><Alt>Tab"];
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;

        # `gnome-extensions list` for a list
        enabled-extensions = [
          "Vitals@CoreCoding.com"
          "dash-to-panel@jderose9.github.com"
          "apps-menu@gnome-shell-extensions.gcampax.github.com"
        ];

        favorite-apps = [
          "org.gnome.Terminal.desktop"
          "org.gnome.Nautilus.desktop"
          "google-chrome.desktop"
          "idea-ultimate.desktop"
        ];
      };
      "org/gnome/shell/extensions/dash-to-panel" = {
        group-apps = false;
      };
      "org/gnome/shell/extensions/vitals" = {
        update-time = 1;
        hot-sensors = [
          "_processor_frequency_"
          "_processor_usage_"
          "_memory_usage_"
          "__fan_avg__"
          "_temperature_thinkpad_cpu_"
        ];
      };
      "org/gnome/desktop/sound" = {
        theme-name = "freedesktop";
      };
      "org/gnome/desktop/interface" = {
        font-antialiasing = "rgba";
        enable-animations = false;
      };
      "org/gnome/desktop/peripherals/mouse" = {
        speed = -0.25;
      };
    };

    programs.git = {
      enable = true;
      userName  = "James Ward";
      userEmail = "james@jamesward.com";
      signing = { 
        signByDefault = true;
        key = null;
      };
      extraConfig = {
        credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
        push.default = "current";
        push.followTags = true;
        pull.rebase = true;
        rebase.autostash = true;
        core.pager = "less -+S";
        core.autocrlf = "input";
        commit.gpgsign = true;
        init.defaultBranch = "main";
        http.postBuffer = "157286400";
      };
    };
    programs.vim = {
      enable = true;
      extraConfig = ''
        syntax on
        set noautoindent
        set nocindent
        set nosmartindent
        set tabstop=4
        set shiftwidth=4
        set expandtab
        set mouse-=a
      '';
    };

    home.file = {
      ".gradle/gradle.properties".source = ./secrets/gradle.properties;
      ".m2/settings.xml".source = ./secrets/settings.xml;
      ".sbt/1.0/sonatype.sbt".source = ./secrets/sonatype.sbt;
      ".sbt/1.0/settings.sbt".source = ./dotfiles/settings.sbt;
      ".git-prompt-colors.sh".source = ./dotfiles/.git-prompt-colors.sh;
    };

  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
#    rootless = {
#      enable = true;
#      setSocketVariable = true;
#    };
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-connections
    gnome-console
  ]) ++ (with pkgs; [
    cheese # webcam tool
    epiphany # web browser
    geary # email reader
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    yelp # Help view
    simple-scan
    gnome-initial-setup
    gnome-contacts
    gnome-weather
    gnome-maps
    gnome-music
  ]);

  programs.dconf.enable = true;
  programs.seahorse.enable = true;

  # Enable external apps to work via NIX_LD_LIBRARY_PATH
  programs.nix-ld.enable = true;

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  hardware.fancontrol.enable = true;
  hardware.fancontrol.config =
    ''
    INTERVAL=1
    DEVPATH=hwmon2=devices/platform/thinkpad_hwmon
    DEVNAME=hwmon2=thinkpad
    FCTEMPS=hwmon2/pwm1=hwmon2/temp1_input
    FCFANS= hwmon2/pwm1=hwmon2/fan2_input+hwmon2/fan1_input
    MINTEMP=hwmon2/pwm1=20
    MAXTEMP=hwmon2/pwm1=60
    MINSTART=hwmon2/pwm1=150
    MINSTOP=hwmon2/pwm1=0
    '';

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    gnome-terminal
    linux-firmware
    enchant
    (aspellWithDicts (dicts: with dicts; [ en ]))
  ];

  environment.defaultPackages = [ ];

  environment.variables = {
    EDITOR = "vim";
  };

  programs.gnupg.agent = {
    enable = true;
  };

  networking.firewall.enable = false;

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
