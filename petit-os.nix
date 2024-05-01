{ pkgs, lib, ... }:

{
  system.stateVersion = "23.11";
  boot.loader.grub.timeoutStyle = "hidden";

  # Disable scripted networking and firewall
  networking = {
    useDHCP = false;
    firewall = {
      enable = false;
    };
  };

  systemd = {
    network = {
      enable = true;
      links = {
        "80-eth0" = {
          matchConfig.OriginalName = "eth0";
          linkConfig.Name = "vnet0";
        };

        "80-eth1" = {
          matchConfig.OriginalName = "eth1";
          linkConfig.Name = "vnet1";
        };
      };
    };
  };

  nixpkgs.config.firefox.speechSynthesisSupport = false;

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;
  services.openssh.settings.PermitRootLogin = "false";

  boot.kernel.sysctl = {
    # Disable Forwarding
    "net.ipv4.conf.all.forwarding" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv4.conf.default.forwarding" = 0;
    "net.ipv6.conf.default.forwarding" = 0;

    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.default.autoconf" = 0;
    
    "net.ipv6.conf.vnet0.accept_ra" = 0;
    "net.ipv6.conf.vnet0.autoconf" = 0;

    "net.ipv6.conf.vnet1.accept_ra" = 0;
    "net.ipv6.conf.vnet1.autoconf" = 0;

    # Don't use RFC 4941 ( IPv6 Privacy Extensions )
    "net.ipv6.conf.all.use_tempaddr" = 0;
    "net.ipv6.conf.default.use_tempaddr" = lib.mkForce 0;
  };

  i18n.defaultLocale = "fr_FR.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  environment.systemPackages = with pkgs; [
    tcpdump
    tmux
    tshark
    nano
    vim
    ipcalc
    dig
    radvd
    emacs
    bridge-utils
    ripgrep
    mtr
    traceroute
    ncdu
    python3
    dhcpcd
    firefox
  ];

  environment.shellAliases = {
    ip = "ip -c";
  };

  services.xserver = {
    layout = "fr";
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
    displayManager = {
      defaultSession = "xfce";
      autoLogin = {
        enable = true;
        user = "utilisateur";
      };
      lightdm = {
        enable = true;
        greeters.slick = {
          enable = true;
          theme.name = "Zukitre-dark";
        };
      };
    };
  };

  users = {
    users = {
      root = {
        password = "root";
      };
      utilisateur = {
        isNormalUser = true;
        initialPassword = "motdepasse";
        description = "Utilisateur";
        extraGroups = [ "wheel" ];
      };
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "utilisateur" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];
}
