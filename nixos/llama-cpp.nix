{ pkgs, ... }:
# let
#   llama-cpp = pkgs.llama-cpp.overrideAttrs(attrs: rec {
#     version = "8806";
#     src = pkgs.fetchFromGitHub {
#       owner = "ggml-org";
#       repo = "llama.cpp";
#       tag = "b${version}";
#       hash = "sha256-tl2y+39f7dVW7FIUYVRAQyTFJixLcMN8fHmFSAEf7ww=";
#       leaveDotGit = true;
#       postFetch = ''
#         git -C "$out" rev-parse --short HEAD > $out/COMMIT
#         find "$out" -name .git -print0 | xargs -0 rm -rf
#       '';
#     };
#     npmDepsHash = "sha256-RAFtsbBGBjteCt5yXhrmHL39rIDJMCFBETgzId2eRRk=";
#     postPatch = "";
#     patches = [];
#   });
# in
{
  services.llama-cpp = {
    enable = true;
    settings = {
      models-preset = "/home/ella/.config/nixos/llama-cpp.ini";
      host = "127.0.0.1";
      port = 8080;
      models-max = 1;
      flash-attn = "on";
      fit = "on";
      fit-target = 512;
      fit-ctx = 65536;
      no-mmap = true;
      parallel = 1;
      kv-unified = true;
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
      cache-type-k-draft = "f16";
      cache-type-v-draft = "f16";
      tools = "get_datetime";
      spec-default = true;
      jinja = true;
    };
    package = (pkgs.llama-cpp.override {
      cudaSupport = true;
    });
  };
}
