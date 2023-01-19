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

  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "5%";

  networking.hostName = "nixos"; # Define your hostname.

  networking.networkmanager.enable = true;

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

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  services.xserver.excludePackages = [ pkgs.xterm ];

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.jw = {
    isNormalUser = true;
    description = "James Ward";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.jw = { pkgs, ... }: {
    home.stateVersion = "22.11";

    nixpkgs.config.allowUnfree = true;
    home.packages = [
      pkgs.google-chrome
      pkgs.trash-cli
    ];
    programs.bash.enable = true;
    programs.bash.shellAliases = {
       rm = "trash-put";
    };

    # Use `dconf watch /` to track stateful changes you are doing
    dconf.settings = {
      "org/gnome/desktop/peripherals/touchpad" = {
        send-events = "disabled";
      };
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-battery-type = "nothing";
        sleep-inactive-ac-type = "nothing";
      };
      "org/gnome/desktop/session" = {
        idle-delay = 0;
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
        core.pager = "less -+S";
        core.autocrlf = "input";
        commit.gpgsign = true;
        init.defaultBranch = "main";
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
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-connections
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gedit # text editor
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

  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "jw";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    gnome.gnome-tweaks
  ];

  programs.gnupg.agent = {
    enable = true;
  };

  networking.firewall.enable = false;

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
