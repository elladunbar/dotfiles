{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      # onnxruntime only builds its LLM/MoE CUDA kernels for SM75+, but the CUDA
      # provider references their host-side symbols unconditionally. With only
      # sm_61 (GTX 1070) the provider fails to load with an undefined
      # MoeGemmRunner symbol and immich falls back to a broken OpenVINO device.
      # Compiling that library as compute_75 PTX supplies the symbols; immich
      # never runs those kernels.
      #
      # nccl is only for multi-GPU, and the OpenVINO provider crashes on this
      # machine, so both are left out.
      onnxruntime = (prev.onnxruntime.override {
        cudaSupport = true;
        ncclSupport = false;
        openvinoSupport = false;
      }).overrideAttrs (old: {
        postPatch = old.postPatch + ''
          substituteInPlace cmake/onnxruntime_providers_cuda.cmake --replace-fail \
            'onnxruntime_filter_cuda_archs(_ort_llm_cuda_architectures MIN_SM 75 EXCLUDE_SM120_REAL)' \
            'onnxruntime_filter_cuda_archs(_ort_llm_cuda_architectures MIN_SM 75 EXCLUDE_SM120_REAL)
          if(NOT _ort_llm_cuda_architectures)
            set(_ort_llm_cuda_architectures "75-virtual")
          endif()'
        '';
      });
    })
  ];

  users.users.immich.extraGroups = [ "render" "video" ];

  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;

    # enables access to all devices
    accelerationDevices = null;

    database = {
      enable = true;
      createDB = true;
    };

    settings.server = {
      externalDomain = "https://photos.elladunbar.com";
      loginPageMessage = "Welcome to Ella Dunbar's self-hosted photo storage!";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /var/cache/immich/matplotlib 0700 immich immich -"
    ];
    services = {
      immich-machine-learning = {
        environment = {
          MPLCONFIGDIR = "/var/cache/immich/matplotlib";
        };
      };
    };
  };
}
