unit Config;

interface

Uses SysUtils, NovusXMLBO, Registry, Windows, NovusStringUtils;

Const
  csMessageslogFile = 'Messages.log';

Type
   TConfig = Class(TNovusXMLBO)
   protected
      fsDBSchemaFileName: String;
      fsProjectConfigFileName: String;
      fsProjectFileName: String;
      fsRootPath: String;
      fsmessageslogFile: String;
      fsLanguagesDirectory: String;
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

      property MessageslogFile: String
        read fsMessageslogFile
        write fsMessageslogFile;

     property  RootPath: String
        read fsRootPath
        write fsRootPath;

     property DBSchemafilename: string
        read fsdbschemafilename
        write fsdbschemafilename;


     property Languagesdirectory: string
       read fslanguagesdirectory
       write fslanguagesdirectory;
   End;

Var
  oConfig: tConfig;

implementation

constructor TConfig.Create;
begin
  inherited Create;
end;

destructor TConfig.Destroy;
begin
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

           if Not DirectoryExists(TNovusStringUtils.JustPathname(fsProjectFileName)) then
              begin
                writeln ('-project ' + TNovusStringUtils.JustPathname(fsProjectFileName) + ' project filename cannot be found.');

                Exit;
              end;

           Result := True;
         end;

        if ParamStr(i) = '-projectconfig' then
         begin
           Inc(i);
           fsProjectConfigFileName := ParamStr(i);

           if Not DirectoryExists(TNovusStringUtils.JustPathname(fsProjectConfigFileName)) then
              begin
                writeln ('-projectconfig ' + TNovusStringUtils.JustPathname(fsProjectConfigFileName) + ' projectconfig filename cannot be found.');

                Exit;
              end;

           Result := True;
         end;

         if ParamStr(i) = '-dbschemafilename' then
         begin
           Inc(i);
           fsdbschemafilename := ParamStr(i);

           if Not DirectoryExists(TNovusStringUtils.JustPathname(fsProjectConfigFileName)) then
              begin
                writeln ('-dbschemafilename ' + TNovusStringUtils.JustPathname(fsProjectConfigFileName) + ' dbschema filrname cannot be found.');

                Exit;
              end;

           Result := True;
         end;

         if ParamStr(i) = '-languagesdirectory' then
         begin
           Inc(i);
           fslanguagesdirectory := ParamStr(i);

           if Not DirectoryExists(fslanguagesdirectory) then
              begin
                writeln ('-languagesdirectory ' + fslanguagesdirectory + ' languages directory cannot be found.');

                Exit;
              end;

           Result := True;
         end;



      Inc(I);

      if I > ParamCount then fbOK := True;
    end;

  if Result = false then
    begin
      writeln ('-error ');

      //
    end;

  fsmessageslogFile := csMessageslogFile;
end;

procedure TConfig.LoadConfig;
Var
  fhkey_local_machine : TRegistry;
begin
  (*
  fhkey_local_machine := TRegistry.Create;

  fhkey_local_machine.RootKey := HKEY_LOCAL_MACHINE;

  fhkey_local_machine.Access := KEY_ALL_ACCESS;

  if fhkey_local_machine.OpenKey(csDefaultInstance, false) then
    begin
      fsRootPath := fhkey_local_machine.ReadString('RootPath');
    end;

  fhkey_local_machine.CloseKey;

  fhkey_local_machine.Free;
  *)

  if fsRootPath = '' then
    fsRootPath := TNovusStringUtils.RootDirectory;

end;

Initialization
  oConfig := tConfig.Create;

finalization
  oConfig.Free;

end.
