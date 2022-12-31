namespace MacOxygeneCloudJukebox;

interface

type
  Jukebox = public class
  public
    const downloadExtension = ".download";
    const albumContainer = "albums";
    const albumArtContainer = "album-art";
    const metadataContainer = "music-metadata";
    const playlistContainer = "playlists";
    const songContainerSuffix = "-artist-songs";
    const nameAlbumArtImportDir = "album-art-import";
    const namePlaylistImportDir = "playlist-import";
    const nameSongImportDir = "song-import";
    const nameSongPlayDir = "song-play";
    const defaultDbFileName = "jukebox_db.sqlite3";

  private
    JukeboxOptions: JukeboxOptions;
    StorageSystem: StorageSystem;
    DebugPrint: Boolean;
    JukeboxDb: JukeboxDB;
    CurrentDir: String;
    SongImportDirPath: String;
    PlaylistImportDirPath: String;
    SongPlayDirPath: String;
    AlbumArtImportDirPath: String;
    MetadataDbFile: String;
    SongList: List<SongMetadata>;
    NumberSongs: Integer;
    SongIndex: Integer;
    AudioPlayerExeFileName: String;
    AudioPlayerCommandArgs: String;
    AudioPlayerProcess: Process;
    SongPlayLengthSeconds: Integer;
    CumulativeDownloadBytes: Int64;
    CumulativeDownloadTime: Integer;
    ExitRequested: Boolean;
    IsPaused: Boolean;
    SongSecondsOffset: Integer;

  public
    class method InitializeStorageSystem(StorageSys: StorageSystem;
                                         DebugPrint: Boolean): Boolean;
    constructor(JbOptions: JukeboxOptions;
                StorageSys: StorageSystem;
                aDebugPrint: Boolean);
    method Enter: Boolean;
    method Leave;
    method TogglePausePlay;
    method AdvanceToNextSong;
    method PrepareForTermination;
    method DisplayInfo;
    method GetMetadataDbFilePath: String;
    method ComponentsFromFileName(FileName: String): tuple of (String, String, String);
    method ArtistFromFileName(FileName: String): String;
    method AlbumFromFileName(FileName: String): String;
    method SongFromFileName(FileName: String): String;
    method StoreSongMetadata(FsSong: SongMetadata): Boolean;
    method StoreSongPlaylist(FileName: String; FileContents: array of Byte): Boolean;
    method ContainerSuffix: String;
    method ObjectFileSuffix: String;
    method ContainerForSong(SongUid: String): String;
    method ImportSongs;
    method SongPathInPlaylist(Song: SongMetadata): String;
    method CheckFileIntegrity(Song: SongMetadata): Boolean;
    method BatchDownloadStart;
    method BatchDownloadComplete;
    method RetrieveFile(Fm: FileMetadata; DirPath: String): Int64;
    method DownloadSong(Song: SongMetadata): Boolean;
    method PlaySong(Song: SongMetadata);
    method DownloadSongs;
    method DownloadSongs(DlSongs: List<SongMetadata>);
    method PlaySongs(Shuffle: Boolean; Artist: String; Album: String);
    method PlaySongList(aSongList: List<SongMetadata>; Shuffle: Boolean);
    method ShowListContainers;
    method ShowListings;
    method ShowArtists;
    method ShowGenres;
    method ShowAlbums;
    method ReadFileContents(FilePath: String): tuple of (Boolean, array of Byte, Integer);
    method UploadMetadataDb: Boolean;
    method ImportPlaylists;
    method ShowPlaylists;
    method ShowAlbum(Album: String);
    method ShowPlaylist(Playlist: String);
    method PlayPlaylist(Playlist: String);
    method PlayAlbum(Artist: String; Album: String);
    method DeleteSong(SongUid: String; UploadMetadata: Boolean): Boolean;
    method DeleteArtist(Artist: String): Boolean;
    method DeleteAlbum(Album: String): Boolean;
    method DeletePlaylist(PlaylistName: String): Boolean;
    method ImportAlbumArt;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

class method Jukebox.InitializeStorageSystem(StorageSys: StorageSystem;
                                             DebugPrint: Boolean): Boolean;
begin
  // create the containers that will hold songs
  const ArtistSongChars = "0123456789abcdefghijklmnopqrstuvwxyz";

  for i := 0 to ArtistSongChars.Length-1 do begin
    const ch = ArtistSongChars[i];
    const ContainerName = String.Format("{0}{1}", ch, songContainerSuffix);
    if not StorageSys.CreateContainer(ContainerName) then begin
      writeLn(String.Format("error: unable to create container '{0}'", ContainerName));
      result := false;
      exit;
    end;
  end;

  // create the other (non-song) containers
  var ContainerNames := new List<String>;
  ContainerNames.Add(Jukebox.metadataContainer);
  ContainerNames.Add(Jukebox.albumArtContainer);
  ContainerNames.Add(Jukebox.albumContainer);
  ContainerNames.Add(Jukebox.playlistContainer);

  for each ContainerName in ContainerNames do begin
    if not StorageSys.CreateContainer(ContainerName) then begin
      writeLn(String.Format("error: unable to create container '{0}'", ContainerName));
      result := false;
      exit;
    end;
  end;

  // delete metadata DB file if present
  const MetadataDbFile = "jukebox_db.sqlite3";
  if Utils.FileExists(MetadataDbFile) then begin
    if DebugPrint then begin
      writeLn("deleting existing metadata DB file");
    end;
    Utils.DeleteFile(MetadataDbFile);
  end;

  result := true;
end;

//*******************************************************************************

constructor Jukebox(JbOptions: JukeboxOptions;
                    StorageSys: StorageSystem;
                    aDebugPrint: Boolean);
begin
  JukeboxOptions := JbOptions;
  StorageSystem := StorageSys;
  DebugPrint := aDebugPrint;
  JukeboxDb := nil;
  CurrentDir := JbOptions.Directory;
  SongImportDirPath := Utils.PathJoin(CurrentDir, nameSongImportDir);
  PlaylistImportDirPath := Utils.PathJoin(CurrentDir, namePlaylistImportDir);
  SongPlayDirPath := Utils.PathJoin(CurrentDir, nameSongPlayDir);
  AlbumArtImportDirPath := Utils.PathJoin(CurrentDir, nameAlbumArtImportDir);
  MetadataDbFile := Jukebox.defaultDbFileName;
  SongList := new List<SongMetadata>();
  NumberSongs := 0;
  SongIndex := -1;
  AudioPlayerExeFileName := "";
  AudioPlayerCommandArgs := "";
  AudioPlayerProcess := nil;
  SongPlayLengthSeconds := 20;
  CumulativeDownloadBytes := 0;
  CumulativeDownloadTime := 0;
  ExitRequested := false;
  IsPaused := false;
  SongSecondsOffset := 0;

  if JukeboxOptions.DebugMode then begin
    DebugPrint := true;
  end;
  if DebugPrint then begin
    writeLn(String.Format("currentDir = '{0}'", CurrentDir));
    writeLn(String.Format("songImportDirPath = '{0}'", SongImportDirPath));
    writeLn(String.Format("songPlayDirPath = '{0}'", SongPlayDirPath));
  end;
end;

//*******************************************************************************

method Jukebox.Enter: Boolean;
var
  EnterSuccess: Boolean;
begin
  EnterSuccess := false;

  // look for stored metadata in the storage system
  if StorageSystem.HasContainer(Jukebox.metadataContainer) and
     not JukeboxOptions.SuppressMetadataDownload then begin

    // metadata container exists, retrieve container listing
    var MetadataFileInContainer := false;
    const ContainerContents =
      StorageSystem.ListContainerContents(Jukebox.metadataContainer);

    if ContainerContents.Count > 0 then begin
      for each Container in ContainerContents do begin
        if Container = MetadataDbFile then begin
          MetadataFileInContainer := true;
          break;
        end;
      end;
    end;

    // does our metadata DB file exist in the metadata container?
    if MetadataFileInContainer then begin
      // download it
      const MetadataDbFilePath = GetMetadataDbFilePath();

      if Utils.FileExists(MetadataDbFilePath) then begin
        if DebugPrint then begin
          writeLn("deleting existing metadata DB file");
        end;
        Utils.DeleteFile(MetadataDbFilePath);
      end;

      const DownloadFile = MetadataDbFilePath; // + Jukebox.downloadExtension;
      if StorageSystem.GetObject(Jukebox.metadataContainer,
                                 MetadataDbFile,
                                 DownloadFile) > 0 then begin
        if DebugPrint then begin
          writeLn("metadata DB file downloaded");
        end;
      end
      else begin
        if DebugPrint then begin
          writeLn("error: unable to retrieve metadata DB file");
        end;
      end;
    end
    else begin
      if DebugPrint then begin
        writeLn("no metadata container in storage system");
      end;
    end;

    JukeboxDb := new JukeboxDB(GetMetadataDbFilePath(),
                               JukeboxOptions.UseEncryption,
                               JukeboxOptions.UseCompression,
                               true); //debugPrint
    EnterSuccess := JukeboxDb.Enter();
    if not EnterSuccess then begin
      writeLn("unable to connect to database");
    end;
  end;

  result := EnterSuccess;
end;

//*******************************************************************************

method Jukebox.Leave;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.Leave;
    JukeboxDb := nil;
  end;
end;

//*******************************************************************************

method Jukebox.TogglePausePlay;
begin
  IsPaused := not IsPaused;
  if IsPaused then begin
    writeLn("paused");
    if AudioPlayerProcess <> nil then begin
      // capture current song position (seconds into song)
      AudioPlayerProcess.Stop();
      AudioPlayerProcess := nil;
    end;
  end
  else begin
    writeLn("resuming play");
  end;
end;

//*******************************************************************************

method Jukebox.AdvanceToNextSong;
begin
  writeLn("advancing to next song");
  if AudioPlayerProcess <> nil then begin
    AudioPlayerProcess.Stop();
    AudioPlayerProcess := nil;
  end;
end;

//*******************************************************************************

method Jukebox.PrepareForTermination;
begin
  writeLn("Ctrl-C detected, shutting down");

  // indicate that it's time to shutdown
  ExitRequested := true;

  // terminate audio player if it's running
  if AudioPlayerProcess <> nil then begin
    AudioPlayerProcess.Stop();
    AudioPlayerProcess := nil;
  end;
end;

//*******************************************************************************

method Jukebox.DisplayInfo;
begin
  if SongList.Count > 0 then begin
    const MaxIndex = SongList.Count - 1;
    if (SongIndex+3) <= MaxIndex then begin
      writeLn("----- songs on deck -----");
      var firstSong := SongList[SongIndex+1];
      writeLn(firstSong.Fm.FileUid);
      var secondSong := SongList[SongIndex+2];
      writeLn(secondSong.Fm.FileUid);
      var thirdSong := SongList[SongIndex+3];
      writeLn(thirdSong.Fm.FileUid);
      writeLn("-------------------------");
    end;
  end;
end;

//*******************************************************************************

method Jukebox.GetMetadataDbFilePath: String;
begin
  result := Utils.PathJoin(CurrentDir, MetadataDbFile);
end;

//*******************************************************************************

method Jukebox.ComponentsFromFileName(FileName: String): tuple of (String, String, String);
begin
  if FileName.Length = 0 then begin
    result := ("", "", "");
    exit;
  end;

  const BaseFileName =
    RemObjects.Elements.RTL.Path.GetFileNameWithoutExtension(FileName);

  const Components = BaseFileName.Split("--", true);
  if Components.Count = 3 then begin
    result := (JBUtils.UnencodeValue(Components[0]),
               JBUtils.UnencodeValue(Components[1]),
               JBUtils.UnencodeValue(Components[2]));
  end
  else begin
    result := ("", "", "");
  end;
end;

//*******************************************************************************

method Jukebox.ArtistFromFileName(FileName: String): String;
var
  Artist: String;
begin
  Artist := "";
  if FileName.Length > 0 then begin
     (Artist, _, _) := ComponentsFromFileName(FileName);
  end;
  result := Artist;
end;

//*******************************************************************************

method Jukebox.AlbumFromFileName(FileName: String): String;
var
  Album: String;
begin
  Album := "";
  if FileName.Length > 0 then begin
    (_, Album, _) := ComponentsFromFileName(FileName);
  end;
  result := Album;
end;

//*******************************************************************************

method Jukebox.SongFromFileName(FileName: String): String;
var
  Song: String;
begin
  Song := "";
  if FileName.Length > 0 then begin
    (_, _, Song) := ComponentsFromFileName(FileName);
  end;
  result := Song;
end;

//*******************************************************************************

method Jukebox.StoreSongMetadata(FsSong: SongMetadata): Boolean;
var
  StoreSuccess: Boolean;
begin
  StoreSuccess := false;
  if JukeboxDb <> nil then begin
    const DbSong = JukeboxDb.RetrieveSong(FsSong.Fm.FileUid);
    if DbSong <> nil then begin
      if not FsSong.Equals(DbSong) then begin
        StoreSuccess := JukeboxDb.UpdateSong(FsSong);
      end
      else begin
        StoreSuccess := true; // no insert or update needed (already up-to-date)
      end;
    end
    else begin
      // song is not in the database, insert it
      StoreSuccess := JukeboxDb.InsertSong(FsSong);
    end;
  end;
  result := StoreSuccess;
end;

//*******************************************************************************

method Jukebox.StoreSongPlaylist(FileName: String;
                                 FileContents: array of Byte): Boolean;
begin
  //TODO: implement StoreSongPlaylist
  result := false;
end;

//*******************************************************************************

method Jukebox.ContainerSuffix: String;
var
  Suffix: String;
begin
  Suffix := "";
  if JukeboxOptions.UseEncryption and JukeboxOptions.UseCompression then begin
    Suffix := "-ez";
  end
  else if JukeboxOptions.UseEncryption then begin
    Suffix := "-e";
  end
  else if JukeboxOptions.UseCompression then begin
    Suffix := "-z";
  end;
  result := Suffix;
end;

//*******************************************************************************

method Jukebox.ObjectFileSuffix: String;
var
  Suffix: String;
begin
  Suffix := "";
  if JukeboxOptions.UseEncryption and JukeboxOptions.UseCompression then begin
    Suffix := ".egz";
  end
  else if JukeboxOptions.UseEncryption then begin
    Suffix := ".e";
  end
  else if JukeboxOptions.UseCompression then begin
    Suffix := ".gz";
  end;
  result := Suffix;
end;

//*******************************************************************************

method Jukebox.ContainerForSong(SongUid: String): String;
var
  ArtistLetter: String;
begin
  if SongUid.Length = 0 then begin
    result := "";
    exit;
  end;

  const theContainerSuffix = Jukebox.songContainerSuffix + ContainerSuffix;

  const Artist = ArtistFromFileName(SongUid);
  if Artist.Length = 0 then begin
    result := "";
    exit;
  end;

  if Artist.StartsWith("A ") then begin
    ArtistLetter := Artist[2];
  end
  else if Artist.StartsWith("The ") then begin
    ArtistLetter := Artist[4];
  end
  else begin
    ArtistLetter := Artist[0];
  end;

  result := ArtistLetter.ToLower() + theContainerSuffix;
end;

//*******************************************************************************

method Jukebox.ImportSongs;
begin
  if JukeboxDb <> nil then begin
    if not JukeboxDb.IsOpen() then begin
      exit;
    end;

    var DirListing := Utils.ListFilesInDirectory(SongImportDirPath);
    if DirListing.Count = 0 then begin
      exit;
    end;

    const NumEntries = Double(DirListing.Count);
    var progressbarChars := 0.0;
    const progressbarWidth = 40;
    const progressCharsPerIteration = Double(progressbarWidth) / NumEntries;
    const progressbarChar = "#";
    var barChars := 0;

    if not DebugPrint then begin
      // setup progressbar
      /*
      var aChar: Char
      var count: Int32
      aChar = " "
      count = Int32(progressbarWidth)
      print("[%s]", String(aChar, count))
      //sys.stdout.flush()
      aChar = "\b"
      count = Int32(progressbarWidth+1)
      print(String(aChar, count)) // return to start of line, after '['
      */
    end;

    var CumulativeUploadTime := 0;
    var CumulativeUploadBytes := 0;
    var FileImportCount := 0;

    for each ListingEntry in DirListing do begin
      const FullPath = Utils.PathJoin(SongImportDirPath, ListingEntry);
      // ignore it if it's not a file
      if Utils.FileExists(FullPath) then begin
        const FileName = ListingEntry;
        var (_, FileExtension) := Utils.PathSplitExt(FullPath);
        if FileExtension.Length > 0 then begin
          const fileSize = Utils.GetFileSize(FullPath);
          const artist = ArtistFromFileName(FileName);
          const album = AlbumFromFileName(FileName);
          const song = SongFromFileName(FileName);

          if (fileSize > 0) and
             (artist.Length > 0) and
             (album.Length > 0) and
             (song.Length > 0) then begin

            const objectName = FileName + ObjectFileSuffix();
            var fsSong := new SongMetadata();
            fsSong.Fm.FileUid := objectName;
            fsSong.AlbumUid := "";
            fsSong.Fm.OriginFileSize := fileSize;
            //let oFile = RemObjects.Elements.RTL.File(fullPath)
            //TODO: assign fileTime
            //fsSong.Fm.FileTime = oFile.DateModified
            fsSong.ArtistName := artist;
            fsSong.SongName := song;
            const md5Hash = Utils.Md5ForFile(FullPath);
            if md5Hash.Length > 0 then begin
              fsSong.Fm.Md5Hash := md5Hash;
            end;
            fsSong.Fm.Compressed := JukeboxOptions.UseCompression;
            fsSong.Fm.Encrypted := JukeboxOptions.UseEncryption;
            fsSong.Fm.ObjectName := objectName;
            fsSong.Fm.PadCharCount := 0;

            fsSong.Fm.ContainerName := ContainerForSong(FileName);

            // read file contents
            var FileRead := false;

            const FileContents = Utils.FileReadAllBytes(FullPath);
            if FileContents.length > 0 then begin
              FileRead := true;
            end
            else begin
              writeLn(String.Format("error: unable to read file {0}", FullPath));
            end;

            if FileRead then begin
              if FileContents.length > 0 then begin
                // for general purposes, it might be useful or helpful to have
                // a minimum size for compressing
                if JukeboxOptions.UseCompression then begin
                  if DebugPrint then
                    writeLn("compressing file");

                    //TODO: compress file contents
                end;

                if JukeboxOptions.UseEncryption then begin
                  if DebugPrint then
                    writeLn("encrypting file");

                    //TODO: encrypt file contents
                  end;
                end;

                // now that we have the data that will be stored, set the file size for
                // what's being stored
                fsSong.Fm.StoredFileSize := Int64(FileContents.length);
                //startUploadTime := time.Now()

                // store song file to storage system
                if StorageSystem.PutObject(fsSong.Fm.ContainerName,
                                           fsSong.Fm.ObjectName,
                                           FileContents,
                                           nil) then begin
                  //endUploadTime := time.Now()
                  // endUploadTime - startUploadTime
                  //uploadElapsedTime := endUploadTime.Add(-startUploadTime)
                  //cumulativeUploadTime.Add(uploadElapsedTime)
                  CumulativeUploadBytes := CumulativeUploadBytes + FileContents.length;

                  // store song metadata in local database
                  if not StoreSongMetadata(fsSong) then begin
                    // we stored the song to the storage system, but were unable to store
                    // the metadata in the local database. we need to delete the song
                    // from the storage system since we won't have any way to access it
                    // since we can't store the song metadata locally.
                    writeLn(String.Format("unable to store metadata, deleting obj '{0}'",
                                          fsSong.Fm.ObjectName));
                    StorageSystem.DeleteObject(fsSong.Fm.ContainerName,
                                               fsSong.Fm.ObjectName);
                  end
                  else begin
                    inc(FileImportCount);
                  end
                end
                else begin
                  writeLn(String.Format("error: unable to upload '{0}' to '{1}'",
                                        fsSong.Fm.ObjectName,
                                        fsSong.Fm.ContainerName));
                end;
              end;
            end;
          end;

          if not DebugPrint then begin
            progressbarChars := progressbarChars + Double(progressCharsPerIteration);
            if Integer(progressbarChars) > barChars then begin
              const numNewChars = Integer(progressbarChars) - barChars;
              if numNewChars > 0 then begin
                // update progress bar
                //for j in 1...numNewChars do begin
                //  write(progressbarChar);
                //end;
                //sys.stdout.flush()
                barChars := barChars + numNewChars;
              end;
            end;
          end;
        end;
      end;

    if not DebugPrint then begin
      // if we haven't filled up the progress bar, fill it now
      if barChars < progressbarWidth then begin
        //const numNewChars = progressbarWidth - barChars;
        //for j in 1...numNewChars do begin
        //  write(progressbarChar);
        //end;
        //sys.stdout.flush()
      end;
      writeLn("");
    end;

    if FileImportCount > 0 then begin
      UploadMetadataDb();
    end;

    writeLn(String.Format("{0} song files imported", FileImportCount));

    if CumulativeUploadTime > 0 then begin
      const cumulativeUploadKb = Double(CumulativeUploadBytes) / 1000.0;
      writeLn(String.Format("average upload throughput = {0} KB/sec",
            cumulativeUploadKb/CumulativeUploadTime));
    end;
  end;
end;

//*******************************************************************************

method Jukebox.SongPathInPlaylist(Song: SongMetadata): String;
begin
  result := Utils.PathJoin(SongPlayDirPath, Song.Fm.FileUid);
end;

//*******************************************************************************

method Jukebox.CheckFileIntegrity(Song: SongMetadata): Boolean;
var
  FileIntegrityPassed: Boolean;
begin
  FileIntegrityPassed := true;

  if JukeboxOptions.CheckDataIntegrity then begin
    var FilePath := SongPathInPlaylist(Song);
    if Utils.FileExists(FilePath) then begin
      if DebugPrint then
        writeLn("checking integrity for {0}", Song.Fm.FileUid);

      var PlaylistMd5 := Utils.Md5ForFile(FilePath);
      if PlaylistMd5.Length = 0 then begin
        writeLn("error: unable to calculate MD5 hash for file '{0}'", FilePath);
        FileIntegrityPassed := false;
      end
      else begin
        if PlaylistMd5 = Song.Fm.Md5Hash then begin
          if DebugPrint then
            writeLn("integrity check SUCCESS");

          FileIntegrityPassed := true;
        end
        else begin
          writeLn("file integrity check failed: {0}", Song.Fm.FileUid);
          FileIntegrityPassed := false;
        end;
      end;
    end
    else begin
      // file doesn't exist
      writeLn("file doesn't exist");
      FileIntegrityPassed := false;
    end;
  end
  else begin
    if DebugPrint then
      writeLn("file integrity bypassed, no jukebox options or check integrity not turned on");
  end;

  result := FileIntegrityPassed;
end;

//*******************************************************************************

method Jukebox.BatchDownloadStart;
begin
  CumulativeDownloadBytes := 0;
  CumulativeDownloadTime := 0;
end;

//*******************************************************************************

method Jukebox.BatchDownloadComplete;
begin
  if not ExitRequested then begin
    if CumulativeDownloadTime > 0 then begin
      const CumulativeDownloadKb = Real(CumulativeDownloadBytes) / 1000.0;
      writeLn(String.Format("average download throughput = {0} KB/sec",
              CumulativeDownloadKb/Int64(CumulativeDownloadTime)));
    end;
    CumulativeDownloadBytes := 0;
    CumulativeDownloadTime := 0;
  end;
end;

//*******************************************************************************

method Jukebox.RetrieveFile(Fm: FileMetadata; DirPath: String): Int64;
var
  BytesRetrieved: Int64;
begin
  BytesRetrieved := 0;

  if DirPath.Length > 0 then begin
     BytesRetrieved := StorageSystem.GetObject(Fm.ContainerName,
                                               Fm.ObjectName,
                                               Utils.PathJoin(DirPath,
                                                              Fm.FileUid));
  end;

  result := BytesRetrieved;
end;

//*******************************************************************************

method Jukebox.DownloadSong(Song: SongMetadata): Boolean;
begin
  if ExitRequested then begin
    result := false;
    exit;
  end;

  const FilePath = SongPathInPlaylist(Song);
  //downloadStartTime := time.time()
  const SongBytesRetrieved = RetrieveFile(Song.Fm, SongPlayDirPath);
  if ExitRequested then begin
    result := false;
    exit;
  end;

  if DebugPrint then begin
    writeLn(String.Format("bytes retrieved: {0}", SongBytesRetrieved));
  end;

  if SongBytesRetrieved > 0 then begin
    //downloadEndTime := time.time()
    //downloadElapsedTime := downloadEndTime - downloadStartTime
    //cumulativeDownloadTime += downloadElapsedTime
    CumulativeDownloadBytes := CumulativeDownloadBytes + SongBytesRetrieved;

    // are we checking data integrity?
    // if so, verify that the storage system retrieved the same length that has been stored
    if JukeboxOptions.CheckDataIntegrity then begin
      if DebugPrint then begin
        writeLn("verifying data integrity");
      end;

      if SongBytesRetrieved <> Song.Fm.StoredFileSize then begin
        writeLn(String.Format("error: file size check failed for '{0}'", FilePath));
        result := false;
        exit;
      end;
    end;

    // is it encrypted? if so, unencrypt it
    var Encrypted := Song.Fm.Encrypted;
    var Compressed := Song.Fm.Compressed;

    if Encrypted or Compressed then begin
      var FileContents := Utils.FileReadAllBytes(FilePath);
      if FileContents.Count = 0 then begin
        writeLn(String.Format("error: unable to read file {0}", FilePath));
        result := false;
        exit;
      end;

      if Encrypted then begin
        //TODO: decrypt content
      end;

      if Compressed then begin
        //TODO: uncompress content
      end;

      // re-write out the uncompressed, unencrypted file contents
      if not Utils.FileWriteAllBytes(FilePath, FileContents) then begin
        writeLn(String.Format("error: unable to write unencrypted/uncompressed file '{0}'",
                              FilePath));
        result := false;
        exit;
      end;
    end;

    if CheckFileIntegrity(Song) then begin
      result := true;
      exit;
    end
    else begin
      // we retrieved the file, but it failed our integrity check
      // if file exists, remove it
      if Utils.FileExists(FilePath) then begin
        Utils.DeleteFile(FilePath);
      end;
    end;
  end;

  result := false;
end;

//*******************************************************************************

method Jukebox.PlaySong(Song: SongMetadata);
var
  ExitCode: Integer;
  StartedAudioPlayer: Boolean;
begin
  ExitCode := -1;
  StartedAudioPlayer := false;

  const SongFilePath = SongPathInPlaylist(Song);

  if Utils.FileExists(SongFilePath) then begin
    writeLn(String.Format("playing {0}", Song.Fm.FileUid));
    if AudioPlayerExeFileName.Length > 0 then begin
      var Args := new List<String>();
      if AudioPlayerCommandArgs.Length > 0 then begin
        const VecAddlArgs = AudioPlayerCommandArgs.Split(" ");
        for each AddlArg in VecAddlArgs do begin
          Args.Add(AddlArg);
        end;
      end;
      Args.Add(SongFilePath);

      const Env = new Dictionary<String,String>();
      const WorkingDir = Environment.CurrentDirectory;

      //AudioPlayerProcess := new Process(AudioPlayerExeFileName,
      //                                  Args,
      //                                  Env,
      //                                  WorkingDir);

      if AudioPlayerProcess.Start() then begin
        StartedAudioPlayer := true;
        AudioPlayerProcess.WaitFor();
        ExitCode := AudioPlayerProcess.ExitCode;
        AudioPlayerProcess := nil;
      end
      else begin
        writeLn("error: unable to start audio player");
        AudioPlayerExeFileName := "";
        AudioPlayerCommandArgs := "";
      end;

      // if the audio player failed or is not present, just sleep
      // for the length of time that audio would be played
      if (not StartedAudioPlayer) and (ExitCode <> 0) then begin
        //TimeSleepSeconds(SongPlayLengthSeconds);
      end;
    end
    else begin
      // we don't know about an audio player, so simulate a
      // song being played by sleeping
      RemObjects.Elements.RTL.Thread.Sleep(1000 * SongPlayLengthSeconds);
    end;

    if not IsPaused then begin
      // delete the song file from the play list directory
      Utils.DeleteFile(SongFilePath);
    end;
  end
  else begin
    writeLn(String.Format("song file doesn't exist: '{0}'", SongFilePath));
    RemObjects.Elements.RTL.File.AppendText("404.txt", SongFilePath + "\n");
  end;
end;

//*******************************************************************************

method Jukebox.DownloadSongs;
begin
  // scan the play list directory to see if we need to download more songs
  var DirListing := Utils.ListFilesInDirectory(SongPlayDirPath);
  if DirListing.Count = 0 then begin
    // log error
    exit;
  end;

  var DlSongs := new List<SongMetadata>;

  var SongFileCount := 0;
  for each FileName in DirListing do begin
    var FileExtension :=
      RemObjects.Elements.RTL.File(FileName).Extension;

    if (FileExtension.Length > 0) and
       (FileExtension <> downloadExtension) then begin

      inc(SongFileCount);
    end;
  end;

  var FileCacheCount := JukeboxOptions.FileCacheCount;

  if SongFileCount < FileCacheCount then begin
    // start looking at the next song in the list
    var CheckIndex := SongIndex + 1;
    for j := 1 to NumberSongs do begin
      if CheckIndex >= NumberSongs then begin
        CheckIndex := 0;
      end;
      if CheckIndex <> SongIndex then begin
        const si = SongList[CheckIndex];
        const FilePath = SongPathInPlaylist(si);
        if not Utils.FileExists(FilePath) then begin
          DlSongs.Add(si);
          if DlSongs.Count >= FileCacheCount then begin
            break
          end;
        end;
      end;
      inc(CheckIndex);
    end;
  end;

  if DlSongs.Count > 0 then begin
    DownloadSongs(DlSongs);
  end;
end;

//*******************************************************************************

method Jukebox.DownloadSongs(DlSongs: List<SongMetadata>);
begin
  if DlSongs.Count > 0 then begin
    //TODO:
    /*
    if (Downloader = nil) and (DownloadThread = nil) then begin
      if DebugPrint then begin
        writeLn("creating SongDownloader and download thread");
      end;
      Downloader := new SongDownloader(this, DlSongs);
      DownloadThread := new Thread(Downloader);
      Downloader.SetCompletionObserver(this);
      DownloadThread.Start();
    end
    else begin
      if DebugPrint then begin
        writeLn("Not downloading more songs b/c downloader != NULL or download_thread != NULL");
      end;
    end;
    */
  end;
end;

//*******************************************************************************

method Jukebox.PlaySongs(Shuffle: Boolean; Artist: String; Album: String);
begin
  if JukeboxDb <> nil then begin
    const theSongList = JukeboxDb.RetrieveSongs(Artist, Album);
    PlaySongList(theSongList, Shuffle);
  end;
end;

//*******************************************************************************

method Jukebox.PlaySongList(aSongList: List<SongMetadata>; Shuffle: Boolean);
begin
  NumberSongs := aSongList.Count;

  if NumberSongs = 0 then begin
    writeLn("no songs in jukebox");
    exit;
  end;

  // does play list directory exist?
  if not Utils.DirectoryExists(SongPlayDirPath) then begin
    if DebugPrint then begin
      writeLn("song-play directory does not exist, creating it");
    end;
    Utils.CreateDirectory(SongPlayDirPath);
  end
  else begin
    // play list directory exists, delete any files in it
    if DebugPrint then begin
      writeLn("deleting existing files in song-play directory");
    end;
    Utils.DeleteFilesInDirectory(SongPlayDirPath);
  end;

  SongIndex := 0;
  //InstallSignalHandlers();

  //TODO: osId := runtime.GOOS
  var osId := "";
  if osId.StartsWith("darwin") then begin
    AudioPlayerExeFileName := "afplay";
    AudioPlayerCommandArgs := "";
  end
  else if osId.StartsWith("linux") or
          osId.StartsWith("freebsd") or
          osId.StartsWith("netbsd") or
          osId.StartsWith("openbsd") then begin

    AudioPlayerExeFileName := "/usr/bin/mplayer";
    AudioPlayerCommandArgs := "-novideo -nolirc -really-quiet";
  end
  else if osId.StartsWith("windows") then begin
    // we really need command-line support for /play and /close arguments. unfortunately,
    // this support used to be available in the built-in Windows Media Player, but is
    // no longer present.
    AudioPlayerExeFileName := "C:\\Program Files\\MPC-HC\\mpc-hc64.exe";
    AudioPlayerCommandArgs := "/play /close /minimized";
  end
  else begin
    writeLn(String.Format("error: '{0}' is not a supported OS\n", osId));
    exit;
  end;

  writeLn("downloading first song...");

  if Shuffle then begin
    //TODO: add shuffling of song list
    //songList = random.sample(songList, len(songList))
  end;

  if DownloadSong(aSongList[0]) then begin
    writeLn("first song downloaded. starting playing now.");

    const pidAsText = String.Format("{0}\n", Utils.GetPid());
    Utils.FileWriteAllText("pid.txt", pidAsText);

    while true do begin
      if not ExitRequested then begin
        if not IsPaused then begin
          DownloadSongs;
          PlaySong(aSongList[SongIndex]);
        end;
        if not IsPaused then begin
          inc(SongIndex);
          if SongIndex >= NumberSongs then begin
            SongIndex := 0;
          end;
        end else begin
          RemObjects.Elements.RTL.Thread.Sleep(1000);
        end;
      end
      else begin
        break
      end;
    end;

    Utils.DeleteFile("pid.txt");
  end
  else begin
    writeLn("error: unable to download songs");
  end;
end;

//*******************************************************************************

method Jukebox.ShowListContainers;
begin
  const ListContainers = StorageSystem.GetContainerNames();
  if ListContainers.Count > 0 then begin
    for each ContainerName in ListContainers do begin
      writeLn(ContainerName);
    end;
  end
  else begin
    writeLn("error: unable to retrieve list of containers");
  end;
end;

//*******************************************************************************

method Jukebox.ShowListings;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.ShowListings();
  end;
end;

//*******************************************************************************

method Jukebox.ShowArtists;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.ShowArtists();
  end;
end;

//*******************************************************************************

method Jukebox.ShowGenres;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.ShowGenres();
  end;
end;

//*******************************************************************************

method Jukebox.ShowAlbums;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.ShowAlbums();
  end;
end;

//*******************************************************************************

method Jukebox.ReadFileContents(FilePath: String): tuple of (Boolean, array of Byte, Integer);
var
  FileRead: Boolean;
  FileContents: array of Byte;
  PadChars: Integer;
begin
  FileRead := false;
  PadChars := 0;

  FileContents := Utils.FileReadAllBytes(FilePath);
  if FileContents.Count = 0 then begin
    writeLn(String.Format("error: unable to read file '{0}'", FilePath));
    var emptyBytes: array of Byte;
    result := (false, emptyBytes, 0);
    exit;
  end
  else begin
    FileRead := true;
  end;

  if FileRead then begin
    if FileContents.Count > 0 then begin
      // for general purposes, it might be useful or helpful to have
      // a minimum size for compressing
      if JukeboxOptions.UseCompression then begin
        if DebugPrint then begin
          writeLn("compressing file");
        end;

        //TODO: compress file contents
      end;

      if JukeboxOptions.UseEncryption then begin
        if DebugPrint then begin
          writeLn("encrypting file");
        end;

        //TODO: encrypt file contents
      end;
    end;
  end;

  result := (FileRead, FileContents, PadChars);
end;

//*******************************************************************************

method Jukebox.UploadMetadataDb: Boolean;
var
  MetadataDbUpload: Boolean;
  HaveMetadataContainer: Boolean;
begin
  MetadataDbUpload := false;
  HaveMetadataContainer := false;
  if not StorageSystem.HasContainer(Jukebox.metadataContainer) then
    HaveMetadataContainer :=
      StorageSystem.CreateContainer(Jukebox.metadataContainer)
  else
    HaveMetadataContainer := true;

  if HaveMetadataContainer then begin
    if JukeboxDb <> nil then begin
      if DebugPrint then
        writeLn("uploading metadata db file to storage system");

      JukeboxDb.Close();
      JukeboxDb := nil;

      const DbFilePath = GetMetadataDbFilePath();
      const DbFileContents = Utils.FileReadAllBytes(DbFilePath);

      if DbFileContents.Count > 0 then begin
        MetadataDbUpload := StorageSystem.PutObject(Jukebox.metadataContainer,
                                                    MetadataDbFile,
                                                    DbFileContents,
                                                    nil);
      end
      else begin
        writeLn("error: unable to read metadata db file");
      end;

      if DebugPrint then begin
        if MetadataDbUpload then
          writeLn("metadata db file uploaded")
        else
          writeLn("unable to upload metadata db file");
      end;
    end;
  end;

  result := MetadataDbUpload;
end;

//*******************************************************************************

method Jukebox.ImportPlaylists;
var
  FileImportCount: Integer;
  HaveContainer: Boolean;
  FileRead: Boolean;
  FileContents: array of Byte;
begin
  if JukeboxDb <> nil then begin
    if JukeboxDb.IsOpen() then begin
      FileImportCount := 0;
      var DirListing := Utils.ListFilesInDirectory(PlaylistImportDirPath);
      if DirListing.Count = 0 then begin
        writeLn("no playlists found");
        exit;
      end;

      HaveContainer := false;
      if not StorageSystem.HasContainer(Jukebox.playlistContainer) then
        HaveContainer :=
          StorageSystem.CreateContainer(Jukebox.playlistContainer)
      else
        HaveContainer := true;

      if not HaveContainer then begin
        writeLn("error: unable to create container for playlists. unable to import");
        exit;
      end;

      for each FileName in DirListing do begin
        const FullPath = Utils.PathJoin(PlaylistImportDirPath, FileName);
        const ObjectName = FileName;
        (FileRead, FileContents, _) := ReadFileContents(FullPath);
        if FileRead then begin
          if StorageSystem.PutObject(Jukebox.playlistContainer,
                                     ObjectName,
                                     FileContents,
                                     nil) then begin
            writeLn("put of playlist succeeded");
            if not StoreSongPlaylist(ObjectName, FileContents) then begin
              writeLn("storing of playlist to db failed");
              _ := StorageSystem.DeleteObject(Jukebox.playlistContainer,
                                              ObjectName);
            end
            else begin
              writeLn("storing of playlist succeeded");
              inc(FileImportCount);
            end;
          end;
        end;
      end;

      if FileImportCount > 0 then begin
        writeLn(String.Format("{0} playlists imported", FileImportCount));
        UploadMetadataDb;
      end
      else begin
        writeLn("no files imported");
      end;
    end;
  end;
end;

//*******************************************************************************

method Jukebox.ShowPlaylists;
begin
  if JukeboxDb <> nil then begin
    JukeboxDb.ShowPlaylists();
  end;
end;

//*******************************************************************************

method Jukebox.ShowAlbum(Album: String);
begin
  //TODO: implement ShowAlbum
end;

//*******************************************************************************

method Jukebox.ShowPlaylist(Playlist: String);
begin
  //TODO: implement ShowPlaylist
end;

//*******************************************************************************

method Jukebox.PlayPlaylist(Playlist: String);
begin
  //TODO: implement PlayPlaylist
end;

//*******************************************************************************

method Jukebox.PlayAlbum(Artist: String; Album: String);
begin
  //TODO: implement PlayAlbum
end;

//*******************************************************************************

method Jukebox.DeleteSong(SongUid: String; UploadMetadata: Boolean): Boolean;
var
  IsDeleted: Boolean;
begin
  IsDeleted := false;
  if SongUid.Length > 0 then begin
    if JukeboxDb <> nil then begin
      const DbDeleted = JukeboxDb.DeleteSong(SongUid);
      const Container = ContainerForSong(SongUid);
      if Container.Length > 0 then begin
        const SsDeleted = StorageSystem.DeleteObject(Container, SongUid);
        if DbDeleted and UploadMetadata then
          UploadMetadataDb;
        IsDeleted := DbDeleted or SsDeleted;
      end;
    end;
  end;

  result := IsDeleted;
end;

//*******************************************************************************

method Jukebox.DeleteArtist(Artist: String): Boolean;
var
  IsDeleted: Boolean;
begin
  IsDeleted := false;
  if Artist.Length > 0 then begin
    if JukeboxDb <> nil then begin
      const theSongList = JukeboxDb.RetrieveSongs(Artist, "");
      if theSongList.Count = 0 then begin
        writeLn("no artist songs in jukebox");
      end
      else begin
        for each Song in theSongList do begin
          if not DeleteSong(Song.Fm.ObjectName, false) then begin
            writeLn(String.Format("error deleting song '{0}'",
                                  Song.Fm.ObjectName));
            result := false;
            exit;
          end;
        end;
        UploadMetadataDb;
        IsDeleted := true;
      end;
    end;
  end;

  result := IsDeleted;
end;

//*******************************************************************************

method Jukebox.DeleteAlbum(Album: String): Boolean;
var
  AlbumDeleted: Boolean;
begin
  AlbumDeleted := false;
  const ContainsDoubleDash = Album.Contains("--");
  if ContainsDoubleDash then begin
    const NameComponents = Album.Split("--");
    if NameComponents.Count = 2 then begin
      const Artist = NameComponents[0];
      const AlbumName = NameComponents[1];
      if JukeboxDb <> nil then begin
        const ListAlbumSongs = JukeboxDb.RetrieveSongs(Artist, AlbumName);
        if ListAlbumSongs.Count > 0 then begin
          var NumSongsDeleted := 0;
          for each Song in ListAlbumSongs do begin
            writeLn(String.Format("{0} {1}",
                                  Song.Fm.ContainerName,
                                  Song.Fm.ObjectName));
            // delete each song audio file
            if StorageSystem.DeleteObject(Song.Fm.ContainerName,
                                          Song.Fm.ObjectName) then begin
              inc(NumSongsDeleted);
              // delete song metadata
              JukeboxDb.DeleteSong(Song.Fm.ObjectName);
            end
            else begin
              writeLn(String.Format("error: unable to delete song {0}",
                                    Song.Fm.ObjectName));
            end;
          end;
          if NumSongsDeleted > 0 then begin
            // upload metadata db
            UploadMetadataDb();
            AlbumDeleted := true;
          end
          else begin
            writeLn(String.Format("no songs found for artist='{0}' album name='{1}'",
                                  Artist,
                                  AlbumName));
          end;
        end;
      end;
    end;
  end
  else begin
    writeLn("specify album with 'the-artist--the-song-name' format");
  end;

  result := AlbumDeleted;
end;

//*******************************************************************************

method Jukebox.DeletePlaylist(PlaylistName: String): Boolean;
var
  IsDeleted: Boolean;
begin
  IsDeleted := false;
  if JukeboxDb <> nil then begin
    const ObjectName = JukeboxDb.GetPlaylist(PlaylistName);
    if ObjectName <> nil then begin
      if ObjectName.Length > 0 then begin
        const DbDeleted = JukeboxDb.DeletePlaylist(PlaylistName);
        if DbDeleted then begin
          writeLn(String.Format("container='{0}', object='{1}'",
                                Jukebox.playlistContainer,
                                ObjectName));
          if StorageSystem.DeleteObject(Jukebox.playlistContainer,
                                        ObjectName) then begin
            IsDeleted := true;
          end
          else begin
            writeLn("error: object delete failed");
          end;
        end
        else begin
          writeLn("error: database delete failed");
          if IsDeleted then begin
            UploadMetadataDb;
          end
          else begin
            writeLn("delete of playlist failed");
          end;
        end;
      end
      else begin
        writeLn("invalid playlist name");
      end;
    end;
  end;

  result := IsDeleted;
end;

//*******************************************************************************

method Jukebox.ImportAlbumArt;
var
  FileImportCount: Integer;
  HaveContainer: Boolean;
  FileRead: Boolean;
  FileContents: array of Byte;
begin
  if JukeboxDb <> nil then begin
    if JukeboxDb.IsOpen then begin
      FileImportCount := 0;
      const DirListing = Utils.ListFilesInDirectory(AlbumArtImportDirPath);
      if DirListing.Count = 0 then begin
        writeLn("no album art found");
        exit;
      end;

      HaveContainer := false;

      if not StorageSystem.HasContainer(Jukebox.albumArtContainer) then
        HaveContainer :=
          StorageSystem.CreateContainer(Jukebox.albumArtContainer)
      else
        HaveContainer := true;

      if not HaveContainer then begin
        writeLn("error: unable to create container for album art. unable to import");
        exit;
      end;

      for each FileName in DirListing do begin
        const FullPath = Utils.PathJoin(AlbumArtImportDirPath, FileName);
        const ObjectName = FileName;
        (FileRead, FileContents, _) := ReadFileContents(FullPath);
        if FileRead then begin
          if StorageSystem.PutObject(Jukebox.albumArtContainer,
                                     ObjectName,
                                     FileContents,
                                     nil) then begin
            inc(FileImportCount);
          end;
        end;
      end;

      if FileImportCount > 0 then begin
        writeLn(String.Format("{0} album art files imported",
                              FileImportCount));
      end
      else begin
        writeLn("no files imported");
      end;
    end;
  end;
end;

//*******************************************************************************

end.