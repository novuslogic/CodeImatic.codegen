unit Config;

interface

Uses SysUtils, NovusXMLBO, Registry, Windows, NovusStringUtils, NovusFileUtils,
     JvSimpleXml, NovusSimpleXML, NovusList, ConfigProperties, NovusEnvironment,
     Classes, VariablesCmdLine, CommandLine, NovusCommandLine;


Const
  csOutputLogFileName = 'codeimatic.codegen.log';
  csConfigfile = 'codeimatic.codegen.config';
  csConfigfileversion = 'codeimatic.codegen1.0';


Type
   TConfigPlugin = class(Tobject)
   private
     fsPluginName: String;
     fsPluginFilename: string;
     fsPluginFilenamePathname: String;
     foConfigProperties: tConfigProperties;
   protected
   public
     constructor Create(aRootProperties: TJvSimpleXmlElem);
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
     fiExitCode: integer;
     fbErrors: Boolean;
     fErrorMessages: TStringlist;
     fbConsoleOutputOnly: Boolean;
     fsOutputlogFilename: string;
     fsVarCmdLine: String;
     fVariablesCmdLine: tVariablesCmdLine;
     fConfigPluginList: tNovusList;
     fsDBSchemaFileName: String;
     fsProjectConfigFileName: String;
     fsProjectFileName: String;
     fsRootPath: String;
     fsLanguagesPath: String;
     fsConfigfile: string;
     fsworkingdirectory: String;


     function GetExitCode: integer;
     procedure SetExitCode(Value: integer);
     function GetErrors: Boolean;
     procedure SetErrors(Value: Boolean);
     function GetErrorMessages: TStringlist;
     procedure SetErrorMessages(Value: TStringlist);
   private
   public
     constructor Create; virtual; // override;
     destructor  Destroy; override;

     function LoadConfig(aCommandLineResult: INovusCommandLineResult): Integer;

     //function ParseParams: Boolean;

     procedure AddError(aErrorMessage: string; aExitCode: integer = 0);

     property ProjectFileName: String
       read fsProjectFileName
       write fsProjectFileName;

    // property ProjectConfigFileName: String
     //  read fsProjectConfigFileName
     ///  write fsProjectConfigFileName;

     property  RootPath: String
        read fsRootPath
        write fsRootPath;

     property Configfile: string
       read fsConfigfile
       write fsConfigfile;

  //   property DBSchemafilename: string
  //      read fsdbschemafilename
  //      write fsdbschemafilename;

     property LanguagesPath: string
       read fsLanguagesPath
       write fsLanguagesPath;

     property oConfigPluginList: tNovusList
       read fConfigPluginList
       write fConfigPluginList;

     property oVariablesCmdLine: tvariablesCmdLine
       read fVariablesCmdLine
       write fVariablesCmdLine;

     property OutputlogFilename: string
       read fsOutputlogFilename
       write fsOutputlogFilename;

     property ConsoleOutputOnly: boolean
        read fbConsoleOutputOnly
        write fbConsoleOutputOnly;

     property workingdirectory: String
       read fsworkingdirectory
       write fsworkingdirectory;

     property ExitCode: Integer read GetExitCode write SetExitCode;
     property Errors: Boolean read GetErrors write SetErrors;
     property ErrorMessages: TStringlist read GetErrorMessages
        write SetErrorMessages;
   End;

Var
  oConfig: tConfig;

implementation

constructor TConfig.Create;
begin
  inherited Create;

  fVariablesCmdLine:= tVariablesCmdLine.Create(NIL);

  fConfigPluginList := tNovusList.Create(TConfigPlugin);

  fErrorMessages:= TStringlist.Create;

  fsOutputlogFilename := csOutputLogFileName;
end;

destructor TConfig.Destroy;
begin
  fErrorMessages.Free;

  fConfigPluginList.Free;

  fVariablesCmdLine.Free;

  inherited Destroy;
end;

{
function TConfig.ParseParams: Boolean;
Var
  I: integer;
  fbOK: Boolean;
  lVarCmdLineStrList: TStringList;
begin
  Result := True;

  fsOutputlogFilename := csOutputFile;

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


  if FindCmdLineSwitch('outputlog', true) then
    FindCmdLineSwitch('outputlog', fsOutputlogFilename, True, [clstValueNextParam, clstValueAppended]);

  if FindCmdLineSwitch('workingdirectory', true) then
    FindCmdLineSwitch('workingdirectory', fsworkingdirectory, True, [clstValueNextParam, clstValueAppended]);

  ConsoleOutputOnly := False;
  if FindCmdLineSwitch('consoleoutputonly', true) then
     ConsoleOutputOnly := True;

  if Trim(fsProjectFileName) = '' then
    begin
      writeln ('-project filename cannot be found.');

      Result := false;
    end;

    (*
  if Trim(fsProjectConfigFileName) = '' then
     begin
       writeln ('-projectconfig filename cannot be found.');

       result := False;
     end;
   *)

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
end;
}

function  TConfig.LoadConfig(aCommandLineResult
  : INovusCommandLineResult): Integer;
Var
  fPluginCommandLine,
  fPluginCommand,
  fPluginProperties,
  fPluginFilename,
  fPluginCommandName,
  fPluginHelp,
  fPlugins: TJvSimpleXmlElem;
  i, Index, SubIndex: Integer;
  fsPluginName,
  fsPluginFilename: String;
  loConfigPlugin: TConfigPlugin;
  fsCommandName: string;
  fsHelp: string;
  fConfigElem: TJvSimpleXmlElem;
begin
  Result := 0;

  if fsRootPath = '' then
    fsRootPath := TNovusFileUtils.TrailingBackSlash(TNovusStringUtils.RootDirectory);
  fsConfigfile := fsRootPath + csConfigfile;
  if FileExists(fsConfigfile) then
    begin
      XMLFileName := fsRootPath + csConfigfile;
      Retrieve;
      Index := 0;
      fConfigElem := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'config', Index);
      if assigned(fConfigElem) then
        begin
          if TNovusSimpleXML.HasProperties(fConfigElem, 'version') = csConfigfileversion then
            begin
              Index := 0;
              fPlugins  := TNovusSimpleXML.FindNode(oXMLDocument.Root, 'plugins', Index);
              if Assigned(fPlugins) then
                 begin
                   For I := 0 to fPlugins.Items.count -1 do
                     begin
                       fsPluginName := fPlugins.Items[i].Name;
                       Index := 0;
                       fsPluginFilename := '';
                       fPluginFilename := TNovusSimpleXML.FindNode(fPlugins.Items[i], 'filename', Index);
                       if Assigned(fPluginFilename) then
                         fsPluginFilename := fPluginFilename.Value;
                       Index := 0;
                       fPluginProperties := TNovusSimpleXML.FindNode(fPlugins.Items[i], 'properties', Index);
                       loConfigPlugin := TConfigPlugin.Create(fPluginProperties);
                       loConfigPlugin.PluginName := fsPluginName;
                       loConfigPlugin.Pluginfilename := fsPluginfilename;
                       loConfigPlugin.PluginFilenamePathname := rootpath + 'plugins\'+ fsPluginfilename;
                       Index := 0;
                       fPluginCommandLine := TNovusSimpleXML.FindNode(fPlugins.Items[i], 'commandline', Index);
                       if Assigned(fPluginCommandLine) then
                         begin

                           Index := 0;
                           fPluginCommand := TNovusSimpleXML.FindNode(fPluginCommandLine, 'command', Index);
                           While(fPluginCommand <> NIL) do
                             begin
                               if Assigned(fPluginCommand) then
                                 begin
                                   SubIndex :=0;
                                   fPluginCommandName := TNovusSimpleXML.FindNode(fPluginCommand, 'commandname', SubIndex);
                                   if Assigned(fPluginCommandName) then
                                     fsCommandName := fPluginCommandName.Value;

                                   SubIndex :=0;
                                   fPluginHelp := TNovusSimpleXML.FindNode(fPluginCommand, 'help', SubIndex);
                                   if Assigned(fPluginHelp) then
                                     fsHelp := fPluginHelp.Value;


                                   fPluginCommand := TNovusSimpleXML.FindNode(fPluginCommandLine, 'command', Index);
                                 end;
                             end;

                         end;
                      fConfigPluginList.Add(loConfigPlugin);
                     end;
               end;
            end
          else
            begin
              aCommandLineResult.AddError(csConfigfile + ' is the wrong config file version [ '+ csConfigfileversion  + ']');
              aCommandLineResult.ExitCode := -1001;
              Result := aCommandLineResult.ExitCode;
            end;
        end
      else
        begin
          aCommandLineResult.AddError(csConfigfile + ' not a config file.', -1000);
          aCommandLineResult.ExitCode := -1000;
          Result := aCommandLineResult.ExitCode;
        end;
    end
  else
    begin
      aCommandLineResult.AddError(csConfigfile + ' not a config file.', -1000);
      aCommandLineResult.ExitCode := -1000;
      Result := aCommandLineResult.ExitCode;
    end;
end;


procedure TConfig.AddError(aErrorMessage: string; aExitCode: integer = 0);

begin
  fiExitCode := aExitCode;
  fbErrors := true;
  fErrorMessages.Add(aErrorMessage)
end;

function TConfig.GetErrors: Boolean;
begin
  result := fbErrors;
end;

procedure TConfig.SetErrors(Value: Boolean);
begin
  fbErrors := Value;
end;

function TConfig.GetExitCode: integer;
begin
  result := fiExitCode;
end;

procedure TConfig.SetExitCode(Value: integer);
begin
  fiExitCode := Value;
end;

function TConfig.GetErrorMessages: TStringlist;
begin
  result := fErrorMessages;
end;

procedure TConfig.SetErrorMessages(Value: TStringlist);
begin
  fErrorMessages := Value;
end;


constructor TConfigPlugin.Create;

begin

  foConfigProperties:= tConfigProperties.Create(aRootProperties);

end;


destructor TConfigPlugin.Destroy;
begin
  foConfigProperties.Free;
end;


Initialization
  oConfig := tConfig.Create;

finalization
  oConfig.Free;

end.
