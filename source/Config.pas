unit Config;

interface

Uses SysUtils, NovusXMLBO, Registry, Windows, NovusStringUtils, NovusFileUtils,
     JvSimpleXml, NovusSimpleXML, NovusList, Properties;


Const
  csOutputFile = 'Output.log';
  csConfigfile = 'zcodegen.config';

Type
   TConfigPlugins = class(Tobject)
   private
     fsPluginName: String;
     fsPluginFilename: string;
     fsPluginFilenamePathname: String;
     foProperties: tProperties;
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

     property oProperties: tProperties
       read foProperties
       write foProperties;
   end;


   TConfig = Class(TNovusXMLBO)
   protected
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
   End;

Var
  oConfig: tConfig;

implementation

constructor TConfig.Create;
begin
  inherited Create;

  fConfigPluginsList := tNovusList.Create(TConfigPlugins);
end;

destructor TConfig.Destroy;
begin
  fConfigPluginsList.Free;

  inherited Destroy;
end;

function TConfig.ParseParams: Boolean;
Var
  I: integer;
  fbOK: Boolean;
begin
  Result := False;

  fbOK := false;
  I := 1;
  While Not fbOK do
    begin
        if ParamStr(i) = '-project' then
         begin
           Inc(i);
           fsProjectFileName := ParamStr(i);

           if Not FileExists(fsProjectFileName) then
              begin
                writeln ('-project ' + TNovusStringUtils.JustFilename(fsProjectFileName) + ' project filename cannot be found.');

                Exit;
              end;

           Result := True;
         end
        else
        if ParamStr(i) = '-projectconfig' then
          begin
            Inc(i);
            fsProjectConfigFileName := ParamStr(i);

            if Not FileExists(fsProjectConfigFileName) then
              begin
                writeln ('-projectconfig ' + TNovusStringUtils.JustFilename(fsProjectConfigFileName) + ' projectconfig filename cannot be found.');

                Exit;
              end;

           Result := True;
         end;

      Inc(I);

      if I > ParamCount then fbOK := True;
    end;

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


  if Result = false then
    begin
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
                 loConfigPlugins.oProperties.oXMLDocument.Root := TJvSimpleXMLElemClassic(fPluginProperties);

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
  foProperties:= tProperties.Create;
end;

destructor TConfigPlugins.Destroy;
begin
  foProperties.oXMLDocument.Root := nil;

  foProperties.Free;
end;


Initialization
  oConfig := tConfig.Create;

finalization
  oConfig.Free;

end.
