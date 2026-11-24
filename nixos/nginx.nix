{ config, lib, ... }:
let
  autheliaSettings = config.services.authelia.instances.main.settings;
  blueskyPdsSettings = config.services.bluesky-pds.settings;
  copypartySettings = config.services.copyparty.settings;
  forgejoSettings = config.services.forgejo.settings.server;
  immichSettings = config.services.immich;
  llamacppSettings = config.services.llama-cpp;
  lldapSettings = config.services.lldap.settings;
  mealieSettings = config.services.mealie;
  syncthingSettings = config.services.syncthing;

  # "tcp://127.0.0.1:9091/" -> "http://127.0.0.1:9091"
  authelia = "http://${lib.removeSuffix "/" (lib.removePrefix "tcp://" autheliaSettings.server.address)}";

  # "unix:770:copyparty:/run/copyparty/party.sock" -> the path
  copyparty = "http://unix:${lib.last (lib.splitString ":" copypartySettings.i)}";

  # shared by files. and dav.; headers are set by hand so copyparty gets
  # exactly one X-Forwarded-For entry, and https since pine terminates tls
  copypartyProxyConfig =
    # nginx
    ''
      proxy_http_version 1.1;
      proxy_set_header   Connection        "";
      proxy_set_header   Host              $host;
      proxy_set_header   X-Real-IP         $remote_addr;
      proxy_set_header   X-Forwarded-For   $remote_addr;
      proxy_set_header   X-Forwarded-Proto https;

      # stream uploads/downloads instead of spooling them to disk
      proxy_buffering         off;
      proxy_request_buffering off;
      client_max_body_size    1024M;
      proxy_read_timeout      600s;
      proxy_send_timeout      600s;
      send_timeout            600s;
    '';
in
{
  # needed to access unix sockets
  systemd.services.nginx.serviceConfig.ProtectHome = false;

  services.nginx = {
    enable = true;

    # every vhost is reached through caddy on pine, which replaces any
    # client-sent X-Forwarded-For with just the client ip, so trust it
    commonHttpConfig =
      # nginx
      ''
        set_real_ip_from 100.64.0.4;
        real_ip_header   X-Forwarded-For;
      '';

    virtualHosts = {
      ${forgejoSettings.DOMAIN} = {
        locations."/" = {
          proxyPass = forgejoSettings.LOCAL_ROOT_URL;
          recommendedProxySettings = true;
          extraConfig =
            # nginx
            ''
              proxy_headers_hash_max_size 1024;
              proxy_headers_hash_bucket_size 128;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 17443;
          }
        ];
      };

      "photos.elladunbar.com" = {
        locations."/" = {
          # immich only listens on ::1; "localhost" also tries 127.0.0.1, which
          # gets refused and makes nginx mark the upstream as down
          proxyPass = "http://[::1]:${toString immichSettings.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig =
            # nginx
            ''
              client_max_body_size 50000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 18443;
          }
        ];
      };

      "recipes.elladunbar.com" = {
        locations."/" = {
          proxyPass = "http://${mealieSettings.listenAddress}:${toString mealieSettings.port}";
          # https by hand since pine terminates tls; mealie marks its session
          # cookie secure from X-Forwarded-Proto
          extraConfig =
            # nginx
            ''
              proxy_set_header Host              $host;
              proxy_set_header X-Forwarded-Proto https;
              proxy_set_header X-Forwarded-For   $remote_addr;
              proxy_set_header X-Real-IP         $remote_addr;

              # recipe images and backup restores
              client_max_body_size 1024M;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 23443;
          }
        ];
      };

      "auth.elladunbar.com" = {
        locations."/" = {
          proxyPass = authelia;
          # https by hand since pine terminates tls; authelia builds its
          # redirects from these
          extraConfig =
            # nginx
            ''
              proxy_set_header Host              $host;
              proxy_set_header X-Forwarded-Proto https;
              proxy_set_header X-Forwarded-Host  $host;
              proxy_set_header X-Forwarded-URI   $request_uri;
              proxy_set_header X-Forwarded-For   $remote_addr;
              proxy_set_header X-Real-IP         $remote_addr;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 21443;
          }
        ];
      };

      "files.elladunbar.com" = {
        # asked by auth_request below before every request; authelia answers
        # 200 with the user in Remote-User, or 401 with a login redirect
        locations."/internal/authelia/authz" = {
          proxyPass = "${authelia}/api/authz/auth-request";
          extraConfig =
            # nginx
            ''
              internal;
              proxy_set_header X-Original-Method $request_method;
              proxy_set_header X-Original-URL    https://$host$request_uri;
              proxy_set_header X-Forwarded-For   $remote_addr;
              proxy_set_header Content-Length    "";
              proxy_set_header Connection        "";
              proxy_pass_request_body off;
            '';
        };
        locations."/" = {
          proxyPass = copyparty;
          extraConfig =
            copypartyProxyConfig
            # nginx
            + ''
              auth_request     /internal/authelia/authz;
              auth_request_set $user $upstream_http_remote_user;
              auth_request_set $redirection_url $upstream_http_location;
              error_page 401 =302 $redirection_url;

              # copyparty logs in whoever this names, so it must only ever
              # come from authelia; this replaces any client-sent value
              proxy_set_header Remote-User $user;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 20443;
          }
        ];
      };

      # webdav clients (finder) can't follow a login redirect, so they get
      # copyparty without authelia and log in with the copyparty password
      "dav.elladunbar.com" = {
        locations."/" = {
          proxyPass = copyparty;
          extraConfig =
            copypartyProxyConfig
            # nginx
            + ''
              # an empty value drops the header, so a client can't send its
              # own and be logged in as anyone
              proxy_set_header Remote-User "";
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 22443;
          }
        ];
      };

      "*.${blueskyPdsSettings.PDS_HOSTNAME}" = {
        locations."/" = {
          proxyPass = "http://localhost:${toString blueskyPdsSettings.PDS_PORT}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 19443;
          }
        ];
      };

      "river-birch.nodes.elladunbar.com" = {
        locations."/" = {
          proxyPass = "http://${llamacppSettings.settings.host}:${toString llamacppSettings.settings.port}";
          extraConfig =
            # nginx
            ''
              # headers by hand: llama-server only answers when Host (with the
              # port, which $host drops) matches its cors-origins
              proxy_set_header Host            $host:$server_port;
              proxy_set_header X-Real-IP       $remote_addr;
              proxy_set_header X-Forwarded-For $remote_addr;

              # headscale only hands this name to tailnet clients, who connect
              # straight to 100.64.0.5; llama-server has no authentication, so
              # refuse the vhost to anyone else in case it is ever proxied
              allow 100.64.0.0/10;
              deny all;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 5678;
          }
        ];
      };

      # same name as the llama.cpp vhost, so it needs its own attribute name
      syncthing-gui = {
        serverName = "river-birch.nodes.elladunbar.com";
        locations."/" = {
          proxyPass = "http://${syncthingSettings.guiAddress}";
          extraConfig =
            # nginx
            ''
              # syncthing refuses non-localhost Host headers on a loopback gui
              proxy_set_header Host            localhost;
              proxy_set_header X-Real-IP       $remote_addr;
              proxy_set_header X-Forwarded-For $remote_addr;
              proxy_read_timeout 600s;

              # the gui has no password; refuse anyone off the tailnet in case
              # this vhost is ever proxied
              allow 100.64.0.0/10;
              deny all;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 8384;
          }
        ];
      };

      lldap-gui = {
        serverName = "river-birch.nodes.elladunbar.com";
        locations."/" = {
          proxyPass = "http://${lldapSettings.http_host}:${toString lldapSettings.http_port}";
          recommendedProxySettings = true;
          extraConfig =
            # nginx
            ''
              # user admin stays on the tailnet, like the syncthing gui
              allow 100.64.0.0/10;
              deny all;
            '';
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = lldapSettings.http_port;
          }
        ];
      };
    };
  };
}
