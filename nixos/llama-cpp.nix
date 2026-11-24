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
      models-preset = (pkgs.formats.ini { }).generate "models-preset.ini" {
        "unsloth/gemma-4-E4B" = {
          hf-repo = "unsloth/gemma-4-E4B-it-qat-GGUF";
          hf-file = "gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf";
          spec-type = "draft-mtp";
          spec-draft-n-max = 2;
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
        # the same model without thinking, for mealie's recipe parsing and
        # imports (it can't send chat-template-kwargs itself). with thinking a
        # short recipe took ~200 s and came back with wrong quantities; without
        # it ~15 s and correct. sampling is qwen's instruct-mode setting for
        # general tasks
        "unsloth/Qwen3.5-9B-nothink" = {
          hf-repo = "unsloth/Qwen3.5-9B-GGUF";
          hf-file = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
          chat-template-kwargs = "{\"enable_thinking\":false}";
          ctx-size = 32768;
          temp = 0.7;
          top-p = 0.8;
          top-k = 20;
          presence-penalty = 1.5;
          min-p = 0.0;
        };
        # Qwen3.5-9B fine-tuned by Xiaomi for coding and agentic work. Only 8 of
        # its 32 layers use full attention, so the KV cache at 64k is ~1 GiB.
        "bartowski/MiMo-V2.6-Distill-Qwen-9B" = {
          hf-repo = "bartowski/MiMo-V2.6-Distill-Qwen-9B-GGUF";
          hf-file = "MiMo-V2.6-Distill-Qwen-9B-Q4_K_M.gguf";
          chat-template-kwargs = "{\"enable_thinking\":true}";
          ctx-size = 65536;
          temp = 0.6;
          top-p = 0.95;
          top-k = 20;
        };
        # Decision models for /v1/systemone. The server detects them from GGUF
        # metadata; they only prefill, so speculative decoding is turned off.
        "ggml-org/Kev-4B" = {
          hf-repo = "ggml-org/Kev-4B-GGUF";
          hf-file = "Kev-4B-Q8_0.gguf";
          spec-type = "none";
        };
        "ggml-org/lev" = {
          hf-repo = "ggml-org/lev-GGUF";
          hf-file = "lev-Q8_0.gguf";
          spec-type = "none";
        };
      };
      host = "127.0.0.1";
      port = 8080;
      ui-mcp-proxy = true;
      # the mcp proxy limits cors to localhost unless origins are listed, which
      # refuses the web ui through nginx (see nginx.nix). loopback clients like
      # mealie are still allowed
      cors-origins = "http://river-birch.nodes.elladunbar.com:5678";
      models-max = 1;
      flash-attn = "on";
      fit = "on";
      fit-target = 256;
      fit-ctx = 32768;
      load-mode = "none";
      parallel = 1;
      kv-unified = true;
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
      cache-type-k-draft = "f16";
      cache-type-v-draft = "f16";
      spec-default = true;
      jinja = true;
    };
    package = (
      pkgs.llama-cpp.override {
        cudaSupport = true;
      }
    );
  };
}
