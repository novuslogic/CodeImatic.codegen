{$I Zcodegen.inc}
program Zcodegen;

{$APPTYPE CONSOLE}

uses
  Forms,
  SysUtils,
  Config in 'Config.pas',
  DBSchema in 'DBSchema.pas',
  Properties in 'Properties.pas',
  CodeGenerator in 'CodeGenerator.pas',
  Interpreter in 'Interpreter.pas',
  Language in 'Language.pas',
  Output in 'Output.pas',
  Variables in 'Variables.pas',
  Project in 'Project.pas',
  Reservelist in 'Reservelist.pas',
  XMLList in 'XMLList.pas',
  projectconfig in 'projectconfig.pas',
  EParser in '3rdParty\EParser.pas',
  Runtime in 'Runtime.pas',
  Plugins in 'Plugins.pas',
  Plugin in 'Plugin.pas',
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
