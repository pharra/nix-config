self: super: {
  ksmbd-tools = super.ksmbd-tools.overrideAttrs (oldAttrs: rec {
    configureFlags = (super.configureFlags or []) ++ ["--with-rundir=/run" "--sysconfdir=/etc"];
    patches = [./etc.patch];
  });
}
