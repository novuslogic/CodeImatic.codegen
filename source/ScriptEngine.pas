unit ScriptEngine;

interface

uses
  Output,
  System.Classes,
  System.SysUtils,
  uPSCompiler,
  uPSRuntime,
  uPSUtils,
  uPSPreProcessor;

type
   TScriptEngine = class
   private
     foOutput: toutput;
     FCompiler: TPSPascalCompiler;
     FsData: AnsiString;
     FExec: TPSExec;
     fImp: TPSRuntimeClassImporter;
   protected
     procedure RegisterFunctions(aExec: TPSExec);
     procedure CompilerOutputMessage;
     procedure SetVariantToClasses(aExec: TPSExec);
   public
     constructor Create(aOutput: TOutput);
     destructor Destroy;

     function ExecuteScript(aScript: String; aCompileOnly: boolean = false): boolean;

     property oImp: TPSRuntimeClassImporter
       read fImp
       write fImp;
   end;

implementation

uses Runtime, plugin;

constructor TScriptEngine.create;
begin
  foOutput:= aOutput;

  fImp := TPSRuntimeClassImporter.Create;
end;

destructor TScriptEngine.destroy;
begin
  fImp.Free;
end;

procedure OnException(Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring; ExObject: TObject; ProcNo, Position: Cardinal);
var
  lsExParam: String;
begin
  oruntime.oOutput.LastExError := ExError;


  lsExParam := ExParam;
  if ExParam = '' then lsExParam := 'Unknown error.';

  oruntime.oOutput.LastExParam := lsExParam;
  oruntime.oOutput.Errors := true;

end;

function CustomOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
Var
  lList: TStringList;
  FTPSCompileTimeClass: TPSCompileTimeClass;
begin
  if Name = 'SYSTEM' then
  begin
    Result := oruntime.oPlugins.CustomOnUses(Sender);
  end
  else
  begin
    if FileExists(oruntime.oProject.oProjectConfigLoader.SearchPath + name + '.pas')
    then
    begin
      Try
        Try
          oruntime.oOutput.Log('Compiling unit ... ' + name + '.pas');

          lList := TStringList.Create;
          lList.LoadFromFile(oruntime.oProject.oProjectConfigLoader.SearchPath + name
            + '.pas');

          if Sender.Compile(lList.Text) then
          begin
            Result := true;
          end
          else
          begin
            Result := False;
          end;
        Finally
          lList.Free;
        End;
      Except

      End;

    end
    else
    begin
      TPSPascalCompiler(Sender).MakeError('',
        ecUnitNotFoundOrContainsErrors, Name);

      Result := False;
    end;
   end;
end;


function TScriptEngine.ExecuteScript(aScript: String; aCompileOnly: boolean = false): boolean;
var
  liRetry, I: Integer;
  fbOK: Boolean;
  fbRetry: Boolean;
begin
  Result := false;

  FCompiler := TPSPascalCompiler.Create; // create an instance of the compiler.
  FCompiler.OnUses :=CustomOnUses; // assign the OnUses event.

  FCompiler.AllowNoBegin := True;
  FCompiler.AllowNoEnd := True; // AllowNoBegin and AllowNoEnd allows it that begin and end are not required in a script.

  foOutput.Log('Compiling ... ');

  if not FCompiler.Compile(aScript) then  // Compile the Pascal script into bytecode.
  begin
    CompilerOutputMessage;

    foOutput.Failed := true;

    Exit;
  end;

  CompilerOutputMessage;

  if aCompileOnly then
    begin
      Result := (not foOutput.Failed = true);

      Exit;
    end;

  FCompiler.GetOutput(fsData); // Save the output of the compiler in the string Data.
  FCompiler.Free; // After compiling the script, there is no need for the compiler anymore.

  foOutput.Log('Executing ... ');


    Try
      FExec := TPSExec.Create;  // Create an instance of the executer.

      FExec.OnException := OnException;

      oruntime.oPlugins.RegisterFunctions(FExec);

      if not FExec.LoadData(fsData) then
      begin
        foOutput.Log('[Error] : Could not load data: '+TIFErrorToString(FExec.ExceptionCode, FExec.ExceptionString));

        foOutput.Failed := true
      end
        else
           begin
            oruntime.oPlugins.SetVariantToClasses(FExec);

            fbOK := FExec.RunScript;

            if not fbOK then
               begin
                 foOutput.Log('[Runtime Error] : ' + TIFErrorToString(FExec.ExceptionCode, FExec.ExceptionString) +
                    ' in ' + IntToStr(FExec.ExceptionProcNo) + ' at ' + IntToSTr(FExec.ExceptionPos));

                 foOutput.Failed := true;
               end;
           end;
    Finally
      FExec.Free;
    End;


  if foOutput.Failed = true then
   fbOK := False;

  Result := fbOK;
end;

procedure TScriptEngine.RegisterFunctions(aExec: TPSExec);
begin
  RegisterClassLibraryRuntime(aExec, fImp);
end;

procedure TScriptEngine.CompilerOutputMessage;
var
  I: Integer;
begin
  for i := 0 to FCompiler.MsgCount - 1 do
    begin
      foOutput.LogError(FCompiler.Msg[i].MessageToString)
    end;
end;

procedure TScriptEngine.SetVariantToClasses(aExec: TPSExec);
begin
//
end;



end.
