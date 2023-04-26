namespace CloudJukeboxSharedProject;

interface

type
  JukeboxOptions = public class
  public
    DebugMode: Boolean;
    CheckDataIntegrity: Boolean;
    FileCacheCount: Integer;
    NumberSongs: Integer;
    SuppressMetadataDownload: Boolean;
    Directory: String;

    constructor();
  end;

implementation

constructor JukeboxOptions;
begin
  DebugMode := false;
  CheckDataIntegrity := false;
  FileCacheCount := 3;
  NumberSongs := 0;
  SuppressMetadataDownload := false;
  Directory := "";
end;

end.