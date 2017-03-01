unit Properties;

interface

Uses NovusXMLBO, Classes, SysUtils, XMLlist, Project, Output;

Type
  tProperties = class(TXMLlist)
  protected
  private
    foProject: tProject;
    FoOutput: TOutput;
  public
    function IsPropertyExists(APropertyName: String): Boolean;
    function GetProperty(APropertyName: String): String;
    function DoPluginProperty(APropertyName: string): string;

    property oProject: tProject
      read foProject
      write foProject;

    property oOutput: TOutput
      read FoOutput
      write FoOutput;
  end;

implementation

uses Runtime, Plugin;


function tProperties.GetProperty(APropertyName: String): String;
var
  lsGetProperty: String;
begin
  lsGetProperty := GetFieldAsString(oXMLDocument.Root, APropertyName);
  Try
    if foProject.oProjectConfig.IsLoaded then
      lsGetProperty := foProject.oProjectConfig.Parseproperties(lsGetProperty);

  Except
    FoOutput.Writelog(APropertyName + ' Projectconfig error.');
  End;

  Result := lsGetProperty;
end;


function tProperties.DoPluginProperty(APropertyName: string): string;
var
  loPlugin: TPlugin;
  I: Integer;
begin
   for I := 0 to oRuntime.oPlugins.PluginsList.Count -1 do
    begin
      loPlugin := TPlugin(oRuntime.oPlugins.PluginsList.Items[i]);

    end;
end;

function tProperties.IsPropertyExists(APropertyName: String): Boolean;
Var
  I: integer;
begin
  Result := False;

  for i := 0 to NodeNames.Count - 1 do
    begin
      If Uppercase(NodeNames.Strings[i]) = Uppercase(APropertyName) then
        begin
          Result := True;

          Exit;
        end;
    end;
end;

end.
