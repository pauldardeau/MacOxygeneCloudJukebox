namespace MacOxygeneCloudJukebox;

uses
  CloudJukeboxSharedProject;

interface

type
  SongDownloader = public class
  private
    jukebox: Jukebox;
    listSongs: ImmutableList<SongMetadata>;

  public
    constructor(jb: Jukebox; aSongList: ImmutableList<SongMetadata>);
    method Run();
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor SongDownloader(jb: Jukebox; aSongList: ImmutableList<SongMetadata>);
begin
  jukebox := jb;
  listSongs := aSongList;
end;

//*******************************************************************************

method SongDownloader.Run();
begin
  if listSongs.Count > 0 then begin
    jukebox.BatchDownloadStart();

    for each song in listSongs do begin
      if jukebox.IsExitRequested() then begin
        break;
      end
      else begin
        jukebox.DownloadSong(song);
      end;
    end;
    jukebox.BatchDownloadComplete();
  end
  else begin
    writeLn("SongDownloader.run: listSongs is empty");
  end;
end;

//*******************************************************************************

end.