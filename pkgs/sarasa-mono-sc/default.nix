# Sarasa Mono SC（更纱黑体 等宽 简体中文）：终端友好的 CJK 等宽字体。
#
# 为什么不用 nixpkgs 的 sarasa-gothic：那个包只装了**比例版**（Sarasa-*.ttc），
# 比例版的拉丁字符宽度不与 CJK 对齐，在终端里会错位。Mono 版是 1:2 严格等宽，
# 中英文混排才对齐。上游把 Mono 版单独发布成 SarasaMono<Lang>-TTF-<ver>.7z。
{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  installFonts,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sarasa-mono-sc";
  version = "1.0.42";

  src = fetchurl {
    url = "https://github.com/be5invis/Sarasa-Gothic/releases/download/v${finalAttrs.version}/SarasaMonoSC-TTF-${finalAttrs.version}.7z";
    hash = "sha256-qiFQ6Z6zjF+dOgD+WOP5Cp2JSVx5WorICTTRw+bDd+4=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [
    p7zip
    installFonts
  ];

  meta = {
    description = "Sarasa Mono SC — CJK 等宽编程字体（终端用）";
    homepage = "https://github.com/be5invis/Sarasa-Gothic";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
