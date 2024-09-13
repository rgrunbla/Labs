{ pkgs, lib, nixos-generators, buildEnv, ... }:

let
  padString = (n: if n < 10 then "0" + toString n else toString n);
  bridges = [ "disi" "frix" "interco" "ora" "nflx" "tp" "nflxhe" "orahe" "he" ];
  networks = [
    { interface_name = "enp0s3"; bridge = "disi"; }
    { interface_name = "enp0s8"; bridge = "tp"; }
  ];
  nodes = {
    frixweb = {
      defaultGateway = "37.49.234.254";
      interfaces = [
        { network_name = "frix"; address = "37.49.234.1"; prefixLength = 24; }
      ];
      variables = {
        hostName = "FranceIx-Web";
        imports_generators = [ genWebsiteConf genNetConf ];
        genWebsiteFunction = { node }: ./websites/franceix/index.html;
      };
    };
    oraweb = {
      defaultGateway = "217.109.218.254";
      interfaces = [
        { network_name = "ora"; address = "217.109.218.1"; prefixLength = 24; }
      ];
      variables = {
        hostName = "Orange-Web";
        imports_generators = [ genWebsiteConf genNetConf ];
        genWebsiteFunction = { node }: ./websites/orange/index.html;
      };
    };
    nflxweb = {
      defaultGateway = "45.57.2.254";
      interfaces = [
        { network_name = "nflx"; address = "45.57.2.1"; prefixLength = 24; }
      ];
      variables = {
        hostName = "Netflix-Web";
        imports_generators = [ genWebsiteConf genNetConf ];
        genWebsiteFunction = { node }: ./websites/netflix/index.html;
      };
    };
    heweb = {
      defaultGateway = "216.218.236.254";
      interfaces = [
        { network_name = "he"; address = "216.218.236.2"; prefixLength = 24; }
      ];
      variables = {
        hostName = "He-Web";
        imports_generators = [ genWebsiteConf genNetConf ];
        genWebsiteFunction = { node }: ./websites/he/index.html;
      };
    };
    frix = {
      interfaces = [
        { network_name = "disi"; address = "37.49.232.254"; prefixLength = 24; }
        { network_name = "frix"; address = "37.49.234.254"; prefixLength = 24; }
      ];
      variables = {
        hostName = "France-IX";
        ASN = "57734";
        routerId = "37.49.232.254";
        networks = [ "37.49.232.0/24" "37.49.234.0/24" ];
        birdLgServers = [ "FranceIX<37.49.232.254>" ];
        rspeers = [
        ] ++ (map
          (i: {
            name = "posteb101${toString i}";
            description = "AS 101 ${padString i} -- Poste ${padString i} en B101";
            ip = "37.49.232.${toString i}";
            interface = "frix-disi";
            ASN = "101${padString i}";
          })
          (lib.range 1 13)) ++ (map
          (i: {
            name = "posteb109${padString i}";
            description = "AS 109 ${padString i} -- Poste ${padString i} en B109";
            ip = "37.49.232.${toString (100+i)}";
            interface = "frix-disi";
            ASN = "109${padString i}";
          })
          (lib.range 1 13));
        peers = [
          {
            name = "orange";
            description = "AS 5511 -- Orange";
            interface = "frix-disi";
            ip = "37.49.232.253";
            ASN = "5511";
            passive = "off";
          }
        ];
        imports_generators = [ genBirdConf genNetConf genWebsiteConf genBirdLgProxyConf genBirdLgWebsiteConf ];
        genWebsiteFunction = genWebsiteIndex;
      };
    };
    ora = {
      interfaces = [
        { network_name = "disi"; address = "37.49.232.253"; prefixLength = 24; }
        { network_name = "interco"; address = "192.173.64.1"; prefixLength = 24; }
        { network_name = "ora"; address = "217.109.218.254"; prefixLength = 24; }
        { network_name = "orahe"; address = "216.218.242.2"; prefixLength = 31; }
      ] ++ (map
        (i: {
          network_name = "tp";
          address = "2.2.0.${toString (i*2)}"; /* Postes B101 */
          prefixLength = 31;
        })
        (lib.range 0 12))
      ++ (map
        (i: {
          network_name = "tp";
          address = "2.2.0.${toString (100+i*2)}"; /* Postes B109 */
          prefixLength = 31;
        })
        (lib.range 0 12));

      variables = {
        hostName = "Orange";
        ASN = "5511";
        routerId = "217.109.218.254";
        networks = [ "2.2.0.0/16" "217.109.218.0/24" ];
        birdLgServers = [ "Orange<217.109.218.254>" ];
        peers = [
          {
            name = "netflix";
            description = "AS 2906 -- Netflix";
            interface = "ora-interco";
            ip = "192.173.64.254";
            ASN = "2906";
            passive = "off";
          }
          {
            name = "franceix";
            description = "AS 57734 -- FRANCEIX";
            interface = "ora-disi";
            ip = "37.49.232.254";
            ASN = "57734";
            passive = "off";
          }
          {
            name = "he";
            description = "AS 6939 -- Hurricane Electric";
            interface = "ora-orahe";
            ip = "216.218.242.3";
            ASN = "6939";
            passive = "off";
          }
        ] ++ (map
          (i: {
            name = "posteb101${toString (i+1)}";
            description = "AS 101 ${padString (i+1)} -- Poste ${padString (i+1)} en B101";
            ip = "2.2.0.${toString (i*2+1)}";
            interface = "ora-tp";
            ASN = "101${padString (i+1)}";
            passive = "on";
          })
          (lib.range 0 12)) ++ (map
          (i: {
            name = "posteb109${toString (i+1)}";
            description = "AS 109 ${padString (i+1)} -- Poste ${padString (i+1)} en B109";
            ip = "2.2.0.${toString (100+i*2+1)}";
            interface = "ora-tp";
            ASN = "109${padString (i+1)}";
            passive = "on";
          })
          (lib.range 0 12));
        rspeers = [ ];
        imports_generators = [ genBirdConf genNetConf genWebsiteConf genBirdLgProxyConf genBirdLgWebsiteConf ];
        genWebsiteFunction = genWebsiteIndex;

      };
    };
    nflx = {
      interfaces = [
        { network_name = "interco"; address = "192.173.64.254"; prefixLength = 24; }
        { network_name = "nflx"; address = "45.57.2.254"; prefixLength = 24; }
        { network_name = "nflxhe"; address = "216.218.242.0"; prefixLength = 31; }
      ];
      variables = {
        hostName = "Netflix";
        ASN = "2906";
        routerId = "192.173.64.254";
        networks = [ "192.173.64.0/24" "45.57.2.0/24" ];
        birdLgServers = [ "Netflix<192.173.64.254>" ];
        peers = [
          {
            name = "orange";
            description = "AS 5511 -- ORANGE";
            interface = "nflx-interco";
            ip = "192.173.64.1";
            ASN = "5511";
            passive = "off";
          }
          {
            name = "he";
            description = "AS 6939 -- Hurricane Electric";
            interface = "nflx-nflxhe";
            ip = "216.218.242.1";
            ASN = "6939";
            passive = "off";
          }
        ];
        rspeers = [ ];
        imports_generators = [ genBirdConf genNetConf genWebsiteConf genBirdLgProxyConf genBirdLgWebsiteConf ];
        genWebsiteFunction = genWebsiteIndex;
      };
    };
    he = {
      interfaces = [
        { network_name = "nflxhe"; address = "216.218.242.1"; prefixLength = 31; }
        { network_name = "orahe"; address = "216.218.242.3"; prefixLength = 31; }
        { network_name = "he"; address = "216.218.236.254"; prefixLength = 24; }
      ];

      variables = {
        hostName = "He";
        ASN = "6939";
        routerId = "216.218.236.254";
        networks = [ "216.218.128.0/17" ];
        birdLgServers = [ "HurricaneElectric<216.218.236.254>" ];
        peers = [
          {
            name = "netflix";
            description = "AS 2906 -- Netflix";
            interface = "he-nflxhe";
            ip = "216.218.242.0";
            ASN = "2906";
            passive = "off";
          }
          {
            name = "orange";
            description = "AS 5511 -- Orange";
            interface = "he-orahe";
            ip = "216.218.242.2";
            ASN = "5511";
            passive = "off";
          }
        ];
        rspeers = [ ];
        imports_generators = [ genBirdConf genNetConf genWebsiteConf genBirdLgProxyConf genBirdLgWebsiteConf ];
        genWebsiteFunction = genWebsiteIndex;

      };
    };

  };

  baseConfig = {
    system.stateVersion = "23.05";

    users.users.root.password = "root";
    services.getty.autologinUser = lib.mkDefault "root";

    networking.usePredictableInterfaceNames = false;

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv4.conf.all.arp_filter" = true;
      # By default, not automatically configure any IPv6 addresses.
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;
    };

    i18n.defaultLocale = "fr_FR.UTF-8";
    console = {
      font = "Lat2-Terminus16";
      keyMap = "fr";
    };

    networking.useNetworkd = true;

    environment.systemPackages = with pkgs; [
      tcpdump
      tmux
      bgpdump
      bridge-utils
      ripgrep
      mtr
      traceroute
    ];
  };

  hostConfig = baseConfig // {
    systemd.network = {
      enable = true;
      netdevs = (lib.listToAttrs
        (lib.imap1
          (idx: bridge_name: {
            name = "20-${bridge_name}-${toString idx}";
            value = {
              netdevConfig = {
                Kind = "bridge";
                Name = bridge_name;
              };
            };
          })
          bridges));

      networks =
        (lib.listToAttrs
          (lib.imap1
            (idx: network: {
              name = "30-${network.interface_name}-${toString idx}";
              value =
                {
                  matchConfig.Name = network.interface_name;
                  networkConfig.Bridge = network.bridge;
                };
            })
            networks)) // (lib.listToAttrs
          (lib.imap1
            (idx: bridge_name: {
              name = "30-${bridge_name}-${toString idx}";
              value = {
                matchConfig.Name = bridge_name;
              };
            })
            bridges));
    };

    containers =
      (lib.mapAttrs
        (name: node: {
          autoStart = true;
          privateNetwork = true;
          extraVeths = (lib.listToAttrs
            (lib.imap1
              (idx: interface: {
                name = "${name}${interface.network_name}${padString idx}";
                value = {
                  hostBridge = interface.network_name;
                  localAddress = "${interface.address}/${toString interface.prefixLength}";
                };
              })
              node.interfaces));

          config = { config, pkgs, ... }: baseConfig // {
            imports = map (fun: (fun { inherit node; })) node.variables.imports_generators;
            networking.defaultGateway = node.defaultGateway or null;
          };
        })
        nodes);
  };

  genWebsiteIndex = { node }: pkgs.writeText "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Bienvenue sur la page de ${node.variables.hostName}, AS ${node.variables.ASN}</title>
    </head>

    <body>
    Bienvenue sur la page de ${node.variables.hostName}, AS n°${node.variables.ASN} ! <br/>
    J'annonce les réseaux suivants:<br/>
    <ul>
    ${lib.concatStringsSep "<br/>" (map (network: "<ul>" + network + "</ul>") node.variables.networks)}
    </ul>
    <br/>
    Cette page web est servie sur les adresses IPs suivantes :
    <ul>
    ${lib.concatStringsSep "<br/>" (map (interface: "<ul>" + interface.address + "</ul>") node.interfaces)}
    </ul>
    </body>
    </html>
  '';

  genEndUserWebsiteIndex = { node }: pkgs.writeText "index.html" ''
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${node.variables.title}</title>
    </head>

    <body>
    ${node.variables.body}
    </body>
    </html>
  '';

  genWebsiteConf = { node }: {
    system.activationScripts.website_setup = {
      text =
        "if [ ! -d '/srv/http' ] ; then mkdir -p '/srv/http/'; fi; cp ${node.variables.genWebsiteFunction { node = node;
                }} /srv/http/index.html; chown nginx:users -R /srv/http; chmod 770 -R /srv/http";
      deps = [ "etc" ];
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "_" = {
          root = "/srv/http/";
        };
      };
    };

    networking.firewall = {
      allowPing = true;
      logRefusedConnections = true;
      allowedTCPPorts = [ 80 ];
    };
  };

  genNetConf = { node }: {
    networking = {
      hostName = node.variables.hostName;
      domain = "lan";
      firewall = {
        enable = true;
        # Allow traceroute
        allowPing = true;
        logRefusedConnections = true;
        allowedUDPPortRanges = [{
          from = 33434;
          to = 33525;
        }];
      };
    };
  };

  genBirdLgProxyConf = { node }: {
    services.bird-lg = {
      proxy = {
        enable = true;
        listenAddress = "0.0.0.0:8000";
      };
    };
    networking.firewall = {
      allowedTCPPorts = [ 8000 ];
      allowPing = true;
      logRefusedConnections = true;
    };
  };
  genBirdLgWebsiteConf = { node }: {
    services.bird-lg = {
      frontend = {
        enable = true;
        servers = node.variables.birdLgServers;
        domain = "";
        listenAddress = "0.0.0.0:5000";
      };
    };
    networking.firewall = {
      allowedTCPPorts = [ 5000 ];
      allowPing = true;
      logRefusedConnections = true;
    };
  };

  genBirdConf = { node }: {
    networking.firewall = {
      allowPing = true;
      logRefusedConnections = true;
      allowedTCPPorts = [ 179 ];
    };

    system.activationScripts.bird_setup = {
      text =
        "if [ ! -d '/srv/bird' ] ; then mkdir -p '/srv/bird/'; fi; chown bird2:users -R /srv/bird/; chmod 770 -R /srv/bird/";
      deps = [ "etc" ];
    };

    services.bird2 = {
      enable = true;
      config = (builtins.readFile
        (pkgs.writeText "bird2.conf" ''
          ################################################
          #               Variable header                #
          ################################################
          log "/srv/bird/all.log" all;
          define OWNAS = ${node.variables.ASN};
          define ROUTERID = ${node.variables.routerId};
          define OWNIP = ${node.variables.routerId};
          define OWNNETSET = [ ${lib.concatStringsSep ", " (map (network: network + "+") node.variables.networks)} ];

          ################################################
          #                 Header end                   #
          ################################################

          protocol mrt {
            table "*";
            where source = RTS_BGP;
            filename "/srv/bird/%N_%F_%T.mrt";
            period 300;
          }

          router id ROUTERID;

          protocol device {
            scan time 10;
          }

          #####################
          # Utility functions #
          #####################

          function is_self_net() {
            return net ~ OWNNETSET;
          }

          # On n'accepte que les réseaux mis en œuvre dans le TP
          function is_valid_network() {
             return net ~ [
              10.0.0.0/8{16,32}, # Élèves
              172.16.1.0/24{31,32}, # Élèves-Interco
              37.49.232.0/24{24,32}, # IXP-INTERCO
              37.49.234.0/24{24,32}, # IXP-WEB
              2.2.0.0/16{16,32}, # Orange
              217.109.218.0/24, # Orange-WEB
              192.173.64.0/24{16,32}, # Netflix
              45.57.2.0/24{24,32}, # Netflix-WEB
              216.218.128.0/17{17,32} # HE
            ];
          }

          protocol kernel {
            scan time 20;
            ipv4 {
              import none;
              export filter {
                print "export filter ipv4 kernel, net: ", net, " source: ", source;
                if source = RTS_STATIC then print "reject";
                if source = RTS_STATIC then reject;
                krt_prefsrc = OWNIP;
                print "accept";
                accept;
              };
            };
          }

          /* Static routes allow to aggregate */
          protocol static {
            # On définit nos réseaux en tant que routes statiques, et on importe ces routes dans BIRD
            ${lib.concatStringsSep "\n" (map (network: "route " + network + " reject;") node.variables.networks)}
            ipv4 {
              import all; /* We import all static routes into bird2 */
              export none; /* We don't export any route to static routes */
            };
          }

          #####################
          # ROUTE SERVER PEER #
          #####################

          # Bloc utilisé uniquement par le route server

          template bgp rspeers {
            local as OWNAS;
            ipv4 {
              import filter {
                # On importe dans BIRD2 uniquement les réseaux valides
                # qui ne correspondent pas à nos propres réseaux
                if is_valid_network() && !is_self_net() then {
                  accept;
                } else {
                  reject;
                }
              };
              export filter {
                # On exporte à nos voisins que les réseaux appris par BGP
                # ou définis par nos propres routes statiques.
                if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then {
                  print net;
                  if net ~ OWNNETSET then {
                    # En tant que route server, si l'on souhaite annoncer nos
                    # propres réseaux, puisque l'on est "rs client" (route serveur)
                    # il est nécessaire d'ajouter « à la main » notre numéro d'AS.
                    bgp_path.prepend(OWNAS);
                    accept;
                  } else {
                    # On n'exporte pas les routes en passant directement vers notre transitaire
                    if bgp_path ~ [= 5511 * =] then {
                      print "export filter rspeers kernel, reject, net: ", net, " source: ", source, " bgp_path: ", bgp_path;
                      reject;
                    } else {
                    accept;
                    }
                  }
                } else {
                  reject;
                }
              };
              add paths tx; # On accepte de propager plusieurs routes sortantes vers différents réseaux
            };
            rs client; # On est un route serveur
            passive on; # The router does not send BFD packets until it has received one from the other side. 
            debug all;
          }

          template bgp dnpeers {
            local as OWNAS;
            ipv4 {
              import filter {

                # On importe dans BIRD2 uniquement les réseaux valides
                # qui ne correspondent pas à nos propres réseaux

                if is_valid_network() && !is_self_net() then {
                  print "dnpeers import filter accept";
                  accept;
                } else {
                  print "dnpeers import filter reject";
                  reject;
                }
              };

              # On exporte à nos voisins que les réseaux appris par BGP
              # ou définis par nos propres routes statiques.

              export filter { if is_valid_network() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };

              # On importe au maximum 1000 routes, et au delà, on refuse les nouvelles routes
              import limit 1000 action block;
            };
            debug all;
          }

          /* Route server peers */
          ${lib.concatStringsSep "\n" (map (peer:
                "      protocol bgp ${peer.name} from rspeers {
                  neighbor ${peer.ip} as ${peer.ASN};
                  description \"${peer.description}\";
                }")
                node.variables.rspeers)}

          /* Normal peers */
          ${lib.concatStringsSep "\n" (map (peer:
                "      protocol bgp ${peer.name} from dnpeers {
                  neighbor ${peer.ip} as ${peer.ASN};
                  description \"${peer.description}\";
                  passive ${peer.passive};
                }")
                node.variables.peers)}
        '')
      );
    };
  };

in
hostConfig