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
   protected
     procedure CompilerOutputMessage;
   public
     constructor Create(aOutput: TOutput);
     destructor Destroy;

     function ExecuteScript(aScript: String): boolean;
   end;

implementation

uses Runtime, plugin;

constructor TScriptEngine.create;
begin
  foOutput:= aOutput;
end;

destructor TScriptEngine.destroy;
begin
end;

procedure OnException(Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring; ExObject: TObject; ProcNo, Position: Cardinal);
var
  lsExParam: String;
begin
  (*
  oruntime.oAPI_Output.LastExError := ExError;


  lsExParam := ExParam;
  if ExParam = '' then lsExParam := 'Unknown error.';


  oruntime.oAPI_Output.LastExParam := lsExParam;
//  oruntime.oAPI_Output.Errors := True;
  oruntime.oAPI_Output.projecttask.BuildStatus := TBuildStatus.bsErrors;
  *)
end;

function CustomOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
Var
  lList:  TStringList;
  FTPSCompileTimeClass: TPSCompileTimeClass;
  fSystemExtPlugin: TPascalScriptPlugin;
begin
  if Name = 'SYSTEM' then
  begin
    Result := False;
    fSystemExtPlugin := TPascalScriptPlugin(oRuntime.oPlugins.FindPlugin('SYSTEMEXT'));
    if Assigned(fSystemExtPlugin) then
      begin
        Result := fSystemExtPlugin.CustomOnUses(Sender);
      end;
  end
  else
  begin
    (*
    if FileExists(oruntime.oProject.oProjectConfig.SearchPath +name + '.pas') then
      begin
        Try
          Try
            oruntime.oAPI_Output.Log('Compiling unit ... ' + name + '.pas' );

            lList := TStringList.Create;
            lList.LoadFromFile(oruntime.oProject.oProjectConfig.SearchPath +name + '.zas');

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
         TPSPascalCompiler(Sender).MakeError('', ecUnitNotFoundOrContainsErrors, Name);

         Result := False;
       end;
       *)
  end;

end;


function TScriptEngine.ExecuteScript(aScript: String): boolean;
var
  liRetry, I: Integer;
  fbOK: Boolean;
  fbRetry: Boolean;
begin
  Result := false;

  FCompiler := TPSPascalCompiler.Create; // create an instance of the compiler.
  FCompiler.OnUses :=CustomOnUses; // assign the OnUses event.

  //FCompiler.OnExportCheck := ScriptOnExportCheck; // Assign the onExportCheck event.

  FCompiler.AllowNoBegin := True;
  FCompiler.AllowNoEnd := True; // AllowNoBegin and AllowNoEnd allows it that begin and end are not required in a script.

  //foAPI_Output.WriteLog('Compiling ... ');

  if not FCompiler.Compile(aScript) then  // Compile the Pascal script into bytecode.
  begin
    CompilerOutputMessage;

    foOutput.Failed := true;

   // foAPI_Output.projecttask.BuildStatus := TBuildStatus.bsFailed;

    Exit;
  end;

  CompilerOutputMessage;

  FCompiler.GetOutput(fsData); // Save the output of the compiler in the string Data.
  FCompiler.Free; // After compiling the script, there is no need for the compiler anymore.

//  foAPI_Output.WriteLog('Executing ... ');


    Try
      FExec := TPSExec.Create;  // Create an instance of the executer.

      FExec.OnException := OnException;

     // foPlugins.RegisterFunctions(FExec);

      if not FExec.LoadData(fsData) then
      begin
        foOutput.WriteLog('[Error] : Could not load data: '+TIFErrorToString(FExec.ExceptionCode, FExec.ExceptionString));

        foOutput.Failed := true
      end
        else
           begin
            //foPlugins.SetVariantToClasses(FExec);

            fbOK := FExec.RunScript;

            if not fbOK then
               begin
                 foOutput.WriteLog('[Runtime Error] : ' + TIFErrorToString(FExec.ExceptionCode, FExec.ExceptionString) +
                    ' in ' + IntToStr(FExec.ExceptionProcNo) + ' at ' + IntToSTr(FExec.ExceptionPos));

                 foOutput.Failed := true;
               end;
           end;
    Finally
      FExec.Free;
    End;


  if foOutput.Failed = true then
     Result := True;
end;

procedure TScriptEngine.CompilerOutputMessage;
var
  I: Integer;
begin
  for i := 0 to FCompiler.MsgCount - 1 do
    begin
      foOutput.WriteLog(FCompiler.Msg[i].MessageToString)
    end;
end;


end.
