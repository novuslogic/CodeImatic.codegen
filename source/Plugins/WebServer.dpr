{$define ShareMM}
{$define ShareMMIfLibrary}
{$define AttemptToUseSharedMM}

library WebServer;

uses
  FastMM4,
  System.SysUtils,
  System.Classes,
  Plugin_WebServerClasses in 'Plugin_WebServerClasses.pas',
  Plugin_WebServerEngine in 'Plugin_WebServerEngine.pas',
  NovusWebUtils in '..\..\..\NovuscodeLibrary\Source\Core\Utilities\NovusWebUtils.pas';

{$R *.res}

begin
end.
