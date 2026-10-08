{ config, ... }:
let
  blueskyPdsSettings = config.services.bluesky-pds.settings;
  copypartySettings = config.services.copyparty.settings;
  forgejoSettings = config.services.forgejo.settings.server;
  immichSettings = config.services.immich;
  llamacppSettings = config.services.llama-cpp;
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

      "files.elladunbar.com" = {
        locations."/" = {
          proxyPass = "http://${copypartySettings.i}:${toString copypartySettings.p}";
          # headers are set by hand so copyparty gets exactly one
          # X-Forwarded-For entry, and https since pine terminates tls
          extraConfig =
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
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 20443;
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
          recommendedProxySettings = true;
        };
        listen = [
          {
            addr = "100.64.0.5";
            port = 5678;
          }
        ];
      };
    };
  };
}
