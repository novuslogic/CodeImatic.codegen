{$I Zcodegen.inc}
program Zcodegen;

{$APPTYPE CONSOLE}

uses
  Sharemem,
  System.SysUtils,
  runtime,
  Config,
  output,
  DBSchema in 'DBSchema.pas',
  Properties in 'Properties.pas',
  CodeGenerator in 'CodeGenerator.pas',
  Interpreter in 'Interpreter.pas',
  Language in 'Language.pas',
  Variables in 'Variables.pas',
  Project in 'Project.pas',
  Reservelist in 'Reservelist.pas',
  XMLList in 'XMLList.pas',
  projectconfig in 'projectconfig.pas',
  Plugins in 'Plugins.pas',
  PluginsMapFactory in 'PluginsMapFactory.pas';

{$R *.res}

begin
  oConfig.LoadConfig;

  If Not oConfig.ParseParams then Exit;

  try
    oruntime.RunEnvironment;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
