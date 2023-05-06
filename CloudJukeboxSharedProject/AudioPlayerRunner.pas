namespace CloudJukeboxSharedProject;

uses
  rtl;

interface

type
  AudioPlayerRunner = public class
  private
    AudioPlayerProcess: Process;
    AudioPlayerPath: String;
    SongDirectory: String;
    Arguments: ImmutableList<String>;
    StdOut: String;
    StdErr: String;
    ExitCode: Int32;
    Terminated: Boolean;

  public
    constructor(aAudioPlayerPath: String;
                aSongDirectory: String;
                aArguments: ImmutableList<String>);
    method PlaySong;
    method OnLineStdOut(aLine: String);
    method OnLineStdErr(aLine: String);
    method OnProcessFinished(aExitCode: Int32);
    method GetExitCode: Int32;
    method GetStdOut: String;
    method GetStdErr: String;
    method Stop;
    method WasTerminated: Boolean;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

constructor AudioPlayerRunner(aAudioPlayerPath: String;
                              aSongDirectory: String;
                              aArguments: ImmutableList<String>);
begin
  AudioPlayerProcess := nil;
  AudioPlayerPath := aAudioPlayerPath;
  SongDirectory := aSongDirectory;
  Arguments := aArguments;
  StdOut := '';
  StdErr := '';
  ExitCode := -1;
  Terminated := false;
end;

//*******************************************************************************

method AudioPlayerRunner.PlaySong;
begin
  const Env = new StringDictionary;

  AudioPlayerProcess := Process.RunAsync(AudioPlayerPath,
                                         Arguments.ToArray,
                                         Env,
                                         SongDirectory,
                                         @OnLineStdOut,
                                         @OnLineStdErr,
                                         @OnProcessFinished);
  if AudioPlayerProcess <> nil then begin
    AudioPlayerProcess.WaitFor;
    AudioPlayerProcess := nil;
  end;
end;

//*******************************************************************************

method AudioPlayerRunner.OnLineStdOut(aLine: String);
begin
  StdOut := StdOut + aLine;
end;

//*******************************************************************************

method AudioPlayerRunner.OnLineStdErr(aLine: String);
begin
  StdErr := StdErr + aLine;
end;

//*******************************************************************************

method AudioPlayerRunner.OnProcessFinished(aExitCode: Int32);
begin
  ExitCode := aExitCode;
end;

//*******************************************************************************

method AudioPlayerRunner.GetExitCode: Int32;
begin
  exit ExitCode;
end;

//*******************************************************************************

method AudioPlayerRunner.GetStdOut: String;
begin
  exit StdOut;
end;

//*******************************************************************************

method AudioPlayerRunner.GetStdErr: String;
begin
  exit StdErr;
end;

//*******************************************************************************

method AudioPlayerRunner.Stop;
begin
  if AudioPlayerProcess <> nil then begin
    AudioPlayerProcess.Stop;
    Terminated := true;
  end;
end;

//*******************************************************************************

method AudioPlayerRunner.WasTerminated: Boolean;
begin
  exit Terminated;
end;

//*******************************************************************************

end.