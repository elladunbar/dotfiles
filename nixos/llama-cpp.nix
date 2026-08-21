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
      models-preset = (pkgs.formats.ini {}).generate "models-preset.ini" {
        "mradermacher/gemma-4-E4B" = {
          hf-repo = "mradermacher/gemma-4-E4B-it-i1-GGUF";
          hf-file = "gemma-4-E4B-it.i1-Q4_K_M.gguf";
          ctx-size = 32768;
          temp = 1.0;
          top-p = 0.95;
          top-k = 64;
        };
        "unsloth/Qwen3.5-4B" = {
          hf-repo = "unsloth/Qwen3.5-4B-GGUF";
          hf-file = "Qwen3.5-4B-UD-Q4_K_XL.gguf";
          chat-template-kwargs = "{\"enable_thinking\":true}";
          ctx-size = 32768;
          temp = 0.8;
          top-p = 0.95;
          top-k = 20;
          presence-penalty = 0.5;
          min-p = 0.0;
        };
        "unsloth/Qwen3.5-9B" = {
          hf-repo = "unsloth/Qwen3.5-9B-GGUF";
          hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
          chat-template-kwargs = "{\"enable_thinking\":true}";
          ctx-size = 32768;
          temp = 0.8;
          top-p = 0.95;
          top-k = 20;
          presence-penalty = 0.5;
          min-p = 0.0;
        };
      };
      host = "127.0.0.1";
      port = 8080;
      models-max = 1;
      flash-attn = "on";
      fit = "on";
      fit-target = 600;
      fit-ctx = 32768;
      load-mode = "none";
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
