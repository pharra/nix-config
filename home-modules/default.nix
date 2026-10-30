# Home Manager 模块清单（显式）：一行一项。开关统一在 home.pharra.* 下。
{
  autostart = import ./autostart;
  base = import ./base;
  cosmic = import ./cosmic;
  denial = import ./denial;
  desktop = import ./desktop;
  desktop-shell = import ./desktop-shell;
  gnome = import ./gnome;
  input-method = import ./input-method;
  kde = import ./kde;
  _template = import ./_template;
}
