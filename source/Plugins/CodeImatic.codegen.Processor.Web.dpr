{.$define ShareMM}
{.$define ShareMMIfLibrary}
{.$define AttemptToUseSharedMM}
library CodeImatic.codegen.Processor.Web;

uses
  System.SysUtils,
  System.Classes,
  Plugin_WebProcessorClasses in 'Plugin_WebProcessorClasses.pas',
  DelphiLibSass in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSass.pas',
  DelphiLibSassCommon in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSassCommon.pas',
  DelphiLibSassLib in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSassLib.pas',
  MarkdownDaringFireball in 'MarkdownDaringFireball.pas',
  MarkdownProcessor in 'MarkdownProcessor.pas',
  SassProcessorItem in 'SassProcessorItem.pas',
  MarkdownProcessorItem in 'MarkdownProcessorItem.pas';

{$R *.res}

begin
end.
