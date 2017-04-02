unit Config;

interface

Uses SysUtils, NovusXMLBO, Registry, Windows, NovusStringUtils, NovusFileUtils,
     JvSimpleXml, NovusSimpleXML, NovusList, ConfigProperties, NovusEnvironment,
     Classes, VariablesCmdLine;


Const
  csOutputFile = 'Output.log';
  csConfigfile = 'zcodegen.config';

Type
   TConfigPlugins = class(Tobject)
   private
     fsPluginName: String;
     fsPluginFilename: string;
     fsPluginFilenamePathname: String;
     foConfigProperties: tConfigProperties;
   protected
   public
     constructor Create;
     destructor Destroy; override;

     property PluginName: String
       read fsPluginName
       write fsPluginName;

     property Pluginfilename: string
        read fsPluginfilename
        write fsPluginfilename;

     property PluginFilenamePathname: String
       read fsPluginFilenamePathname
       write fsPluginFilenamePathname;

     property oConfigProperties: tConfigProperties
       read foConfigProperties
       write foConfigProperties;
   end;


   TConfig = Class(TNovusXMLBO)
   protected
      fsVarCmdLine: String;
      fVariablesCmdLine: tVariablesCmdLine;
      fConfigPluginsList: tNovusList;
      fsDBSchemaFileName: String;
      fsProjectConfigFileName: String;
      fsProjectFileName: String;
      fsRootPath: String;
      fsOutputFile: String;
      fsLanguagesPath: String;
      fsConfigfile: string;
   private
   public
     constructor Create; virtual; // override;
     destructor  Destroy; override;

     procedure LoadConfig;

     function ParseParams: Boolean;

     property ProjectFileName: String
       read fsProjectFileName
       write fsProjectFileName;

     property ProjectConfigFileName: String
       read fsProjectConfigFileName
       write fsProjectConfigFileName;

      property OutputFile: String
        read fsOutputFile
        write fsOutputFile;

     property  RootPath: String
        read fsRootPath
        write fsRootPath;

     property Configfile: string
       read fsConfigfile
       write fsConfigfile;

     property DBSchemafilename: string
        read fsdbschemafilename
        write fsdbschemafilename;

     property LanguagesPath: string
       read fsLanguagesPath
       write fsLanguagesPath;

     property oConfigPluginsList: tNovusList
       read fConfigPluginsList
       write fConfigPluginsList;

     property oVariablesCmdLine: tvariablesCmdLine
       read fVariablesCmdLine
       write fVariablesCmdLine;

   End;

Var
  oConfig: tConfig;

implementation

constructor TConfig.Create;
begin
  inherited Create;

  fVariablesCmdLine:= tVariablesCmdLine.Create;

  fConfigPluginsList := tNovusList.Create(TConfigPlugins);
end;

destructor TConfig.Destroy;
begin
  fConfigPluginsList.Free;

  fVariablesCmdLine.Free;

  inherited Destroy;
end;

function TConfig.ParseParams: Boolean;
Var
  I: integer;
  fbOK: Boolean;
  lVarCmdLineStrList: TStringList;
begin
  Result := True;

  if FindCmdLineSwitch('project', true) then
    begin
      FindCmdLineSwitch('project', fsProjectFileName, True, [clstValueNextParam, clstValueAppended]);

      if Not FileExists(fsProjectFileName) then
        begin
          writeln ('-project ' + TNovusStringUtils.JustFilename(fsProjectFileName) + ' project filename cannot be found.');

          result := false;
        end;
    end
  else Result := false;

  if FindCmdLineSwitch('projectconfig', true) then
    begin
      FindCmdLineSwitch('projectconfig', fsProjectConfigFileName, True, [clstValueNextParam, clstValueAppended]);

      if Not FileExists(fsProjectConfigFileName) then
        begin
          writeln ('-projectconfig ' + TNovusStringUtils.JustFilename(fsProjectConfigFileName) + ' projectconfig filename cannot be found.');

          Result := False;
        end;
    end
  else Result := False;

   if Trim(fsProjectFileName) = '' then
    begin
      writeln ('-project filename cannot be found.');

      Result := false;
    end;

  if Trim(fsProjectConfigFileName) = '' then
     begin
       writeln ('-projectconfig filename cannot be found.');

       result := False;
     end;

  if Result = True then
     begin
      if FindCmdLineSwitch('var', true) then
        begin
          FindCmdLineSwitch('var', fsVarCmdLine, True, [clstValueNextParam, clstValueAppended]);

          Result := fVariablesCmdLine.AddVarCmdLine(fsVarCmdLine);
        end;
     end;

  if Result = false then
    begin
      if fVariablesCmdLine.Failed then
        writeln('-error: ' + fVariablesCmdLine.Error)
      else
        writeln ('-error ');

      //
    end;

  fsOutputFile := csOutputFile;
end;

procedure TConfig.LoadConfig;
Var
  fPluginProperties,
  fPluginElem,
  fPluginsElem: TJvSimpleXmlElem;
  i, Index: Integer;
  fsPluginName,
  fsPluginFilename: String;
  loConfigPlugins: TConfigPlugins;
begin
  if fsRootPath = '' then
    fsRootPath := TNovusFileUtils.TrailingBackSlash(TNovusStringUtils.RootDirectory);

  fsConfigfile := fsRootPath + csConfigfile;

  if FileExists(fsConfigfile) then
    begin
      XMLFileName := fsRootPath + csConfigfile;
      Retrieve;

      Index := 0;
      fPluginsElem  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'plugins', Index);
      if Assigned(fPluginsElem) then
         begin
           For I := 0 to fPluginsElem.Items.count -1 do
             begin
               loConfigPlugins := TConfigPlugins.Create;

               fsPluginName := fPluginsElem.Items[i].Name;

               Index := 0;
               fsPluginFilename := '';
               fPluginElem := TNovusSimpleXML.FindNode(fPluginsElem.Items[i], 'filename', Index);
               if Assigned(fPluginElem) then
                 fsPluginFilename := fPluginElem.Value;

               Index := 0;
               fPluginProperties := TNovusSimpleXML.FindNode(fPluginsElem.Items[i], 'properties', Index);
               if Assigned(fPluginProperties) then
                 loConfigPlugins.oConfigProperties.oProperties := fPluginProperties;

               loConfigPlugins.PluginName := fsPluginName;
               loConfigPlugins.Pluginfilename := fsPluginfilename;
               loConfigPlugins.PluginFilenamePathname := rootpath + 'plugins\'+ fsPluginfilename;


               fConfigPluginsList.Add(loConfigPlugins);
             end;
         end;
    end;
end;


constructor TConfigPlugins.Create;
begin
  foConfigProperties:= tConfigProperties.Create;
end;

destructor TConfigPlugins.Destroy;
begin
  foConfigProperties.Free;
end;


Initialization
  oConfig := tConfig.Create;

finalization
  oConfig.Free;

end.
