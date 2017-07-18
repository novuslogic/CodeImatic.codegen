{$define ShareMM}
{$define ShareMMIfLibrary}
{$define AttemptToUseSharedMM}
library Sass;

uses
  FastMM4,
  System.SysUtils,
  System.Classes,
  Plugin_SassClasses in 'Plugin_SassClasses.pas',
  DelphiLibSass in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSass.pas',
  DelphiLibSassCommon in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSassCommon.pas',
  DelphiLibSassLib in '..\..\..\DelphiLibSass\Source\Core\DelphiLibSassLib.pas';

{$R *.res}

begin
end.
