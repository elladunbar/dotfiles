{ pkgs, ... }:
let
  flatwhite-theme = pkgs.vimUtils.buildVimPlugin {
    name = "flatwhite-theme";
    src = pkgs.fetchFromGitHub {
      owner = "elladunbar";
      repo = "flatwhite-theme";
      rev = "962a88c9bcfcc8afd0b7213064413b45b650b955";
      hash = "sha256-68Bx2SX3hKxSBBCfBTQwUXbsNwcW/IV6LFmf62X9ffY=";
    };
  };
in
{
  home.username = "ella";
  home.homeDirectory = "/home/ella";

  home.sessionVariables = {
    EDITOR = "nvim";
    SUDO_EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  home.shell.enableShellIntegration = true;

  home.packages = with pkgs; [
    # standard utils
    file
    gawk
    gnupg
    gnused
    which

    # new utils
    bat
    eza
    fzf
    jq
    ripgrep
    fd
    fastfetch

    # networking tools
    nmap

    # monitoring
    btop
    pciutils
    lshw
    ethtool

    # LSPs
    nixd

    # remote x11
    firefox-bin
    xeyes
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellOptions = [ "checkwinsize" "histappend" "cmdhist" ];
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 50000;
    historyFileSize = 1000000;
    sessionVariables = {
      HISTTIMEFORMAT = "%Y-%m-%d %H:%M:%S ";
    };
    initExtra = "set -o vi";
  };

  programs.fish = {
    enable = true;

    shellInit = 
    # fish
    ''
      set -g fish_greeting ""
    '';

    interactiveShellInit = 
    # fish
    ''
      fish_vi_key_bindings

      function fish_mode_prompt
        switch $fish_bind_mode
          case default
            set_color brcyan
            echo ""
            set_color --background brcyan
            set_color black
            echo ""
            set_color --background bryellow
            set_color brcyan
            echo ""
          case insert
            set_color brblue
            echo ""
            set_color --background brblue
            set_color black
            echo ""
            set_color --background bryellow
            set_color brblue
            echo ""
          case replace_one
            set_color brred
            echo ""
            set_color --background brred
            set_color black
            echo ""
            set_color --background bryellow
            set_color brred
            echo ""
          case replace
            set_color brred
            echo ""
            set_color --background brred
            set_color black
            echo ""
            set_color --background bryellow
            set_color brred
            echo ""
          case visual
            set_color magenta
            echo ""
            set_color --background magenta
            set_color black
            echo ""
            set_color --background bryellow
            set_color magenta
            echo ""
          case '*'
        end
        set_color normal
      end
    '';

    shellAbbrs = {
      # file management
      ",cpdirs" = "rsync --archive --include='*/' --exclude '*'";
      ",rs" = "rsync --archive --compress --human-readable --progress";
      la = "eza --all --hyperlink";
      ll = "eza --all --long --icons=auto --git --hyperlink";
      ls = "eza --hyperlink";
      tree = "eza --tree --icons=auto --hyperlink";

      # misc
      ",ad" = "cd; and clear";
      ",g" = "git";
      batp = "bat --plain";
      neofetch = "fastfetch --config neofetch.jsonc";
    };

    functions = {
      # file management
      ",cl" = {
        body = "cd $argv[1]; and eza --hyperlink";
      };
      ",mkcd" = {
        body = "mkdir -p $argv[1]; and cd $argv[1]";
      };
      ",mksh" = {
        body = "touch $argv[1]; and chmod +x $argv[1]; and echo '#!/' >> $argv[1]; and $EDITOR $argv[1]";
      };

      # file viewers
      ",csv" = {
        body = "column -s, -t < $argv[1] | less -#2 -N -S";
      };
      ",json" = {
        body = 
        # fish
        ''
          if test (count $argv) -eq 0
            set -f file /dev/stdin
          else if test (count $argv) -eq 1
            set -f file $argv[1]
          end

          jq '.' $file | bat --plain --language=json
        '';
      };
      ",vm" = {
        body = "pandoc -s -t man $argv[1] | man -l -";
      };

      # misc
      ",h" = {
        body = "$argv --help | bat --plain --language=help";
      };
      ",sz" = {
        body = "du -h -d 1 $argv | sort --human-numeric-sort --reverse";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    tmux.enableShellIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      alias = {
        a = "add";
        aa = "add .";
        b = "branch";
        c = "commit";
        ca = "commit -a";
        cam = "commit -am";
        cl = "clone";
        cm = "commit -m";
        co = "checkout";
        db = "diff HEAD^ HEAD";
        fgt = "update-index --skip-worktree";
        lg = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(auto)%s%C(reset) %C(dim black)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
        pl = "pull";
        ps = "push";
        s = "status";
        sw = "switch";
      };
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      core.pager = "bat --style plain";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      fetch = {
        fsckobjects = true;
        prune = true;
        pruneTags = true;
        all = true;
      };
      help.autocorrect = "prompt";
      init.defaultBranch = "main";
      merge = {
        conflictstyle = "zdiff3";
        tool = "nvimdiff";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      receive.fsckobjects = true;
      rerere = {
        autoupdate = true;
        enabled = true;
      };
      tag.sort = "version:refname";
      transfer.fsckobjects = true;
      user = {
        name = "Ella Dunbar";
        email = "git@elladunbar.com";
      };
    };

    lfs.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    initLua = 
    # lua
    ''
      -- OPTS --
      local opt = vim.opt

      -- Context
      opt.number = true
      opt.relativenumber = true
      opt.scrolloff = 4
      opt.showmode = false

      -- Filetypes
      opt.encoding = "utf8"
      opt.fileencoding = "utf8"

      -- Theme
      opt.syntax = "ON"
      opt.termguicolors = true
      opt.winborder = "none"

      -- Search
      opt.ignorecase = true
      opt.smartcase = true

      -- Whitespace
      opt.expandtab = true
      opt.shiftwidth = 2
      opt.softtabstop = 2
      opt.tabstop = 2
      opt.list = true

      -- VARS --
      local g = vim.g
      g.t_co = 256
      g.mapleader = ' '

      -- USER --
      -- Global Variables
      LSP_SERVERS = {}

      -- Settings
      vim.diagnostic.config({ virtual_lines = true })

      -- Functions
      function REGISTER_SERVER(server_name)
        return function(_, bufnr)
          LSP_SERVERS[bufnr] = LSP_SERVERS[bufnr] or {}
          LSP_SERVERS[bufnr][server_name] = true
        end
      end

      -- BACKGROUND --
      vim.g.background = "light"
      vim.o.background = "light"
    '';
    plugins = with pkgs.vimPlugins; [
      cmp-buffer
      cmp-nvim-lsp
      cmp_luasnip
      cmp-path
      {
        plugin = flatwhite-theme;
        type = "lua";
        config = ''
          if vim.o.background == "light" then
            COLOR_THEME = "flatwhite"
          else
            COLOR_THEME = "flatdark"
          end
          vim.cmd.colorscheme(COLOR_THEME)
        '';
      }
      {
        plugin = friendly-snippets;
        type = "lua";
        config = ''
          require("luasnip.loaders.from_vscode").lazy_load()
        '';
      }
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = ''
          require("ibl").setup({ scope = { show_start = false, show_end = false } })
        '';
      }
      lspkind-nvim
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          local function current_servers()
            local servers = LSP_SERVERS[vim.api.nvim_get_current_buf()] or {}
            local current = ""
            local num_servers = 0
            for server, loaded in pairs(servers) do
              if loaded then
                current = current .. " " .. server
                num_servers = num_servers + 1
              end
            end

            if num_servers ~= 0 then
              current = "󰒋" .. current
            end

            return current
          end

          require("lualine").setup({
            options = {
              theme = COLOR_THEME,
              component_separators = { left = "", right = "" },
              section_separators = { left = "", right = "" },
              always_divide_middle = false,
              globalstatus = true,
            },
            sections = {
              lualine_a = {
                { "mode", separator = { left = "", right = "" } },
              },
              lualine_b = { "branch", "diff", "diagnostics" },
              lualine_c = { current_servers },
              lualine_x = { "encoding", "fileformat", "filetype" },
              lualine_y = { "progress" },
              lualine_z = {
                { "location", separator = { left = "", right = "" } },
              },
            },
            tabline = {
              lualine_a = {
                {
                  "buffers",
                  separator = { left = "", right = "" },
                  buffers_color = { inactive = "lualine_b_normal" },
                  symbols = { alternate_file = "󰤖 " },
                },
              },
              lualine_z = {
                {
                  "tabs",
                  separator = { left = "", right = "" },
                  tabs_color = { inactive = "lualine_b_normal" },
                  symbols = { modified = " ●" },
                },
              },
            },
            extensions = { "man", "quickfix", "symbols-outline" },
          })
        '';
      }
      {
        plugin = luasnip;
        type = "lua";
        config = ''
          require("luasnip").setup({ history = true, delete_check_events = "TextChanged" })
        '';
      }
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require("cmp")
          local lspkind = require("lspkind")
          local luasnip = require("luasnip")

          local has_words_before = function()
            unpack = unpack or table.unpack
            local line, col = unpack(vim.api.nvim_win_get_cursor(0))
            return col ~= 0
              and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
          end

          cmp.setup({
            completion = {
              completeopt = "menu,menuone,noselect,noinsert",
            },
            snippet = {
              expand = function(args)
                require("luasnip").lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
                -- that way you will only jump inside the snippet region
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                elseif has_words_before() then
                  cmp.complete()
                else
                  fallback()
                end
              end, { "i", "s" }),

              -- make it so return without selecting just goes to next line
              ["<CR>"] = cmp.mapping({
                i = function(fallback)
                  if cmp.visible() and cmp.get_active_entry() then
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                  else
                    fallback()
                  end
                end,
                s = cmp.mapping.confirm({ select = true }),
                c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
              }),
            }),
            preselect = cmp.PreselectMode.None,
            sources = cmp.config.sources({
              {
                name = "nvim_lsp",

                -- filter out "text" sources
                entry_filter = function(entry, _)
                  return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Text"
                end,
              },
              { name = "luasnip" },
              { name = "path" },
            }, {
              { name = "buffer" },
            }),
            view = {
              docs = {
                auto_open = true,
              },
            },
            sorting = {
              comparators = {
                cmp.config.compare.offset,
                cmp.config.compare.exact,
                cmp.config.compare.recently_used,
                cmp.config.compare.kind,
                cmp.config.compare.sort_text,
                cmp.config.compare.length,
                cmp.config.compare.order,
              },
            },
            formatting = {
              format = lspkind.cmp_format({
                mode = "symbol_text",
                menu = {
                  buffer = "[buf]",
                  nvim_lsp = "[LSP]",
                  nvim_lua = "[api]",
                  path = "[path]",
                  luasnip = "[snip]",
                },
              }),
            },
            window = {
              documentation = {
                max_width = 0,
                max_height = 0,
              },
            },
            experimental = {
              native_menu = false,
              ghost_text = false,
            },
          })
        '';
      }
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          local cmp_nvim_lsp = require("cmp_nvim_lsp")
          local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_nvim_lsp.default_capabilities()
          )

          local servers = {
            "nixd"
          }
          for _, server in ipairs(servers) do
            vim.lsp.config(server, {
              capabilities = capabilities,
              on_attach = REGISTER_SERVER(server),
            })
            vim.lsp.enable(server)
          end
        '';
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          local filetypes = {
            "bash",
            "css",
            "fish",
            "gitcommit",
            "gitignore",
            "html",
            "json",
            "lua",
            "markdown",
            "markdown_inline",
            "nix",
            "vim",
            "vimdoc",
          }
          require("nvim-treesitter").install(filetypes)

          for _, filetype in ipairs(filetypes) do
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { filetype },
              callback = function()
                vim.treesitter.start()
                vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[0][0].foldmethod = "expr"
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end,
            })
          end
        '';
      }
      nvim-web-devicons
      plenary-nvim
      telescope-nvim
      {
        plugin = telescope-fzf-native-nvim;
        type = "lua";
        config = ''
          require("telescope").load_extension("fzf")
        '';
      }
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          vim.o.timeout = true
          vim.o.timeoutlen = 300

          require("which-key").setup({
            spec = {
              -- buffers
              {
                "<leader>b",
                group = "buffers",
                expand = function()
                  return require("which-key.extras").expand.buf()
                end
              },
              { "<leader>bn", "<cmd>bn<cr>", desc = "Jump to next buffer" },
              { "<leader>bp", "<cmd>bp<cr>", desc = "Jump to previous buffer" },
              { "<leader>bx", "<cmd>bd<cr>", desc = "Close current buffer" },

              -- telescope
              { "<leader>f", group = "telescope" },
              {
                "<leader>fb",
                function()
                  return require("telescope.builtin").buffers()
                end,
                desc = "Open buffers",
              },
              {
                "<leader>fc",
                function()
                  return require("telescope.builtin").commands()
                end,
                desc = "Available commands",
              },
              {
                "<leader>ff",
                function()
                  return require("telescope.builtin").find_files()
                end,
                desc = "Find files",
              },
              {
                "<leader>fg",
                function()
                  return require("telescope.builtin").live_grep()
                end,
                desc = "Live grep",
              },
              {
                "<leader>fk",
                function()
                  return require("telescope.builtin").man_pages()
                end,
                desc = "Manpage entries",
              },
              {
                "<leader>ft",
                function()
                  return require("telescope.builtin").treesitter()
                end,
                desc = "Treesitter locals",
              },

              -- misc
              { "<leader>h", "<cmd>nohlsearch<cr>", desc = "Remove match highlighting" },

              -- windows
              { "<leader>w", proxy = "<c-w>", group = "windows" },
            },
          })
        '';
      }
    ];
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "ginkgo" = {
        hostname = "ginkgo.nodes.elladunbar.com";
        user = "ella";
        port = 17227;
      };
      "pine" = {
        hostname = "pine.nodes.elladunbar.com";
        user = "ella";
        port = 17227;
      };
      "*" = {
        compression = true;
        extraOptions = { VisualHostKey = "yes"; };
      };
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;

      format = "[  ](fg:black bg:bright-yellow)$directory[](fg:bright-yellow bg:bright-purple)$git_branch$git_status[](fg:bright-purple bg:bright-green)\${custom.python}[](fg:bright-green) ";

      continuation_prompt = "[](fg:bright-yellow) ";

      directory = {
        style = "fg:black bg:bright-yellow";
        format = "[$path]($style)";
        truncation_length = 1;
      };

      git_branch = {
        symbol = "  ";
        style = "fg:black bg:bright-purple";
        format = "[$symbol$branch]($style)";
      };

      git_status = {
        style = "fg:black bg:bright-purple";
        format = "[$staged$deleted$modified]($style)";
        staged = " +$count";
        deleted = " -$count";
        modified = " ~$count";
      };

      custom.python = {
        command = "if [ -z \"$VIRTUAL_ENV\" ]; then echo \"\\$\"; else echo \" \"; fi";
        when = true;
        shell = [ "${pkgs.dash}/bin/dash" ];
        unsafe_no_escape = true;
        style = "fg:black bg:bright-green";
        format = "[ $output]($style)";
      };
    };
  };

  programs.tmux = {
    enable = true;

    shortcut = "space";
    escapeTime = 0;
    focusEvents = true;
    mouse = true;
    historyLimit = 100000;
    shell = "${pkgs.fish}/bin/fish";
    baseIndex = 1;

    clock24 = true;
    disableConfirmationPrompt = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      tmux-fzf
      vim-tmux-navigator
    ];

    extraConfig = 
    # tmux
    ''
      set -g extended-keys on
      set -g extended-keys-format csi-u

      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",*:RGB"
      set -ga terminal-overrides ",*:Tc"

      set -g allow-passthrough on

      set -g renumber-windows on

      set-option -g status-left "#[bg=default,fg=black]#[bg=black,fg=white] #S #[bg=default,fg=black]#[default] "
      set-option -g status-right "#[bg=default,fg=black]#[bg=black,fg=white] %H:%M #[bg=black,fg=yellow]#[bg=yellow,fg=white] #h #[bg=default,fg=yellow]"

      set-option -g status-style bg=default

      set-option -g display-time 1000
    '';
  };


  home.stateVersion = "25.05";
}
