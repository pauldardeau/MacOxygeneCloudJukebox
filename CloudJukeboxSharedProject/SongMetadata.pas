namespace CloudJukeboxSharedProject;

interface

type
  SongMetadata = public class
  public
    Fm: FileMetadata;
    ArtistUid: String;
    ArtistName: String;
    AlbumUid: String;
    SongName: String;

    constructor();
    constructor(aFm: FileMetadata);
  end;

implementation

constructor SongMetadata();
begin
  Fm := new FileMetadata();
  ArtistUid := "";
  ArtistName := "";
  AlbumUid := "";
  SongName := "";
end;

constructor SongMetadata(aFm: FileMetadata);
begin
  Fm := aFm;
  ArtistUid := "";
  ArtistName := "";
  AlbumUid := "";
  SongName := "";
end;

end.