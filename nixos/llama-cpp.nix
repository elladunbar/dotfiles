{ pkgs, ... }:

{
  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    extraFlags = [
      "--flash-attn" "on"
      "--fit" "on"
      "--fit-target" "512"
      "--no-mmap"
      "--parallel" "4"
      "--kv-unified"
      "--cache-type-k" "bf16"
      "--cache-type-v" "q4_1"
      "--jinja"
    ];
    package = (pkgs.llama-cpp.override { cudaSupport = true; });
  };
}
