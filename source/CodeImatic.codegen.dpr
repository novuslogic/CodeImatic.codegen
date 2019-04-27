{$I CodeImatic.codegen.inc}
program CodeImatic.codegen;

{$APPTYPE CONSOLE}

uses
  FastMM4,
  System.SysUtils,
  Config,
  output,
  runtime,
  project,
  projectconfig,
  Language in 'Language.pas',
  Plugins in 'Plugins.pas',
  PluginsMapFactory in 'PluginsMapFactory.pas';

{$R *.res}


begin
  ExitCode := oConfig.LoadConfig;
  if ExitCode <> 0 then Exit;

  If Not oConfig.ParseParams then
    Exit;

  try
    ExitCode := oruntime.RunEnvironment;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
