{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.audio-relay;
in {
  options.services.audio-relay = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.audio-relay;
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    services.pipewire.configPackages = lib.mkIf (config.services.pipewire.enable == true) [
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/10-audiorelay-virtual-speaker-sink.conf" ''
        context.modules = [
        {   name = libpipewire-module-loopback
            args = {
              node.description = "Audio-Relay-Speaker"
              capture.props = {
                  media.class=Audio/Sink
                  audio.position = [ FL FR ]
                  stream.dont-remix = true
                  node.name=audiorelay-speaker
              }
            }
        }
        ]
      '')
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/10-audiorelay-virtual-mic-sink.conf" ''
        context.modules = [
        {   name = libpipewire-module-loopback
            args = {
              node.description = "Audio-Relay-Mic"
              capture.props = {
                  media.class=Audio/Sink
                  audio.position = [ FL FR ]
                  stream.dont-remix = true
                  node.name=audiorelay-mic-sink
              }
              playback.props = {
                  media.class=Audio/Source
                  audio.position = [ FL FR ]
                  target.object=audiorelay-mic-sink
                  node.name=audiorelay-mic
              }
            }
        }
        ]
      '')
    ];
  };
}
