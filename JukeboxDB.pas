namespace MacOxygeneCloudJukebox;

uses
CloudJukeboxSharedProject, RemObjects.Elements.RTL.SQLite;

interface

type
  JukeboxDB = public class
  private
    DebugPrint: Boolean;
    DbConnection: SQLiteConnection;
    MetadataDbFilePath: String;
    InTransaction: Boolean;

  public
    constructor(aMetadataDbFilePath: String;
                aDebugPrint: Boolean);
    method IsOpen: Boolean;
    method Open: Boolean;
    method Close: Boolean;
    method Enter: Boolean;
    method Leave;
    method BeginTransaction: Boolean;
    method Rollback: Boolean;
    method Commit: Boolean;
    method CreateTable(SqlStatement: String): Boolean;
    method CreateTables: Boolean;
    method HaveTables: Boolean;
    method GetPlaylist(PlaylistName: String): String;
    method SongsForQueryResults(QueryResults: SQLiteQueryResult): List<SongMetadata>;
    method RetrieveSong(SongUid: String): SongMetadata;
    method InsertPlaylist(PlUid: String; PlName: String; PlDesc: String): Boolean;
    method DeletePlaylist(PlName: String): Boolean;
    method InsertSong(Song: SongMetadata): Boolean;
    method UpdateSong(Song: SongMetadata): Boolean;
    method StoreSongMetadata(Song: SongMetadata): Boolean;
    method SqlWhereClause: String;
    method RetrieveSongs(Artist: String; Album: String): List<SongMetadata>;
    method SongsForArtist(ArtistName: String): List<SongMetadata>;
    method ShowListings;
    method ShowArtists;
    method ShowGenres;
    method ShowAlbums;
    method ShowPlaylists;
    method DeleteSong(SongUid: String): Boolean;
end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor JukeboxDB(aMetadataDbFilePath: String;
                         aDebugPrint: Boolean);
begin
  DebugPrint := aDebugPrint;
  DbConnection := nil;
  InTransaction := false;
  if aMetadataDbFilePath.Length > 0 then
    MetadataDbFilePath := aMetadataDbFilePath
  else
    MetadataDbFilePath := Jukebox.DEFAULT_DB_FILE_NAME;
  if DebugPrint then begin
    writeLn("JukeboxDB using file {0}", MetadataDbFilePath);
  end;
end;

//*******************************************************************************

method JukeboxDB.IsOpen: Boolean;
begin
  result := DbConnection <> nil;
end;

//*******************************************************************************

method JukeboxDB.Open: Boolean;
begin
  Close;
  var OpenSuccess := false;

  DbConnection := new SQLiteConnection(MetadataDbFilePath);

  if not HaveTables then begin
    OpenSuccess := CreateTables;
    if not OpenSuccess then begin
      writeLn("error: unable to create all tables");
    end;
  end
  else begin
    OpenSuccess := true;
  end;

  exit OpenSuccess;
end;

//*******************************************************************************

method JukeboxDB.Close: Boolean;
begin
  var DidClose := false;
  if DbConnection <> nil then begin
    DbConnection.Close;
    DbConnection := nil;
    DidClose := true;
  end;

  exit DidClose;
end;

//*******************************************************************************

method JukeboxDB.Enter: Boolean;
begin
  // look for stored metadata in the storage system
  if Open() then begin
    if DbConnection <> nil then begin
      if DebugPrint then begin
        writeLn("have db connection");
      end;
    end;
  end
  else begin
    writeLn("unable to connect to database");
    DbConnection := nil;
  end;

  exit DbConnection <> nil;
end;

//*******************************************************************************

method JukeboxDB.Leave;
begin
  if DbConnection <> nil then begin
    DbConnection.Close;
    DbConnection := nil;
  end;
end;

//*******************************************************************************

method JukeboxDB.BeginTransaction: Boolean;
begin
  if InTransaction then begin
    writeLn("error: BeginTransaction called when already in transaction");
    exit false;
  end
  else begin
    InTransaction := true;
    DbConnection.BegInTransaction;
    exit true;
  end;
end;

//*******************************************************************************

method JukeboxDB.Rollback: Boolean;
begin
  if not InTransaction then begin
    writeLn("error: Rollback called when not in transaction");
    exit false;
  end
  else begin
    DbConnection.Rollback;
    InTransaction := false;
    exit true;
  end;
end;

//*******************************************************************************

method JukeboxDB.Commit: Boolean;
begin
  if not InTransaction then begin
    writeLn("error: Commit called when not in transaction");
    exit false;
  end
  else begin
    DbConnection.Commit;
    InTransaction := false;
    exit true;
  end;
end;

//*******************************************************************************

method JukeboxDB.CreateTable(SqlStatement: String): Boolean;
begin
  var DidSucceed := false;
  if DbConnection <> nil then begin
    try
      DbConnection.Execute(SqlStatement, nil);
      DidSucceed := true;
    finally
    end;
  end;
  exit DidSucceed;
end;

//*******************************************************************************

method JukeboxDB.CreateTables: Boolean;
begin
  var DidSucceed := false;
  if DbConnection <> nil then begin
    if DebugPrint then begin
      writeLn("creating tables");
    end;

    const createGenreTable = "CREATE TABLE genre (" +
                             "genre_uid TEXT UNIQUE NOT NULL, " +
                             "genre_name TEXT UNIQUE NOT NULL, " +
                             "genre_description TEXT);";

    const createArtistTable = "CREATE TABLE artist (" +
                              "artist_uid TEXT UNIQUE NOT NULL," +
                              "artist_name TEXT UNIQUE NOT NULL," +
                              "artist_description TEXT);";

    const createAlbumTable = "CREATE TABLE album (" +
                             "album_uid TEXT UNIQUE NOT NULL," +
                             "album_name UNIQUE NOT NULL," +
                             "album_description TEXT," +
                             "artist_uid TEXT NOT NULL REFERENCES artist(artist_uid)," +
                             "genre_uid TEXT REFERENCES genre(genre_uid));";

    const createSongTable = "CREATE TABLE song (" +
                            "song_uid TEXT UNIQUE NOT NULL," +
                            "file_time TEXT," +
                            "origin_file_size INTEGER," +
                            "stored_file_size INTEGER," +
                            "pad_char_count INTEGER," +
                            "artist_name TEXT," +
                            "artist_uid TEXT REFERENCES artist(artist_uid)," +
                            "song_name TEXT NOT NULL," +
                            "md5_hash TEXT NOT NULL," +
                            "compressed INTEGER," +
                            "encrypted INTEGER," +
                            "container_name TEXT NOT NULL," +
                            "object_name TEXT NOT NULL," +
                            "album_uid TEXT REFERENCES album(album_uid));";

    const createPlaylistTable = "CREATE TABLE playlist (" +
                                "playlist_uid TEXT UNIQUE NOT NULL," +
                                "playlist_name TEXT UNIQUE NOT NULL," +
                                "playlist_description TEXT);";

    const createPlaylistSongTable = "CREATE TABLE playlist_song (" +
                                    "playlist_song_uid TEXT UNIQUE NOT NULL," +
                                    "playlist_uid TEXT NOT NULL REFERENCES playlist(playlist_uid)," +
                                    "song_uid TEXT NOT NULL REFERENCES song(song_uid));";

    DidSucceed := CreateTable(createGenreTable) and
                  CreateTable(createArtistTable) and
                  CreateTable(createAlbumTable) and
                  CreateTable(createSongTable) and
                  CreateTable(createPlaylistTable) and
                  CreateTable(createPlaylistSongTable);
  end;

  exit DidSucceed;
end;

//*******************************************************************************

method JukeboxDB.HaveTables: Boolean;
begin
  var HaveTablesInDb := false;
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT COUNT(*) " +
                     "FROM sqlite_master " +
                     "WHERE type='table' AND name='song'";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        const Count = QueryResults.GetInt64(0);
        if Count > 0 then begin
          HaveTablesInDb := true;
        end;
      end;
    finally
      QueryResults.Close;
    end;
  end;

  exit HaveTablesInDb;
end;

//*******************************************************************************

method JukeboxDB.GetPlaylist(PlaylistName: String): String;
begin
  var PlObject: String := nil;

  if PlaylistName.Length > 0 then begin
    const SqlQuery = "SELECT playlist_uid " +
                     "FROM playlist " +
                     "WHERE playlist_name = ?";
    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, PlaylistName);

    try
      while QueryResults.Next do begin
        PlObject := QueryResults.GetString(0);
      end;
    finally
      QueryResults.Close;
    end;
  end;
  exit PlObject;
end;

//*******************************************************************************

method JukeboxDB.SongsForQueryResults(QueryResults: SQLiteQueryResult): List<SongMetadata>;
begin
  const ResultSongs = new List<SongMetadata>();

  try
    while QueryResults.Next do begin
      const song = new SongMetadata();
      song.Fm.FileUid := QueryResults.GetString(0);
      song.Fm.FileTime := QueryResults.GetString(1);
      song.Fm.OriginFileSize := QueryResults.GetInt64(2);
      song.Fm.StoredFileSize := QueryResults.GetInt64(3);
      song.Fm.PadCharCount := QueryResults.GetInt32(4);
      song.ArtistName := QueryResults.GetString(5);
      song.ArtistUid := QueryResults.GetString(6);
      song.SongName := QueryResults.GetString(7);
      song.Fm.Md5Hash := QueryResults.GetString(8);
      song.Fm.Compressed := QueryResults.GetInt32(9) = 1;
      song.Fm.Encrypted := QueryResults.GetInt32(10) = 1;
      song.Fm.ContainerName := QueryResults.GetString(11);
      song.Fm.ObjectName := QueryResults.GetString(12);
      song.AlbumUid := QueryResults.GetString(13);
      ResultSongs.Add(song);
    end;
  finally
    QueryResults.Close;
  end;

  exit ResultSongs;
end;

//*******************************************************************************

method JukeboxDB.RetrieveSong(SongUid: String): SongMetadata;
begin
  var Song: SongMetadata := nil;

  if DbConnection <> nil then begin
    const SqlQuery = "SELECT song_uid," +
                            "file_time," +
                            "origin_file_size," +
                            "stored_file_size," +
                            "pad_char_count," +
                            "artist_name," +
                            "artist_uid," +
                            "song_name," +
                            "md5_hash," +
                            "compressed," +
                            "encrypted," +
                            "container_name," +
                            "object_name," +
                            "album_uid " +
                            "FROM song " +
                     "WHERE song_uid = ?";

    const Args = new PropertyList;
    Args.Append(new PropertyValue(SongUid));

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, SongUid);

    const SongResults = SongsForQueryResults(QueryResults);
    if SongResults.Count > 0 then begin
      Song := SongResults[0];
    end;
  end;

  exit Song;
end;

//*******************************************************************************

method JukeboxDB.InsertPlaylist(PlUid: String;
                                   PlName: String;
                                   PlDesc: String): Boolean;
begin
  var InsertSuccess := false;

  if (DbConnection <> nil) and
     (PlUid.Length > 0) and
     (PlName.Length > 0) then begin

    if not BeginTransaction then begin
      exit false;
    end;

    const SqlStatement = "INSERT INTO playlist VALUES (?,?,?)";

    const Args = new PropertyList;
    Args.Append(new PropertyValue(PlUid));
    Args.Append(new PropertyValue(PlName));
    Args.Append(new PropertyValue(PlDesc));

    const RowsAffected = DbConnection.Execute(SqlStatement, Args);
    if RowsAffected = 0 then begin
      Rollback;
    end
    else begin
      InsertSuccess := Commit;
    end;
  end;

  exit InsertSuccess;
end;

//*******************************************************************************

method JukeboxDB.DeletePlaylist(PlName: String): Boolean;
begin
  var DeleteSuccess := false;

  if (DbConnection <> nil) and (PlName.Length > 0) then begin
    if not BeginTransaction then begin
      exit false;
    end;

    const SqlQuery = "DELETE FROM playlist WHERE playlist_name = ?";

    const Args = new PropertyList;
    Args.Append(new PropertyValue(PlName));

    const RowsAffected = DbConnection.Execute(SqlQuery, Args);
    if RowsAffected = 0 then begin
      Rollback;
    end
    else begin
      DeleteSuccess := Commit;
    end;
  end;

  exit DeleteSuccess;
end;

//*******************************************************************************

method JukeboxDB.InsertSong(Song: SongMetadata): Boolean;
begin
  var InsertSuccess := false;

  if DbConnection <> nil then begin
    if not BeginTransaction() then begin
      exit false;
    end;

    const Args = new PropertyList();
    Args.Append(new PropertyValue(Song.Fm.FileUid));
    Args.Append(new PropertyValue(Song.Fm.FileTime));
    Args.Append(new PropertyValue(Song.Fm.OriginFileSize));
    Args.Append(new PropertyValue(Song.Fm.StoredFileSize));
    Args.Append(new PropertyValue(Song.Fm.PadCharCount));
    Args.Append(new PropertyValue(Song.ArtistName));
    Args.Append(new PropertyValue(""));
    Args.Append(new PropertyValue(Song.SongName));
    Args.Append(new PropertyValue(Song.Fm.Md5Hash));
    Args.Append(new PropertyValue(Song.Fm.Compressed));
    Args.Append(new PropertyValue(Song.Fm.Encrypted));
    Args.Append(new PropertyValue(Song.Fm.ContainerName));
    Args.Append(new PropertyValue(Song.Fm.ObjectName));
    Args.Append(new PropertyValue(Song.AlbumUid));

    const SqlQuery = "INSERT INTO song VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

    const RowId = DbConnection.ExecuteInsert(SqlQuery, Args);
    if RowId < 1 then begin
      Rollback();
    end
    else begin
      InsertSuccess := Commit();
    end;
  end;

  exit InsertSuccess;
end;

//*******************************************************************************

method JukeboxDB.UpdateSong(Song: SongMetadata): Boolean;
begin
  var UpdateSuccess := false;

  if (DbConnection <> nil) and (Song.Fm.FileUid.Length > 0) then begin
    if not BeginTransaction() then begin
      exit false;
    end;

    const Args = new PropertyList();
    Args.Append(new PropertyValue(Song.Fm.FileTime));
    Args.Append(new PropertyValue(Song.Fm.OriginFileSize));
    Args.Append(new PropertyValue(Song.Fm.StoredFileSize));
    Args.Append(new PropertyValue(Song.Fm.PadCharCount));
    Args.Append(new PropertyValue(Song.ArtistName));
    Args.Append(new PropertyValue(""));
    Args.Append(new PropertyValue(Song.SongName));
    Args.Append(new PropertyValue(Song.Fm.Md5Hash));
    Args.Append(new PropertyValue(Song.Fm.Compressed));
    Args.Append(new PropertyValue(Song.Fm.Encrypted));
    Args.Append(new PropertyValue(Song.Fm.ContainerName));
    Args.Append(new PropertyValue(Song.Fm.ObjectName));
    Args.Append(new PropertyValue(Song.AlbumUid));
    Args.Append(new PropertyValue(Song.Fm.FileUid));

    const SqlQuery = "UPDATE song " +
                     "SET file_time=?," +
                         "origin_file_size=?," +
                         "stored_file_size=?," +
                         "pad_char_count=?," +
                         "artist_name=?," +
                         "artist_uid=?," +
                         "song_name=?," +
                         "md5_hash=?," +
                         "compressed=?," +
                         "encrypted=?," +
                         "container_name=?," +
                         "object_name=?," +
                         "album_uid=? " +
                     "WHERE song_uid = ?";

    const RowsAffected = DbConnection.Execute(SqlQuery, Args);
    if RowsAffected = 0 then begin
      Rollback();
    end
    else begin
      UpdateSuccess := Commit();
    end;
  end;

  exit UpdateSuccess;
end;

//*******************************************************************************

method JukeboxDB.StoreSongMetadata(Song: SongMetadata): Boolean;
begin
  const DbSong = RetrieveSong(Song.Fm.FileUid);
  if DbSong <> nil then begin
    if Song <> DbSong then begin
      exit UpdateSong(Song);
    end
    else begin
      exit true;  // no insert or update needed (already up-to-date)
    end;
  end
  else begin
    // song is not in the database, insert it
    exit InsertSong(Song);
  end;
end;

//*******************************************************************************

method JukeboxDB.SqlWhereClause: String;
begin
  exit " WHERE encrypted = 0";
end;

//*******************************************************************************

method JukeboxDB.RetrieveSongs(Artist: String; Album: String): List<SongMetadata>;
begin
  var Songs := new List<SongMetadata>;
  if DbConnection <> nil then begin
    var SqlQuery := "SELECT song_uid," +
                           "file_time," +
                           "origin_file_size," +
                           "stored_file_size," +
                           "pad_char_count," +
                           "artist_name," +
                           "artist_uid," +
                           "song_name," +
                           "md5_hash," +
                           "compressed," +
                           "encrypted," +
                           "container_name," +
                           "object_name," +
                           "album_uid " +
                    "FROM song";

    SqlQuery := SqlQuery + SqlWhereClause();

    var AddedClause: String;
    if Artist.Length > 0 then begin
      const EncodedArtist = JBUtils.EncodeValue(Artist);
      if Album.Length > 0 then begin
        const EncodedAlbum = JBUtils.EncodeValue(Album);
        AddedClause := String.Format(" AND object_name LIKE '{0}--{1}%'",
                                     EncodedArtist,
                                     EncodedAlbum);
      end
      else begin
        AddedClause := String.Format(" AND object_name LIKE '{0}--%'",
                                     EncodedArtist);
      end;
      SqlQuery := SqlQuery + AddedClause;
    end;

    if DebugPrint then begin
      writeLn("executing query: {0}", SqlQuery);
    end;

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);
    Songs := SongsForQueryResults(QueryResults);
  end;

  exit Songs;
end;

//*******************************************************************************

method JukeboxDB.SongsForArtist(ArtistName: String): List<SongMetadata>;
begin
  var Songs := new List<SongMetadata>;
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT song_uid," +
                            "file_time," +
                            "origin_file size," +
                            "stored_file size," +
                            "pad_char_count," +
                            "artist_name," +
                            "artist_uid," +
                            "song_name," +
                            "md5_hash," +
                            "compressed," +
                            "encrypted," +
                            "container_name," +
                            "object_name," +
                            "album_uid " +
                            "FROM song" +
                            SqlWhereClause +
                            " AND artist = ?";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, ArtistName);
    Songs := SongsForQueryResults(QueryResults);
  end;
  exit Songs;
end;

//*******************************************************************************

method JukeboxDB.ShowListings;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT artist_name, song_name " +
                     "FROM song " +
                     "ORDER BY artist_name, song_name";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        const Artist = QueryResults.GetString(0);
        const Song = QueryResults.GetString(1);
        writeLn("{0}, {1}", Artist, Song);
      end;
    finally
      QueryResults.Close;
    end;
  end
  else begin
    writeLn("error: DbConnection is nil");
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowArtists;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT DISTINCT artist_name " +
                     "FROM song " +
                     "ORDER BY artist_name";
    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        writeLn(QueryResults.GetString(0));
      end;
    finally
      QueryResults.Close;
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowGenres;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT genre_name " +
                     "FROM genre " +
                     "ORDER BY genre_name";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        writeLn(QueryResults.GetString(0));
      end;
    finally
      QueryResults.Close;
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowAlbums;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT album.album_name, artist.artist_name " +
                     "FROM album, artist " +
                     "WHERE album.artist_uid = artist.artist_uid " +
                     "ORDER BY album.album_name";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        const AlbumName = QueryResults.GetString(0);
        const ArtistName = QueryResults.GetString(1);
        writeLn("{0} ({1})", AlbumName, ArtistName);
      end;
    finally
      QueryResults.Close;
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowPlaylists;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT playlist_uid, playlist_name " +
                     "FROM playlist " +
                     "ORDER BY playlist_uid";

    const QueryResults = DbConnection.ExecuteQuery(SqlQuery, nil);

    try
      while QueryResults.Next do begin
        const PlUid = QueryResults.GetString(0);
        const PlName = QueryResults.GetString(1);
        writeLn(PlUid + " - " + PlName);
      end;
    finally
      QueryResults.Close;
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.DeleteSong(SongUid: String): Boolean;
begin
  var WasDeleted := false;
  if DbConnection <> nil then begin
    if SongUid.Length > 0 then begin
      if not BeginTransaction then begin
        writeLn("error: begin transaction failed");
        exit false;
      end;

      const ArgList = new PropertyList;
      ArgList.Append(new PropertyValue(SongUid));

      const SqlStatement = "DELETE FROM song WHERE song_uid = ?";
      const RowsAffected = DbConnection.Execute(SqlStatement, SongUid);

      if RowsAffected = 0 then begin
        Rollback;
        writeLn("error: unable to delete song '{0}'", SongUid);
      end
      else begin
        WasDeleted := Commit;
      end;
    end;
  end;

  exit WasDeleted;
end;

//*******************************************************************************

end.
