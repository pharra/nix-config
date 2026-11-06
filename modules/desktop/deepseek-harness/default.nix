# DeepSeek Harness Web UI（dsh web）的常驻用户服务。
#
# 为什么是 user service：
#   dsh 的 profile、会话、凭据都在 $HOME/.dsh 下，必须以普通用户身份运行；
#   zed 的 wf 用户由 services.pharra.user-group 打开了 linger，
#   所以这个 user unit 在开机时就随 user manager 启动，不用等图形登录。
#
# 默认只监听回环地址（http://127.0.0.1:3080），与手动执行 `dsh web` 的行为一致。
# 要从局域网访问就改 host —— dsh 拒绝 0.0.0.0/:: 这类通配地址，只能写某一个具体地址；
# 纯 HTTP 绑定非回环地址时 dsh 会在启动日志里告警，安全的做法是走反向代理 + --trusted-host。
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.deepseek-harness;

  # systemd 的 ExecStart 由 systemd 自己解析引号，escapeShellArgs 生成的写法它认。
  dshArgs =
    [
      "web"
      "--no-open" # 服务里没有浏览器可开；需要时由用户自己访问下面的 URL
      "--host"
      cfg.host
      "--port"
      (toString cfg.port)
    ]
    ++ cfg.extraArgs;
in {
  options.services.pharra.deepseek-harness = {
    enable = mkEnableOption "DeepSeek Harness Web UI 用户服务（dsh web）";

    package = mkPackageOption pkgs "deepseek-harness" {};

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "192.168.31.2";
      description = ''
        监听地址，必须是本机某个接口的具体地址（dsh 不接受 0.0.0.0 / ::）。
        默认 127.0.0.1，即只有本机能访问。
      '';
    };

    port = mkOption {
      type = types.port;
      default = 3080;
      description = "监听端口；默认与手动执行 dsh web 相同（3080）。";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "--trusted-host"
        "dsh.example.com"
        "--public-url"
        "https://dsh.example.com"
      ];
      description = ''
        追加给 `dsh web` 的参数，例如 --public-url / --trusted-host / --tls-cert / --tls-key。
        需要把这些值原样传给 dsh，本模块不解析它们的含义。
      '';
    };
  };

  config = mkIf cfg.enable {
    # 服务用绝对路径启动，这一条只是让命令行里也能直接用 dsh；
    # 与 core/desktop 里已有的同路径安装重复时，buildEnv 会指向同一个 store 路径。
    environment.systemPackages = [cfg.package];

    systemd.user.services.dsh-web = {
      description = "DeepSeek Harness Web UI";
      wantedBy = ["default.target"];
      after = ["network.target"];

      # NixOS 给 user unit 的默认 PATH 只有 coreutils/findutils/grep/sed/systemd，
      # 而 dsh 会用 PATH 去跑 agent 的工具（git、node、用户自己的脚本……）。
      # 关掉默认值，改用和登录 shell 一致的路径（per-user profile + 系统 profile + wrappers）。
      enableDefaultPath = false;
      environment.PATH = concatStringsSep ":" [
        "/run/wrappers/bin"
        "/etc/profiles/per-user/${username}/bin"
        "/nix/var/nix/profiles/default/bin"
        "/run/current-system/sw/bin"
      ];

      serviceConfig = {
        Type = "simple";
        # 家目录既是 dsh 读取 $HOME/.dsh 的地方，也是 agent 的默认工作区。
        WorkingDirectory = "%h";
        ExecStart = "${getExe cfg.package} ${escapeShellArgs dshArgs}";
        Restart = "on-failure";
        RestartSec = 5;
        # 退出时留时间把会话落盘。
        TimeoutStopSec = 20;
      };
    };
  };
}
