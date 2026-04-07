{ config, ... }:
let
  blueskyPdsSettings = config.services.bluesky-pds.settings;
  forgejoSettings = config.services.forgejo.settings.server;
  immichSettings = config.services.immich;
  llamacppSettings = config.services.llama-cpp;
in
{
  # needed to access unix sockets
  systemd.services.nginx.serviceConfig.ProtectHome = false;

  services.nginx = {
    enable = true;

    # easy anubis upstream
    # upstreams = {
    #   anubis-forgejo.servers = { "unix:/run/anubis/anubis-forgejo.sock" = {}; };
    # };

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
          proxyPass = "http://localhost:${toString immichSettings.port}";
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
          proxyPass = "http://${llamacppSettings.host}:${toString llamacppSettings.port}";
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
