program Zcodegen;

{$APPTYPE CONSOLE}

uses
  Forms,
  Config in 'Config.pas',
  DMZenCodeGen in 'DMZenCodeGen.pas' {DM: TDataModule},
  DBSchema in 'DBSchema.pas',
  Properties in 'Properties.pas',
  CodeGenerator in 'CodeGenerator.pas',
  Interpreter in 'Interpreter.pas',
  Language in 'Language.pas',
  MessagesLog in 'MessagesLog.pas',
  Variables in 'Variables.pas',
  Project in 'Project.pas',
  Reservelist in 'Reservelist.pas',
  XMLList in 'XMLList.pas',
  projectconfig in 'projectconfig.pas',
  EParser in '3rdParty\EParser.pas';

{$R *.res}

begin
  oConfig.LoadConfig;

  If Not oConfig.ParseParams then Exit;

  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.Run;
end.
