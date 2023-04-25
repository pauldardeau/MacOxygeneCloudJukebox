namespace MacOxygeneCloudJukebox;

uses
  rtl;

interface

type
  Jukebox = public class
  public
    // containers
    const albumContainerSuffix = "albums";
    const albumArtContainerSuffix = "album-art";
    const metadataContainerSuffix = "music-metadata";
    const playlistContainerSuffix = "playlists";
    const songContainerSuffix = "-artist-songs";

    // directories
    const albumArtImportDir = "album-art-import";
    const playlistImportDir = "playlist-import";
    const songImportDir = "song-import";
    const songPlayDir = "song-play";

    // files
    const downloadExtension = ".download";
    const jukeboxPidFileName = "jukebox.pid";
    const JsonFileExt = ".json";
    const IniFileName = "audio_player.ini";
    const defaultDbFileName = "jukebox_db.sqlite3";

    // audio file INI contents
    const keyAudioPlayerExeFileName = "audio_player_exe_file_name";
    const keyAudioPlayerCommandArgs = "audio_player_command_args";
    const keyAudioPlayerResumeArgs = "audio_player_resume_args";

    // placeholders
    const phAudioFilePath = "%%AUDIO_FILE_PATH%%";
    const phStartSongTimeOffset = "%%START_SONG_TIME_OFFSET%%";


  public
    GlobalJukebox: Jukebox := nil; static;
  private
    JukeboxOptions: JukeboxOptions;
    StorageSystem: StorageSystem;
    DebugPrint: Boolean;
    JukeboxDb: JukeboxDB;
    ContainerPrefix: String;
    CurrentDir: String;
    SongImportDirPath: String;
    PlaylistImportDirPath: String;
    SongPlayDirPath: String;
    AlbumArtImportDirPath: String;
    MetadataDbFile: String;
    MetadataContainer: String;
    PlaylistContainer: String;
    AlbumContainer: String;
    AlbumArtContainer: String;
    SongList: List<SongMetadata>;
    NumberSongs: Integer;
    SongIndex: Integer;
    AudioPlayerExeFileName: String;
    AudioPlayerCommandArgs: String;
    AudioPlayerResumeArgs: String;
    AudioPlayerProcess: Process;
    SongPlayLengthSeconds: Integer;
    CumulativeDownloadBytes: Int64;
    CumulativeDownloadTime: Integer;
    ExitRequested: Boolean;
    IsPaused: Boolean;
    SongStartTime: Double;
    SongSecondsOffset: Integer;
    SongPlayIsResume: Boolean;
    IsRepeatMode: Boolean;
    Downloader: SongDownloader;
    DownloadThread: Thread;
    IniFilePath: String;

  public
    class method InitializeStorageSystem(StorageSys: StorageSystem;
                                         aContainerPrefix: String;
                                         aDebugPrint: Boolean): Boolean;
    constructor(JbOptions: JukeboxOptions;
                StorageSys: StorageSystem;
                aContainerPrefix: String;
                aDebugPrint: Boolean);
    method InstallSignalHandlers;
    method IsExitRequested: Boolean;
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
    method RunSongDownloaderThread();
    method PlaySongs(Shuffle: Boolean; Artist: String; Album: String);
    method PlaySongList(aSongList: List<SongMetadata>; Shuffle: Boolean);
    method ShowListContainers;
    method ShowListings;
    method ShowArtists;
    method ShowGenres;
    method ShowAlbums;
    method ReadFileContents(FilePath: String): tuple of (Boolean, array of Byte);
    method UploadMetadataDb: Boolean;
    method ImportPlaylists;
    method ShowPlaylists;
    method ShowAlbum(Artist: String; Album: String);
    method ShowPlaylist(Playlist: String);
    method PlayPlaylist(Playlist: String);
    method PlayAlbum(Artist: String; Album: String);
    method DeleteSong(SongUid: String; UploadMetadata: Boolean): Boolean;
    method DeleteArtist(Artist: String): Boolean;
    method DeleteAlbum(Album: String): Boolean;
    method DeletePlaylist(PlaylistName: String): Boolean;
    method ImportAlbumArt;
    method RetrieveAlbumTrackObjectList(Artist: String;
                                        Album: String;
                                        ListTrackObjects: List<String>): Boolean;
    method GetPlaylistSongs(Playlist: String;
                            ListSongs: List<SongMetadata>): Boolean;
    method ReadAudioPlayerConfig;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

class method Jukebox.InitializeStorageSystem(StorageSys: StorageSystem;
                                             aContainerPrefix: String;
                                             aDebugPrint: Boolean): Boolean;
begin
  // create the containers that will hold songs
  const ArtistSongChars = "0123456789abcdefghijklmnopqrstuvwxyz";

  for i := 0 to ArtistSongChars.Length-1 do begin
    const ch = ArtistSongChars[i];
    const ContainerName = aContainerPrefix + String.Format("{0}{1}", ch, songContainerSuffix);
    if not StorageSys.CreateContainer(ContainerName) then begin
      writeLn("error: unable to create container '{0}'", ContainerName);
      result := false;
      exit;
    end;
  end;

  // create the other (non-song) containers
  var ContainerNames := new List<String>;
  ContainerNames.Add(Jukebox.metadataContainerSuffix);
  ContainerNames.Add(Jukebox.albumArtContainerSuffix);
  ContainerNames.Add(Jukebox.albumContainerSuffix);
  ContainerNames.Add(Jukebox.playlistContainerSuffix);

  for each ContainerName in ContainerNames do begin
    var CnrName := aContainerPrefix + ContainerName;
    if not StorageSys.CreateContainer(CnrName) then begin
      writeLn("error: unable to create container '{0}'", CnrName);
      result := false;
      exit;
    end;
  end;

  // delete metadata DB file if present
  const MetadataDbFile = defaultDbFileName;
  if Utils.FileExists(MetadataDbFile) then begin
    if aDebugPrint then begin
      writeLn("deleting existing metadata DB file");
    end;
    Utils.DeleteFile(MetadataDbFile);
  end;

  result := true;
end;

//*******************************************************************************

constructor Jukebox(JbOptions: JukeboxOptions;
                    StorageSys: StorageSystem;
                    aContainerPrefix: String;
                    aDebugPrint: Boolean);
begin
  if GlobalJukebox = nil then begin
    GlobalJukebox := self;
  end
  else begin
    //TODO: throw an exception (only 1 Jukebox instance allowed)
  end;

  JukeboxOptions := JbOptions;
  StorageSystem := StorageSys;
  DebugPrint := aDebugPrint;
  JukeboxDb := nil;
  ContainerPrefix := aContainerPrefix;
  CurrentDir := JbOptions.Directory;
  SongImportDirPath := Utils.PathJoin(CurrentDir, songImportDir);
  PlaylistImportDirPath := Utils.PathJoin(CurrentDir, playlistImportDir);
  SongPlayDirPath := Utils.PathJoin(CurrentDir, songPlayDir);
  AlbumArtImportDirPath := Utils.PathJoin(CurrentDir, albumArtImportDir);
  MetadataDbFile := Jukebox.defaultDbFileName;
  MetadataContainer := ContainerPrefix + Jukebox.metadataContainerSuffix;
  PlaylistContainer := ContainerPrefix + Jukebox.playlistContainerSuffix;
  AlbumContainer := ContainerPrefix + Jukebox.albumContainerSuffix;
  AlbumArtContainer := ContainerPrefix + Jukebox.albumArtContainerSuffix;
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
  Downloader := nil;
  DownloadThread := nil;
  IniFilePath := Utils.PathJoin(JbOptions.Directory, "jukebox.ini");

  if JukeboxOptions.DebugMode then begin
    DebugPrint := true;
  end;
  if DebugPrint then begin
    writeLn("currentDir = '{0}'", CurrentDir);
    writeLn("songImportDirPath = '{0}'", SongImportDirPath);
    writeLn("songPlayDirPath = '{0}'", SongPlayDirPath);
    writeLn("playlistImportDirPath = '{0}'", PlaylistImportDirPath);
    writeLn("albumArtImportDirPath = '{0}'", AlbumArtImportDirPath);
  end;
end;

//*******************************************************************************

class method SigHandler(signum: Integer);
begin
  if Jukebox.GlobalJukebox <> nil then begin
    if signum = SIGUSR1 then begin
      Jukebox.GlobalJukebox.TogglePausePlay;
    end
    else if signum = SIGUSR2 then begin
      Jukebox.GlobalJukebox.AdvanceToNextSong;
    end
    else if signum = SIGINT then begin
      Jukebox.GlobalJukebox.PrepareForTermination;
    end
    else if signum = SIGWINCH then begin
      Jukebox.GlobalJukebox.DisplayInfo;
    end;
  end;
end;

//*******************************************************************************

method Jukebox.InstallSignalHandlers;
begin
  var lAct := new __struct_sigaction;
  lAct.sa_flags := SA_SIGINFO;
  lAct.__sigaction_u.__sa_handler := @SigHandler;

  // setup the sigterm handler
  sigaction(SIGUSR1, @lAct, nil);
  sigaction(SIGUSR2, @lAct, nil);
  sigaction(SIGINT, @lAct, nil);
  sigaction(SIGWINCH, @lAct, nil);
end;

//*******************************************************************************

method Jukebox.IsExitRequested: Boolean;
begin
  result := ExitRequested;
end;

//*******************************************************************************

method Jukebox.Enter: Boolean;
var
  EnterSuccess: Boolean;
begin
  EnterSuccess := false;

  // look for stored metadata in the storage system
  if StorageSystem.HasContainer(MetadataContainer) and
     not JukeboxOptions.SuppressMetadataDownload then begin

    // metadata container exists, retrieve container listing
    var MetadataFileInContainer := false;
    const ContainerContents =
      StorageSystem.ListContainerContents(MetadataContainer);

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
      if StorageSystem.GetObject(MetadataContainer,
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
                               true); //debugPrint
    EnterSuccess := JukeboxDb.Enter();
    if not EnterSuccess then begin
      writeLn("unable to connect to database");
    end;
  end
  else begin
    if DebugPrint then begin
      if not StorageSystem.HasContainer(MetadataContainer) then begin
        writeLn("metadata container '{0}' does not exist", MetadataContainer);
      end;
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
    AudioPlayerProcess.Stop;
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

  const BaseFileName = Utils.GetBaseFileName(FileName);

  const Components = BaseFileName.Split("--", true);
  if Components.Count = 3 then begin
    result := (JBUtils.DecodeValue(Components[0]),
               JBUtils.DecodeValue(Components[1]),
               JBUtils.DecodeValue(Components[2]));
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

method Jukebox.ContainerForSong(SongUid: String): String;
var
  ArtistLetter: String;
begin
  if SongUid.Length = 0 then begin
    result := "";
    exit;
  end;

  const theContainerSuffix = Jukebox.songContainerSuffix;

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

  result := ContainerPrefix + ArtistLetter.ToLower() + theContainerSuffix;
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

            const objectName = FileName;
            var fsSong := new SongMetadata();
            fsSong.Fm.FileUid := objectName;
            fsSong.AlbumUid := "";
            fsSong.Fm.OriginFileSize := fileSize;
            //let oFile = RemObjects.Elements.RTL.File(fullPath)
            //TODO: assign fileTime
            //fsSong.Fm.FileTime = oFile.DateModified
            fsSong.ArtistName := artist;
            fsSong.SongName := song;
            const md5Hash = Utils.Md5ForFile(IniFilePath, FullPath);
            if md5Hash.Length > 0 then begin
              fsSong.Fm.Md5Hash := md5Hash;
            end;
            fsSong.Fm.Compressed := false;
            fsSong.Fm.Encrypted := false;
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
              writeLn("error: unable to read file {0}", FullPath);
            end;

            if FileRead then begin
              if FileContents.length > 0 then begin
                fsSong.Fm.StoredFileSize := Int64(FileContents.length);
                //startUploadTime := time.Now()

                var ContainerName := ContainerPrefix + fsSong.Fm.ContainerName;

                // store song file to storage system
                if StorageSystem.PutObject(ContainerName,
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
                    writeLn("unable to store metadata, deleting obj '{0}'",
                            fsSong.Fm.ObjectName);
                    StorageSystem.DeleteObject(ContainerName,
                                               fsSong.Fm.ObjectName);
                  end
                  else begin
                    inc(FileImportCount);
                  end
                end
                else begin
                  writeLn("error: unable to upload '{0}' to '{1}'",
                          fsSong.Fm.ObjectName,
                          ContainerName);
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

    writeLn("{0} song files imported", FileImportCount);

    if CumulativeUploadTime > 0 then begin
      const cumulativeUploadKb = Double(CumulativeUploadBytes) / 1000.0;
      writeLn("average upload throughput = {0} KB/sec",
              cumulativeUploadKb/CumulativeUploadTime);
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

      var PlaylistMd5 := Utils.Md5ForFile(IniFilePath, FilePath);
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
      writeLn("average download throughput = {0} KB/sec",
              CumulativeDownloadKb/Int64(CumulativeDownloadTime));
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
     BytesRetrieved := StorageSystem.GetObject(ContainerPrefix + Fm.ContainerName,
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
    writeLn("bytes retrieved: {0}", SongBytesRetrieved);
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
        writeLn("error: file size check failed for '{0}'", FilePath);
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
begin
  ExitCode := -1;

  const SongFilePath = SongPathInPlaylist(Song);

  if Utils.FileExists(SongFilePath) then begin
    writeLn("playing {0}", Song.Fm.FileUid);
    if AudioPlayerExeFileName.Length > 0 then begin
      var didResume := false;
      var commandArgs := "";
      if SongPlayIsResume then begin
        const placeholder = phStartSongTimeOffset;
        const posPlaceholder =
            AudioPlayerResumeArgs.IndexOf(placeholder);
        if posPlaceholder > -1 then begin
          commandArgs := AudioPlayerResumeArgs;
          var theSongStartTime: String := "";
          const minutes = SongSecondsOffset / 60;
          if minutes > 0 then begin
            theSongStartTime := minutes.ToString();
            theSongStartTime := theSongStartTime + ":";
            const remainingSeconds = SongSecondsOffset mod 60;
            var secondsText := remainingSeconds.ToString();
            if secondsText.length = 1 then begin
              secondsText := "0" + secondsText;
            end;
            theSongStartTime := theSongStartTime + secondsText;
          end
          else begin
            theSongStartTime := SongSecondsOffset.ToString();
          end;
          //writeLn("resuming at '{0}'", songStartTime);
          commandArgs := commandArgs.Replace(phStartSongTimeOffset, theSongStartTime);
          commandArgs := commandArgs.Replace(phAudioFilePath, SongFilePath);
          didResume := true;
          //writeLn("commandArgs: '{0}'", commandArgs);
        end;
      end;

      if not didResume then begin
        commandArgs := AudioPlayerCommandArgs;
        commandArgs := commandArgs.Replace(phAudioFilePath, SongFilePath);
      end;

      const Args = commandArgs.Split(" ");
      const Env = new Dictionary<String,String>();

      AudioPlayerProcess := new Process();
      ExitCode := AudioPlayerProcess.Run(AudioPlayerExeFileName,
                                         Args,
                                         Env,
                                         SongPlayDirPath);
      AudioPlayerProcess := nil;

      // if the audio player failed or is not present, just sleep
      // for the length of time that audio would be played
      if ExitCode <> 0 then begin
        Utils.SleepSeconds(SongPlayLengthSeconds);
      end;
    end
    else begin
      // we don't know about an audio player, so simulate a
      // song being played by sleeping
      Utils.SleepSeconds(SongPlayLengthSeconds);
    end;

    if not IsPaused then begin
      // delete the song file from the play list directory
      Utils.DeleteFile(SongFilePath);
    end;
  end
  else begin
    writeLn("song file doesn't exist: '{0}'", SongFilePath);
    const FileNotFoundPath = Utils.PathJoin(JukeboxOptions.Directory, "404.txt");
    Utils.FileAppendAllText(FileNotFoundPath, SongFilePath + Environment.LineBreak);
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
    const FileExtension = Utils.GetFileExtension(FileName);

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
    if (Downloader = nil) and (DownloadThread = nil) then begin
      if DebugPrint then begin
        writeLn("creating SongDownloader and download thread");
      end;
      Downloader := new SongDownloader(self, DlSongs);
      DownloadThread := new Thread(@RunSongDownloaderThread);
      DownloadThread.Start();
    end
    else begin
      if DebugPrint then begin
        writeLn("Not downloading more songs b/c downloader != NULL or download_thread != NULL");
      end;
    end;
  end;
end;

//*******************************************************************************

method Jukebox.RunSongDownloaderThread();
begin
  Downloader.Run();
  Downloader := nil;
  DownloadThread := nil;
end;

//*******************************************************************************

method Jukebox.PlaySongs(Shuffle: Boolean; Artist: String; Album: String);
begin
  if JukeboxDb <> nil then begin
    var HaveSongs := false;
    if (Artist.Length > 0) and (Album.Length > 0) then begin
      var aSongList := new List<SongMetadata>;
      var ListTrackObjects := new List<String>;
      if RetrieveAlbumTrackObjectList(Artist, Album, ListTrackObjects) then begin
        if ListTrackObjects.Count > 0 then begin
          for each TrackObjectName in ListTrackObjects do begin
            var Song := JukeboxDb.RetrieveSong(TrackObjectName);
            if Song <> nil then begin
              aSongList.Add(Song);
            end;
          end;
          if aSongList.Count = ListTrackObjects.Count then begin
            HaveSongs := true;
            SongList := aSongList;
          end;
        end;
      end;
    end;

    if not HaveSongs then begin
      SongList := JukeboxDb.RetrieveSongs(Artist, Album);
    end;

    PlaySongList(SongList, Shuffle);
  end;
end;

//*******************************************************************************

method Jukebox.ReadAudioPlayerConfig;
begin
  if not Utils.FileExists(IniFileName) then begin
    writeLn("error: missing {0} config file", IniFileName);
    exit;
  end;

  const osIdentifier = Utils.GetPlatformIdentifier();
  if osIdentifier = Utils.PLATFORM_UNKNOWN then begin
    writeLn("error: no audio-player specific lookup defined for this OS (unknown)");
    exit;
  end;

  var charsToStrip: array  of Char;
  charsToStrip := new Char[1];
  charsToStrip[0] := '"';

  AudioPlayerExeFileName := "";
  AudioPlayerCommandArgs := "";
  AudioPlayerResumeArgs := "";

  var iniReader := new IniReader(IniFileName);
  if not iniReader.ReadFile() then begin
    writeLn("error: unable to read ini config file '{0}'", IniFileName);
    exit;
  end;

  var kvpAudioPlayer := new KeyValuePairs();
  if not iniReader.ReadSection(osIdentifier, var kvpAudioPlayer) then begin
    writeLn("error: no config section present for '{0}'", osIdentifier);
    exit;
  end;

  var key := keyAudioPlayerExeFileName;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerExeFileName := kvpAudioPlayer.GetValue(key);

    if AudioPlayerExeFileName.StartsWith('"') and
       AudioPlayerExeFileName.EndsWith('"') then begin

      AudioPlayerExeFileName := AudioPlayerExeFileName.Trim(charsToStrip);
    end;

    AudioPlayerExeFileName := AudioPlayerExeFileName.Trim();

    if AudioPlayerExeFileName.Length = 0 then begin
      writeLn("error: no value given for '{0}' within [{1}]", key, osIdentifier);
      exit;
    end;
  end
  else begin
    writeLn("error: {0} missing value for '{1}' within [{2}]", IniFileName, key, osIdentifier);
    exit;
  end;

  key := keyAudioPlayerCommandArgs;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerCommandArgs := kvpAudioPlayer.GetValue(key);

    if AudioPlayerCommandArgs.StartsWith('"') and
       AudioPlayerCommandArgs.EndsWith('"') then begin

      AudioPlayerCommandArgs := AudioPlayerCommandArgs.Trim(charsToStrip);
    end;

    AudioPlayerCommandArgs := AudioPlayerCommandArgs.Trim();
    if AudioPlayerCommandArgs.Length = 0 then begin
      writeLn("error: no value given for '{0}' within [{1}]", key, osIdentifier);
      exit;
    end;

    const placeholder = phAudioFilePath;
    const posPlaceholder = AudioPlayerCommandArgs.IndexOf(placeholder);
    if posPlaceholder = -1 then begin
      writeLn("error: {0} value does not contain placeholder '{1}'", key, placeholder);
      exit;
    end;
  end
  else begin
    writeLn("error: {0} missing value for '{1}' within [{2}]", IniFileName, key, osIdentifier);
    exit;
  end;

  key := keyAudioPlayerResumeArgs;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerResumeArgs := kvpAudioPlayer.GetValue(key);

    if AudioPlayerResumeArgs.StartsWith('"') and AudioPlayerResumeArgs.EndsWith('"') then begin
      AudioPlayerResumeArgs := AudioPlayerResumeArgs.Trim(charsToStrip);
    end;

    AudioPlayerResumeArgs := AudioPlayerResumeArgs.Trim();
    if AudioPlayerResumeArgs.Length > 0 then begin
      const placeholder = phStartSongTimeOffset;
      const posPlaceholder = AudioPlayerResumeArgs.IndexOf(placeholder);
      if posPlaceholder = -1 then begin
        writeLn("error: {0} value does not contain placeholder '{1}'", key, placeholder);
        writeLn("ignoring '{0}', using '{1}' for song resume", key, keyAudioPlayerCommandArgs);
        AudioPlayerResumeArgs := "";
      end;
    end;
  end;

  if AudioPlayerResumeArgs.Length = 0 then begin
    AudioPlayerResumeArgs := AudioPlayerCommandArgs;
  end;
end;

//*******************************************************************************

method Jukebox.PlaySongList(aSongList: List<SongMetadata>; Shuffle: Boolean);
begin
  SongList := aSongList;
  NumberSongs := aSongList.Count;
  SongIndex := 0;

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

  InstallSignalHandlers();

  ReadAudioPlayerConfig();

  if AudioPlayerExeFileName.Length = 0 then begin
    writeLn("error: no audio player configured");
    exit;
  end;

  if Shuffle then begin
    //TODO: the following code is buggy
    //var random := new Random;
    //var n := aSongList.Count;
    //while (n > 1) do begin
    //   dec(n);
    //   const k = random.NextInt(n + 1);
    //   var value := aSongList[k];
    //   aSongList[k] := aSongList[n];
    //   aSongList[n] := value;
    //end;
  end;

  writeLn("downloading first song...");

  if DownloadSong(aSongList[0]) then begin
    writeLn("first song downloaded. starting playing now.");

    const pidAsText = String.Format("{0}" + Environment.LineBreak, Utils.GetPid());
    const pidFilePath = Utils.PathJoin(JukeboxOptions.Directory, jukeboxPidFileName);
    Utils.FileWriteAllText(pidFilePath, pidAsText);

    try
      while true do begin
        if not ExitRequested then begin
          if not IsPaused then begin
            if SongIndex ≥ NumberSongs then begin
              SongIndex := 0;
            end;
            DownloadSongs;
            PlaySong(SongList[SongIndex]);
          end;
          if not IsPaused then begin
            inc(SongIndex);
            if SongIndex >= NumberSongs then begin
              SongIndex := 0;
            end;
          end else begin
            Utils.SleepSeconds(1);
          end;
        end
        else begin
          break
        end;
      end;
    finally
      Utils.DeleteFile(pidFilePath);
    end;
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

method Jukebox.ReadFileContents(FilePath: String): tuple of (Boolean, array of Byte);
var
  FileRead: Boolean;
  FileContents: array of Byte;
begin
  FileRead := false;

  FileContents := Utils.FileReadAllBytes(FilePath);
  if FileContents.Count = 0 then begin
    writeLn("error: unable to read file '{0}'", FilePath);
    var emptyBytes: array of Byte;
    result := (false, emptyBytes);
    exit;
  end
  else begin
    FileRead := true;
  end;

  result := (FileRead, FileContents);
end;

//*******************************************************************************

method Jukebox.UploadMetadataDb: Boolean;
var
  MetadataDbUpload: Boolean;
  HaveMetadataContainer: Boolean;
begin
  MetadataDbUpload := false;
  HaveMetadataContainer := false;
  if not StorageSystem.HasContainer(MetadataContainer) then
    HaveMetadataContainer :=
      StorageSystem.CreateContainer(MetadataContainer)
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
        MetadataDbUpload := StorageSystem.PutObject(MetadataContainer,
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
      if not StorageSystem.HasContainer(PlaylistContainer) then
        HaveContainer :=
          StorageSystem.CreateContainer(PlaylistContainer)
      else
        HaveContainer := true;

      if not HaveContainer then begin
        writeLn("error: unable to create container for playlists. unable to import");
        exit;
      end;

      for each FileName in DirListing do begin
        const FullPath = Utils.PathJoin(PlaylistImportDirPath, FileName);
        const ObjectName = FileName;
        (FileRead, FileContents) := ReadFileContents(FullPath);
        if FileRead then begin
          if StorageSystem.PutObject(PlaylistContainer,
                                     ObjectName,
                                     FileContents,
                                     nil) then begin
            writeLn("put of playlist succeeded");
            if not StoreSongPlaylist(ObjectName, FileContents) then begin
              writeLn("storing of playlist to db failed");
              _ := StorageSystem.DeleteObject(PlaylistContainer,
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
        writeLn("{0} playlists imported", FileImportCount);
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
  var ContainerContents :=
    StorageSystem.ListContainerContents(PlaylistContainer);

  const NumberPlaylists = ContainerContents.Count;
  if NumberPlaylists > 0 then begin
    for i := 0 to NumberPlaylists-1 do begin
      writeLn(ContainerContents[i]);
    end;
  end else begin
    writeLn("no playlists found");
  end;
end;

//*******************************************************************************

method Jukebox.RetrieveAlbumTrackObjectList(Artist: String;
                                            Album: String;
                                            ListTrackObjects: List<String>): Boolean;
begin
  var Success := false;
  const JsonFileName = String.Format("{0}{1}",
                                     JBUtils.EncodeArtistAlbum(Artist, Album),
                                     JsonFileExt);
  const LocalJsonFile = Utils.PathJoin(SongPlayDirPath, JsonFileName);
  if StorageSystem.GetObject(AlbumContainer,
                             JsonFileName,
                             LocalJsonFile) > 0 then begin

    const AlbumJsonContents = Utils.FileReadAllText(LocalJsonFile);
    if AlbumJsonContents.Length > 0 then begin
      var deserializer := new JsonDeserializer(AlbumJsonContents);
      const AlbumJson = deserializer.Deserialize();
      const TrackList = AlbumJson.Item["tracks"] as JsonArray;
      const NumberTracks = TrackList.Count;
      if NumberTracks > 0 then begin
        for i := 0 to NumberTracks-1 do begin
          const Track = TrackList.Item[i];
          ListTrackObjects.Add(Track.Item["object"].ToString());
        end;
        Success := true;
      end;
    end
    else begin
      writeLn("Album json file is empty");
    end;
  end
  else begin
    writeLn("Unable to retrieve '{0}' from '{1}'", JsonFileName, AlbumContainer);
  end;
  result := Success;
end;

//*******************************************************************************

method Jukebox.GetPlaylistSongs(Playlist: String;
                                ListSongs: List<SongMetadata>): Boolean;
begin
  var Success := false;
  const JsonFileName = String.Format("{0}{1}",
                                     JBUtils.EncodeValue(Playlist),
                                     JsonFileExt);
  const LocalJsonFile = Utils.PathJoin(SongPlayDirPath, JsonFileName);
  if StorageSystem.GetObject(PlaylistContainer,
                             JsonFileName,
                             LocalJsonFile) > 0 then begin

    const PlaylistJsonContents = Utils.FileReadAllText(LocalJsonFile);
    if PlaylistJsonContents.Length > 0 then begin
      var deserializer := new JsonDeserializer(PlaylistJsonContents);
      const PlaylistJson = deserializer.Deserialize();
      const theSongList = PlaylistJson.Item["songs"] as JsonArray;
      const plNumberSongs = theSongList.Count;
      if plNumberSongs > 0 then begin
        var SongsAdded := 0;
        var FileExtensions := new List<String>;
        FileExtensions.Add(".flac");
        FileExtensions.Add(".m4a");
        FileExtensions.Add(".mp3");

        for i := 0 to plNumberSongs-1 do begin
          const SongJson = theSongList.Item[i];
          const plArtist = SongJson.Item["artist"].ToString();
          const plAlbum = SongJson.Item["album"].ToString();
          const plSong = SongJson.Item["song"].ToString();
          const EncodedSong = JBUtils.EncodeArtistAlbumSong(plArtist,
                                                            plAlbum,
                                                            plSong);
          var SongFound := false;

          for each FileExtension in FileExtensions do begin
            const SongUid = EncodedSong + FileExtension;
            const Song = self.JukeboxDb.RetrieveSong(SongUid);
            if Song <> nil then begin
              ListSongs.Add(Song);
              inc(SongsAdded);
              SongFound := true;
              break;
            end;
          end;

          if not SongFound then begin
            writeLn("error: unable to retrieve metadata for '{0}'", EncodedSong);
          end;
        end;

        if SongsAdded > 0 then begin
          Success := true;
        end;
      end;
    end
    else begin
      writeLn("Playlist json file is empty");
    end;
  end
  else begin
    writeLn("Unable to retrieve '{0}' from '{1}'",
            JsonFileName,
            PlaylistContainer);
  end;
  result := Success;
end;

//*******************************************************************************

method Jukebox.ShowAlbum(Artist: String; Album: String);
begin
  var ListTrackObjects: List<String> := new List<String>;
  if RetrieveAlbumTrackObjectList(Artist, Album, ListTrackObjects) then begin
    writeLn("Album: {0} ({1}):", Album, Artist);
    var i: Integer := 1;
    for each SongObject in ListTrackObjects do begin
      const SongName = SongFromFileName(SongObject);
      writeLn("{0}  {1}", i, SongName);
      inc(i);
    end;
  end
  else begin
    writeLn("Unable to retrieve album '{0}/{1}'", Artist, Album);
  end;
end;

//*******************************************************************************

method Jukebox.ShowPlaylist(Playlist: String);
begin
  var ListSongs := new List<SongMetadata>;
  if GetPlaylistSongs(Playlist, ListSongs) then begin
    for each Song in ListSongs do begin
      writeLn("{0} : {1}", Song.SongName, Song.ArtistName);
    end;
  end
  else begin
    writeLn("unable to retrieve playlist {0} in {1}", Playlist, PlaylistContainer);
  end;
end;

//*******************************************************************************

method Jukebox.PlayPlaylist(Playlist: String);
begin
  //ScopePlaylist = Playlist;
  var PlaylistSongsFound := false;
  var theListSongs := new List<SongMetadata>;
  if GetPlaylistSongs(Playlist, theListSongs) then begin
    if theListSongs.Count > 0 then begin
      PlaylistSongsFound := true;
      PlaySongList(theListSongs, false);
    end
  end;

  if not PlaylistSongsFound then begin
    writeLn("error: unable to retrieve playlist songs");
  end;
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
            writeLn("error deleting song '{0}'", Song.Fm.ObjectName);
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
            writeLn("{0} {1}",
                    Song.Fm.ContainerName,
                    Song.Fm.ObjectName);
            // delete each song audio file
            if StorageSystem.DeleteObject(ContainerPrefix + Song.Fm.ContainerName,
                                          Song.Fm.ObjectName) then begin
              inc(NumSongsDeleted);
              // delete song metadata
              JukeboxDb.DeleteSong(Song.Fm.ObjectName);
            end
            else begin
              writeLn("error: unable to delete song {0}",
                      Song.Fm.ObjectName);
            end;
          end;
          if NumSongsDeleted > 0 then begin
            // upload metadata db
            UploadMetadataDb();
            AlbumDeleted := true;
          end
          else begin
            writeLn("no songs found for artist='{0}' album name='{1}'",
                    Artist,
                    AlbumName);
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
          writeLn("container='{0}', object='{1}'",
                  PlaylistContainer,
                  ObjectName);
          if StorageSystem.DeleteObject(PlaylistContainer,
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

      if not StorageSystem.HasContainer(AlbumArtContainer) then
        HaveContainer :=
          StorageSystem.CreateContainer(AlbumArtContainer)
      else
        HaveContainer := true;

      if not HaveContainer then begin
        writeLn("error: unable to create container for album art. unable to import");
        exit;
      end;

      for each FileName in DirListing do begin
        const FullPath = Utils.PathJoin(AlbumArtImportDirPath, FileName);
        const ObjectName = FileName;
        (FileRead, FileContents) := ReadFileContents(FullPath);
        if FileRead then begin
          if StorageSystem.PutObject(AlbumArtContainer,
                                     ObjectName,
                                     FileContents,
                                     nil) then begin
            inc(FileImportCount);
          end;
        end;
      end;

      if FileImportCount > 0 then begin
        writeLn("{0} album art files imported", FileImportCount);
      end
      else begin
        writeLn("no files imported");
      end;
    end;
  end;
end;

//*******************************************************************************

end.