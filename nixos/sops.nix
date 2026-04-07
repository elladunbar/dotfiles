{ ... }:

{
  # https://michael.stapelberg.ch/posts/2025-08-24-secret-management-with-sops-nix/
  sops.defaultSopsFile = ./secrets/default.yaml;
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  sops.secrets.forgejo-admin-password = {};
  sops.secrets.forgejo-runner-token = {};
}
