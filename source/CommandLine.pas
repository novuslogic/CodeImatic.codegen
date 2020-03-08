unit CommandLine;

interface

Uses
  NovusCommandLine, SysUtils;

const
  clworkingdirectory = 'workingdirectory';
  clproject = 'project';
  clconsoleoutputonly = 'consoleoutputonly';
  clvar = 'var';
  clOutputlog = 'outputlog';


type
  tProjectCommand = class(tNovusCommandLineCommand)
  protected
  private
    fsProjectFileName: string;
  public
    constructor Create; override;

    function Execute: boolean; override;

    property ProjectFileName: string read fsProjectFileName
      write fsProjectFileName;
  end;

  tHelpCommand = class(tNovusCommandLineCommand)
  protected
  private
  public
    constructor Create; override;
    function Execute: boolean; override;
  end;

  tOutputlogCommand = class(tNovusCommandLineCommand)
  protected
  private
    fsOutputlogFilename: string;
  public
    constructor Create; override;
    function Execute: boolean; override;

    property OutputlogFilename: string
      read fsOutputlogFilename
      write fsOutputlogFilename;
  end;


  tConsoleoutputonlyCommand = class(tNovusCommandLineCommand)
  protected
  private
  public
  end;

  tWorkingDirectoryCommand = class(tNovusCommandLineCommand)
  protected
  private
    fsWorkingDirectory: string;
  public
    constructor Create; override;
    function Execute: boolean; override;

    property WorkingDirectory: string
       read fsWorkingDirectory
       write fsWorkingDirectory;
  end;

  tVarCommand = class(tNovusCommandLineCommand)
  protected
  private
    fsVariable: string;
  public
    constructor Create; override;
    function Execute: boolean; override;

    property Variable: string
       read fsVariable
       write fsVariable;
  end;

  TCommandLine = class(tNovusCommandLine)
  protected
  private
  public
    class procedure RegisterCommands;
  end;


implementation

Uses Config;

// tPeojectCommand
constructor tprojectCommand.Create;
begin
  inherited;

  RegisterOption('filename', '', true, NIL);
end;

function tProjectCommand.Execute: boolean;
var
  fFilenameOption: INovusCommandLineOption;
begin
  result := false;

  fFilenameOption := FindOptionByName('filename');

  if Assigned(fFilenameOption) then
    begin
      result := True;

      ProjectFileName := fFilenameOption.Value;
    end;
end;

// tHelpCommand
constructor tHelpCommand.Create;
begin
  inherited;

  RegisterOption('command', '', true, NIL);
end;


function tHelpCommand.Execute: boolean;
var
  fCommandOption: INovusCommandLineOption;
  fCommand: INovusCommandLineCommand;
begin
  result := false;

  fCommandOption := FindOptionByName('command');
  if Assigned(fCommandOption) then
    begin
      fCommand := FindCommandName(fCommandOption.Value);
      if Assigned(fCommand) then
        begin
          result := True;

          writeln(fCommand.Help);
        end;
    end;

end;


// tWorkingDirectoryCommand
constructor tWorkingDirectoryCommand.Create;
begin
  inherited;

  RegisterOption(clworkingdirectory, '', true, NIL);
end;

function tWorkingDirectoryCommand.Execute: boolean;
var
  fWorkingdirectoryOption: INovusCommandLineOption;
begin
  result := false;

  fWorkingdirectoryOption := FindOptionByName(clworkingdirectory);

  if Assigned(fWorkingdirectoryOption) then
    begin
      result := true;

      Workingdirectory := fWorkingdirectoryOption.Value;
    end;


end;

// tOutputlogCommand
constructor tOutputlogCommand.Create;
begin
  inherited;

  fsOutputlogFilename := csOutputFile;

  RegisterOption(clOutputlog, '', false, NIL);
end;

function tOutputlogCommand.Execute: boolean;
var
  fOutputlogOption: INovusCommandLineOption;
begin
  result := false;

  fOutputlogOption := FindOptionByName(clOutputlog);

  if Assigned(fOutputlogOption) then
    begin
      result := true;

      OutputlogFilename := fOutputlogOption.Value;
    end;


end;

// TVarCoomand
constructor tVarCommand.Create;
begin
  inherited;

  RegisterOption('variable', '', true, NIL);
end;

function tVarCommand.Execute: boolean;
var
  fVarOption: INovusCommandLineOption;
begin
  result := false;

  fVarOption := FindOptionByName('variable');

  if Assigned(fVarOption) then
    begin
      result := true;

      Variable := fVarOption.Value;
    end;


end;


//TCommandLine
class procedure TCommandLine.RegisterCommands;
begin
  tCommandLine.RegisterCommand(clproject, 's',
    'Usage : codeimatic.codegen -project [filename]', true, tProjectCommand.Create);

  tCommandLine.RegisterCommand(clworkingdirectory, 'w',
    'Usage : codeimatic.codegen -workingdirectory [directory]', false, tWorkingDirectoryCommand.Create);

  tCommandLine.RegisterCommand(clconsoleoutputonly, '', 'Usage : codeimatic.codegen -consoleoutputonly', false,
    tConsoleoutputonlyCommand.Create);

  tCommandLine.RegisterCommand(clvar, 'v', 'Usage : codeimatic.codegen -var [variable]', false,
    tVarCommand.Create);

  tCommandLine.RegisterCommand('help', 'h', 'Usage : codeimatic.codegen -help [command]', false,
    tHelpCommand.Create);

  tCommandLine.RegisterCommand(clvar, 'o', 'Usage : codeimatic.codegen -outputlog [outputlogfilename]', false,
    tOutputlogCommand.Create);


end;


end.
