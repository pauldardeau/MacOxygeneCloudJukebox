namespace MacOxygeneCloudJukebox;

uses
  rtl, CloudJukeboxSharedProject;

interface

type
  Jukebox = public class
  public
    const DOUBLE_DASHES = "--";

    // container suffixes
    const SFX_ALBUM_CONTAINER = "albums";
    const SFX_ALBUM_ART_CONTAINER = "album-art";
    const SFX_METADATA_CONTAINER = "music-metadata";
    const SFX_PLAYLIST_CONTAINER = "playlists";
    const SFX_SONG_CONTAINER = "-artist-songs";

    // directories
    const DIR_ALBUM_ART_IMPORT = "album-art-import";
    const DIR_PLAYLIST_IMPORT = "playlist-import";
    const DIR_SONG_IMPORT = "song-import";
    const DIR_SONG_PLAY = "song-play";

    // files
    const DOWNLOAD_EXTENSION = ".download";
    const JUKEBOX_PID_FILE_NAME = "jukebox.pid";
    const JSON_FILE_EXT = ".json";
    const SETTINGS_INI_FILE_NAME = "settings.ini";
    const DEFAULT_DB_FILE_NAME = "jukebox_db.sqlite3";

    // audio file INI
    const AUDIO_INI_FILE_NAME = "audio_player.ini";
    const AUDIO_PLAYER_EXE_FILE_NAME = "audio_player_exe_file_name";
    const AUDIO_PLAYER_COMMAND_ARGS = "audio_player_command_args";
    const AUDIO_PLAYER_RESUME_ARGS = "audio_player_resume_args";

    // placeholders
    const PH_AUDIO_FILE_PATH = "%%AUDIO_FILE_PATH%%";
    const PH_START_SONG_TIME_OFFSET = "%%START_SONG_TIME_OFFSET%%";

  {$IFNDEF WINDOWS}
  public
    GlobalJukebox: Jukebox := nil; static;
  {$ENDIF}

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
    PlayerRunner: AudioPlayerRunner;
    PlayerTerminated: Boolean;
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
    AudioIniFilePath: String;
    SettingsIniFilePath: String;

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
    method StoreSongMetadata(FsSong: SongMetadata): Boolean;
    method StoreSongPlaylist(FileName: String;
                             FileContents: array of Byte): Boolean;
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
    method GetAlbumTrackObjectList(Artist: String;
                                   AlbumName: String;
                                   ListTrackObjects: List<String>): Boolean;
    method GetPlaylistSongs(PlaylistName: String;
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
    const ContainerName = aContainerPrefix +
      String.Format("{0}{1}", ch, SFX_SONG_CONTAINER);
    if not StorageSys.CreateContainer(ContainerName) then begin
      writeLn("error: unable to create container '{0}'", ContainerName);
      exit false;
    end;
  end;

  // create the other (non-song) containers
  const ContainerNames = new List<String>;
  ContainerNames.Add(SFX_METADATA_CONTAINER);
  ContainerNames.Add(SFX_ALBUM_ART_CONTAINER);
  ContainerNames.Add(SFX_ALBUM_CONTAINER);
  ContainerNames.Add(SFX_PLAYLIST_CONTAINER);

  for each ContainerName in ContainerNames do begin
    const CnrName = aContainerPrefix + ContainerName;
    if not StorageSys.CreateContainer(CnrName) then begin
      writeLn("error: unable to create container '{0}'", CnrName);
      exit false;
    end;
  end;

  // delete metadata DB file if present
  const MetadataDbFile = DEFAULT_DB_FILE_NAME;
  if Utils.FileExists(MetadataDbFile) then begin
    if aDebugPrint then begin
      writeLn("deleting existing metadata DB file");
    end;
    Utils.DeleteFile(MetadataDbFile);
  end;

  exit true;
end;

//*******************************************************************************

constructor Jukebox(JbOptions: JukeboxOptions;
                    StorageSys: StorageSystem;
                    aContainerPrefix: String;
                    aDebugPrint: Boolean);
begin
  {$IFNDEF WINDOWS}
  if GlobalJukebox = nil then begin
    GlobalJukebox := self;
  end
  else begin
    //TODO: throw an exception (only 1 Jukebox instance allowed)
  end;
  {$ENDIF}

  JukeboxOptions := JbOptions;
  StorageSystem := StorageSys;
  DebugPrint := aDebugPrint;
  JukeboxDb := nil;
  ContainerPrefix := aContainerPrefix;
  CurrentDir := JbOptions.Directory;
  SongImportDirPath := Utils.PathJoin(CurrentDir, DIR_SONG_IMPORT);
  PlaylistImportDirPath := Utils.PathJoin(CurrentDir, DIR_PLAYLIST_IMPORT);
  SongPlayDirPath := Utils.PathJoin(CurrentDir, DIR_SONG_PLAY);
  AlbumArtImportDirPath := Utils.PathJoin(CurrentDir, DIR_ALBUM_ART_IMPORT);
  MetadataDbFile := DEFAULT_DB_FILE_NAME;
  MetadataContainer := ContainerPrefix + SFX_METADATA_CONTAINER;
  PlaylistContainer := ContainerPrefix + SFX_PLAYLIST_CONTAINER;
  AlbumContainer := ContainerPrefix + SFX_ALBUM_CONTAINER;
  AlbumArtContainer := ContainerPrefix + SFX_ALBUM_ART_CONTAINER;
  SongList := new List<SongMetadata>();
  NumberSongs := 0;
  SongIndex := -1;
  AudioPlayerExeFileName := "";
  AudioPlayerCommandArgs := "";
  AudioPlayerResumeArgs := "";
  PlayerRunner := nil;
  PlayerTerminated := false;
  SongPlayLengthSeconds := 20;
  CumulativeDownloadBytes := 0;
  CumulativeDownloadTime := 0;
  ExitRequested := false;
  IsPaused := false;
  SongSecondsOffset := 0;
  SongPlayIsResume := false;
  IsRepeatMode := false;
  Downloader := nil;
  DownloadThread := nil;
  AudioIniFilePath := Utils.PathJoin(JbOptions.Directory, AUDIO_INI_FILE_NAME);
  SettingsIniFilePath := Utils.PathJoin(JbOptions.Directory, SETTINGS_INI_FILE_NAME);

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
  {$IFNDEF WINDOWS}
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
  {$ENDIF}
end;

//*******************************************************************************

method Jukebox.InstallSignalHandlers;
begin
  {$IFNDEF WINDOWS}
  var lAct := new __struct_sigaction;
  lAct.sa_flags := SA_SIGINFO;
  lAct.__sigaction_u.__sa_handler := @SigHandler;

  // setup the sigterm handler
  sigaction(SIGUSR1, @lAct, nil);
  sigaction(SIGUSR2, @lAct, nil);
  sigaction(SIGINT, @lAct, nil);
  sigaction(SIGWINCH, @lAct, nil);
  {$ENDIF}
end;

//*******************************************************************************

method Jukebox.IsExitRequested: Boolean;
begin
  exit ExitRequested;
end;

//*******************************************************************************

method Jukebox.Enter: Boolean;
begin
  var EnterSuccess := false;

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

    JukeboxDb := new JukeboxDB(GetMetadataDbFilePath(), DebugPrint);
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

  exit EnterSuccess;
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
    if PlayerRunner <> nil then begin
      // capture current song position (seconds into song)
      PlayerRunner.Stop;
      PlayerTerminated := true;
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
  if PlayerRunner <> nil then begin
    PlayerRunner.Stop;
    PlayerTerminated := true;
  end;
end;

//*******************************************************************************

method Jukebox.PrepareForTermination;
begin
  writeLn("Ctrl-C detected, shutting down");

  // indicate that it's time to shutdown
  ExitRequested := true;

  // terminate audio player if it's running
  if PlayerRunner <> nil then begin
    PlayerRunner.Stop;
    PlayerTerminated := true;
  end;
end;

//*******************************************************************************

method Jukebox.DisplayInfo;
begin
  if SongList.Count > 0 then begin
    const MaxIndex = SongList.Count - 1;
    if (SongIndex+3) <= MaxIndex then begin
      writeLn("----- songs on deck -----");
      const firstSong = SongList[SongIndex+1];
      writeLn(firstSong.Fm.FileUid);
      const secondSong = SongList[SongIndex+2];
      writeLn(secondSong.Fm.FileUid);
      const thirdSong = SongList[SongIndex+3];
      writeLn(thirdSong.Fm.FileUid);
      writeLn("-------------------------");
    end;
  end;
end;

//*******************************************************************************

method Jukebox.GetMetadataDbFilePath: String;
begin
  exit Utils.PathJoin(CurrentDir, MetadataDbFile);
end;

//*******************************************************************************

method Jukebox.StoreSongMetadata(FsSong: SongMetadata): Boolean;
begin
  var StoreSuccess := false;
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
  exit StoreSuccess;
end;

//*******************************************************************************

method Jukebox.StoreSongPlaylist(FileName: String;
                                 FileContents: array of Byte): Boolean;
begin
  //TODO: implement StoreSongPlaylist
  exit false;
end;

//*******************************************************************************

method Jukebox.ContainerForSong(SongUid: String): String;
begin
  if SongUid.Length = 0 then begin
    exit "";
  end;

  const Artist = JBUtils.ArtistFromFileName(SongUid);
  if Artist.Length = 0 then begin
    exit "";
  end;

  var ArtistLetter: String;

  if Artist.StartsWith("A ") then begin
    ArtistLetter := Artist[2];
  end
  else if Artist.StartsWith("The ") then begin
    ArtistLetter := Artist[4];
  end
  else begin
    ArtistLetter := Artist[0];
  end;

  exit ContainerPrefix + ArtistLetter.ToLower + SFX_SONG_CONTAINER;
end;

//*******************************************************************************

method Jukebox.ImportSongs;
begin
  if JukeboxDb <> nil then begin
    if not JukeboxDb.IsOpen() then begin
      exit;
    end;

    const DirListing = Utils.ListFilesInDirectory(SongImportDirPath);
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
          const artist = JBUtils.ArtistFromFileName(FileName);
          const album = JBUtils.AlbumFromFileName(FileName);
          const song = JBUtils.SongFromFileName(FileName);

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
            //fsSong.Fm.FileTime = oFile.DateModified  // DateModified is a DateTime
            fsSong.ArtistName := artist;
            fsSong.SongName := song;
            const md5Hash = Utils.Md5ForFile(SettingsIniFilePath, FullPath);
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

                const ContainerName = ContainerPrefix + fsSong.Fm.ContainerName;

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
  exit Utils.PathJoin(SongPlayDirPath, Song.Fm.FileUid);
end;

//*******************************************************************************

method Jukebox.CheckFileIntegrity(Song: SongMetadata): Boolean;
begin
  var FileIntegrityPassed := true;

  if JukeboxOptions.CheckDataIntegrity then begin
    const FilePath = SongPathInPlaylist(Song);
    if Utils.FileExists(FilePath) then begin
      if DebugPrint then
        writeLn("checking integrity for {0}", Song.Fm.FileUid);

      const PlaylistMd5 = Utils.Md5ForFile(SettingsIniFilePath, FilePath);
      if PlaylistMd5.Length = 0 then begin
        writeLn("error: unable to calculate MD5 hash for file '{0}'",
                FilePath);
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
      writeLn("file integrity bypassed, no jukebox options or check integrity " +
              "not turned on");
  end;

  exit FileIntegrityPassed;
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
begin
  var BytesRetrieved: Int64 := 0;

  if DirPath.Length > 0 then begin
    const ContainerName = ContainerPrefix + Fm.ContainerName;
    const LocalFilePath = Utils.PathJoin(DirPath, Fm.FileUid);
    BytesRetrieved := StorageSystem.GetObject(ContainerName,
                                              Fm.ObjectName,
                                              LocalFilePath);
  end;

  exit BytesRetrieved;
end;

//*******************************************************************************

method Jukebox.DownloadSong(Song: SongMetadata): Boolean;
begin
  if ExitRequested then begin
    exit false;
  end;

  const FilePath = SongPathInPlaylist(Song);
  const SongBytesRetrieved = RetrieveFile(Song.Fm, SongPlayDirPath);
  if ExitRequested then begin
    exit false;
  end;

  if DebugPrint then begin
    writeLn("bytes retrieved: {0}", SongBytesRetrieved);
  end;

  if SongBytesRetrieved > 0 then begin
    CumulativeDownloadBytes := CumulativeDownloadBytes + SongBytesRetrieved;

    // are we checking data integrity?
    // if so, verify that the storage system retrieved the same length that
    // has been stored
    if JukeboxOptions.CheckDataIntegrity then begin
      if DebugPrint then begin
        writeLn("verifying data integrity");
      end;

      if SongBytesRetrieved <> Song.Fm.StoredFileSize then begin
        writeLn("error: file size check failed for '{0}'", FilePath);
        exit false;
      end;
    end;

    if CheckFileIntegrity(Song) then begin
      exit true;
    end
    else begin
      // we retrieved the file, but it failed our integrity check
      // if file exists, remove it
      if Utils.FileExists(FilePath) then begin
        Utils.DeleteFile(FilePath);
      end;
    end;
  end;

  exit false;
end;

//*******************************************************************************

method Jukebox.PlaySong(Song: SongMetadata);
begin
  var ExitCode := -1;

  const SongFilePath = SongPathInPlaylist(Song);

  if Utils.FileExists(SongFilePath) then begin
    writeLn("playing {0}", Song.Fm.FileUid);
    if AudioPlayerExeFileName.Length > 0 then begin
      var didResume := false;
      var CommandArgs := "";
      if SongPlayIsResume then begin
        const Placeholder = PH_START_SONG_TIME_OFFSET;
        const PosPlaceholder =
            AudioPlayerResumeArgs.IndexOf(Placeholder);
        if PosPlaceholder > -1 then begin
          CommandArgs := AudioPlayerResumeArgs;
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
          CommandArgs := CommandArgs.Replace(PH_START_SONG_TIME_OFFSET, theSongStartTime);
          CommandArgs := CommandArgs.Replace(PH_AUDIO_FILE_PATH, SongFilePath);
          didResume := true;
          //writeLn("CommandArgs: '{0}'", CommandArgs);
        end;
      end;

      if not didResume then begin
        CommandArgs := AudioPlayerCommandArgs;
        CommandArgs := CommandArgs.Replace(PH_AUDIO_FILE_PATH, SongFilePath);
      end;

      const Args = CommandArgs.Split(" ");
      PlayerTerminated := false;
      PlayerRunner := new AudioPlayerRunner(AudioPlayerExeFileName,
                                            SongPlayDirPath,
                                            Args);
      PlayerRunner.PlaySong;
      if not PlayerTerminated then begin
        ExitCode := PlayerRunner.GetExitCode;
        PlayerRunner := nil;

        // if the audio player failed or is not present, just sleep
        // for the length of time that audio would be played
        if ExitCode <> 0 then begin
          Utils.SleepSeconds(SongPlayLengthSeconds);
        end;
      end
      else begin
        PlayerTerminated := false;
        PlayerRunner := nil;
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
    Utils.FileAppendAllText(FileNotFoundPath,
                            SongFilePath + Environment.LineBreak);
  end;
end;

//*******************************************************************************

method Jukebox.DownloadSongs;
begin
  // scan the play list directory to see if we need to download more songs
  const DirListing = Utils.ListFilesInDirectory(SongPlayDirPath);
  if DirListing.Count = 0 then begin
    // log error
    exit;
  end;

  const DlSongs = new List<SongMetadata>;

  var SongFileCount := 0;
  for each FileName in DirListing do begin
    const FileExtension = Utils.GetFileExtension(FileName);

    if (FileExtension.Length > 0) and
       (FileExtension <> DOWNLOAD_EXTENSION) then begin

      inc(SongFileCount);
    end;
  end;

  const FileCacheCount = JukeboxOptions.FileCacheCount;

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
        writeLn("Not downloading more songs b/c Downloader <> nil or " +
                "DownloadThread <> nil");
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
      const aSongList = new List<SongMetadata>;
      const ListTrackObjects = new List<String>;
      if GetAlbumTrackObjectList(Artist, Album, ListTrackObjects) then begin
        if ListTrackObjects.Count > 0 then begin
          for each TrackObjectName in ListTrackObjects do begin
            const Song = JukeboxDb.RetrieveSong(TrackObjectName);
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
  if not Utils.FileExists(AudioIniFilePath) then begin
    writeLn("error: missing {0} config file", AudioIniFilePath);
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

  const iniReader = new IniReader(AudioIniFilePath);
  if not iniReader.ReadFile() then begin
    writeLn("error: unable to read ini config file '{0}'",
            AudioIniFilePath);
    exit;
  end;

  var kvpAudioPlayer := new KeyValuePairs();
  if not iniReader.ReadSection(osIdentifier, var kvpAudioPlayer) then begin
    writeLn("error: no config section present for '{0}'",
            osIdentifier);
    exit;
  end;

  var key := AUDIO_PLAYER_EXE_FILE_NAME;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerExeFileName := kvpAudioPlayer.GetValue(key);

    if AudioPlayerExeFileName.StartsWith('"') and
       AudioPlayerExeFileName.EndsWith('"') then begin

      AudioPlayerExeFileName :=
        AudioPlayerExeFileName.Trim(charsToStrip);
    end;

    AudioPlayerExeFileName := AudioPlayerExeFileName.Trim();

    if AudioPlayerExeFileName.Length = 0 then begin
      writeLn("error: no value given for '{0}' within [{1}]",
              key, osIdentifier);
      exit;
    end;

    if DebugPrint then begin
      writeLn("audio player: '{0}'", AudioPlayerExeFileName);
    end;
  end
  else begin
    writeLn("error: {0} missing value for '{1}' within [{2}]",
            AUDIO_INI_FILE_NAME, key, osIdentifier);
    exit;
  end;

  key := AUDIO_PLAYER_COMMAND_ARGS;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerCommandArgs := kvpAudioPlayer.GetValue(key);

    if AudioPlayerCommandArgs.StartsWith('"') and
       AudioPlayerCommandArgs.EndsWith('"') then begin

      AudioPlayerCommandArgs :=
        AudioPlayerCommandArgs.Trim(charsToStrip);
    end;

    AudioPlayerCommandArgs := AudioPlayerCommandArgs.Trim();
    if AudioPlayerCommandArgs.Length = 0 then begin
      writeLn("error: no value given for '{0}' within [{1}]",
              key, osIdentifier);
      exit;
    end;

    const placeholder = PH_AUDIO_FILE_PATH;
    const posPlaceholder = AudioPlayerCommandArgs.IndexOf(placeholder);
    if posPlaceholder = -1 then begin
      writeLn("error: {0} value does not contain placeholder '{1}'",
              key, placeholder);
      exit;
    end;
  end
  else begin
    writeLn("error: {0} missing value for '{1}' within [{2}]",
            AUDIO_INI_FILE_NAME, key, osIdentifier);
    exit;
  end;

  key := AUDIO_PLAYER_RESUME_ARGS;

  if kvpAudioPlayer.ContainsKey(key) then begin
    AudioPlayerResumeArgs := kvpAudioPlayer.GetValue(key).Trim;

    if AudioPlayerResumeArgs.StartsWith('"') and
       AudioPlayerResumeArgs.EndsWith('"') then begin

      AudioPlayerResumeArgs := AudioPlayerResumeArgs.Trim(charsToStrip);
    end;

    AudioPlayerResumeArgs := AudioPlayerResumeArgs.Trim();
    if AudioPlayerResumeArgs.Length > 0 then begin
      const placeholder = PH_START_SONG_TIME_OFFSET;
      const posPlaceholder = AudioPlayerResumeArgs.IndexOf(placeholder);
      if posPlaceholder = -1 then begin
        writeLn("error: {0} value does not contain placeholder '{1}'",
                key, placeholder);
        writeLn("ignoring '{0}', using '{1}' for song resume",
                key, AUDIO_PLAYER_COMMAND_ARGS);
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
      writeLn("{0} directory does not exist, creating it", DIR_SONG_PLAY);
    end;
    Utils.CreateDirectory(SongPlayDirPath);
  end
  else begin
    // play list directory exists, delete any files in it
    if DebugPrint then begin
      writeLn("deleting existing files in {0} directory", DIR_SONG_PLAY);
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
    Utils.ShuffleList(aSongList);
  end;

  writeLn("downloading first song...");

  if DownloadSong(aSongList[0]) then begin
    writeLn("first song downloaded. starting playing now.");

    const pidAsText = String.Format("{0}{1}", Utils.GetPid(), Environment.LineBreak);
    const pidFilePath = Utils.PathJoin(JukeboxOptions.Directory,
                                       JUKEBOX_PID_FILE_NAME);
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
begin
  const FileContents = Utils.FileReadAllBytes(FilePath);
  if FileContents.Count = 0 then begin
    writeLn("error: unable to read file '{0}'", FilePath);
    var emptyBytes: array of Byte;
    exit (false, emptyBytes);
  end;

  exit (true, FileContents);
end;

//*******************************************************************************

method Jukebox.UploadMetadataDb: Boolean;
begin
  var MetadataDbUpload := false;
  var HaveMetadataContainer := false;
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

  exit MetadataDbUpload;
end;

//*******************************************************************************

method Jukebox.ImportPlaylists;
var
  FileRead: Boolean;
  FileContents: array of Byte;
begin
  if JukeboxDb <> nil then begin
    if JukeboxDb.IsOpen() then begin
      var FileImportCount := 0;
      const DirListing = Utils.ListFilesInDirectory(PlaylistImportDirPath);
      if DirListing.Count = 0 then begin
        writeLn("no playlists found");
        exit;
      end;

      var HaveContainer := false;
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
  const ContainerContents =
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

method Jukebox.GetAlbumTrackObjectList(Artist: String;
                                       AlbumName: String;
                                       ListTrackObjects: List<String>): Boolean;
begin
  var Success := false;
  const EncodedArtistAlbum = JBUtils.EncodeArtistAlbum(Artist, AlbumName);
  const JsonFileName = String.Format("{0}{1}",
                                     EncodedArtistAlbum,
                                     JSON_FILE_EXT);
  const LocalJsonFile = Utils.PathJoin(SongPlayDirPath, JsonFileName);
  if StorageSystem.GetObject(AlbumContainer,
                             JsonFileName,
                             LocalJsonFile) > 0 then begin

    const AlbumJsonContents = Utils.FileReadAllText(LocalJsonFile);
    if AlbumJsonContents.Length > 0 then begin
      const Deserializer = new JsonDeserializer(AlbumJsonContents);
      {$IFDEF DARWIN}
      const AlbumJson = Deserializer.Deserialize;
      const TrackList = AlbumJson.Item["tracks"] as JsonArray;
      if TrackList <> nil then begin
        const NumberTracks = TrackList.Count;
        if NumberTracks > 0 then begin
          for i := 0 to NumberTracks-1 do begin
            const Track = TrackList.Item[i];
            const TrackObject = Track.Item["object"];
            if TrackObject <> nil then begin
              ListTrackObjects.Add(TrackObject.ToString());
            end;
          end;
          Success := true;
        end;
      end;
      {$ELSE}
      const Album = Deserializer.Read<Album>;
      if Album <> nil then begin
        const NumberTracks = Album.Tracks.Count;
        if NumberTracks > 0 then begin
          for i := 0 to NumberTracks-1 do begin
            const Track = Album.Tracks.Item[i];
            ListTrackObjects.Add(Track.ObjectName);
          end;
          Success := true;
        end;
      end;
      {$ENDIF}
    end
    else begin
      writeLn("Album json file is empty");
    end;
  end
  else begin
    writeLn("Unable to retrieve '{0}' from '{1}'",
            JsonFileName, AlbumContainer);
  end;
  exit Success;
end;

//*******************************************************************************

method Jukebox.GetPlaylistSongs(PlaylistName: String;
                                ListSongs: List<SongMetadata>): Boolean;
begin
  var Success := false;
  const JsonFileName = String.Format("{0}{1}",
                                     JBUtils.EncodeValue(PlaylistName),
                                     JSON_FILE_EXT);
  const LocalJsonFile = Utils.PathJoin(SongPlayDirPath, JsonFileName);
  if StorageSystem.GetObject(PlaylistContainer,
                             JsonFileName,
                             LocalJsonFile) > 0 then begin

    const PlaylistJsonContents = Utils.FileReadAllText(LocalJsonFile);
    if PlaylistJsonContents.Length > 0 then begin
      const FileExtensions = new List<String>;
      FileExtensions.Add(".flac");
      FileExtensions.Add(".m4a");
      FileExtensions.Add(".mp3");

      const Deserializer = new JsonDeserializer(PlaylistJsonContents);

      {$IFDEF DARWIN}
      const PlaylistJson = Deserializer.Deserialize;
      const TheSongList = PlaylistJson.Item["songs"] as JsonArray;
      if TheSongList <> nil then begin
        const plNumberSongs = TheSongList.Count;
        if plNumberSongs > 0 then begin
          var SongsAdded := 0;

          for i := 0 to plNumberSongs-1 do begin
            const SongJson = TheSongList.Item[i];

            const ItemArtist = SongJson.Item["artist"];
            const ItemAlbum = SongJson.Item["album"];
            const ItemSong = SongJson.Item["song"];

            if (ItemArtist <> nil) and (ItemAlbum <> nil) and (ItemSong <> nil) then begin
              const PlArtist = ItemArtist.ToString();
              const PlAlbum = ItemAlbum.ToString();
              const PlSong = ItemSong.ToString();
              const EncodedSong = JBUtils.EncodeArtistAlbumSong(PlArtist,
                                                                PlAlbum,
                                                                PlSong);
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
            end
            else begin
              if DebugPrint then begin
                writeLn("error: JSON missing one or more of ['artist', 'album', 'song']");
              end;
            end;
          end;

          if SongsAdded > 0 then begin
            Success := true;
          end;
        end;
      end;
      {$ELSE}
      const Playlist = Deserializer.Read<Playlist>;
      if Playlist <> nil then begin
        if Playlist.Songs.Count > 0 then begin
          var SongsAdded := 0;

          for each plSongObj in Playlist.Songs do begin
            const plArtist = plSongObj.Artist;
            const plAlbum = plSongObj.Album;
            const plSong = plSongObj.Song;
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
              writeLn("error: unable to retrieve metadata for '{0}'",
                      EncodedSong);
            end;
          end;

          if SongsAdded > 0 then begin
            Success := true;
          end;
        end;
      end;
      {$ENDIF}
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
  exit Success;
end;

//*******************************************************************************

method Jukebox.ShowAlbum(Artist: String; Album: String);
begin
  const ListTrackObjects: List<String> = new List<String>;
  if GetAlbumTrackObjectList(Artist, Album, ListTrackObjects) then begin
    writeLn("Album: {0} ({1}):", Album, Artist);
    var i: Integer := 1;
    for each SongObject in ListTrackObjects do begin
      const SongName = JBUtils.SongFromFileName(SongObject);
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
  const ListSongs = new List<SongMetadata>;
  if GetPlaylistSongs(Playlist, ListSongs) then begin
    for each Song in ListSongs do begin
      writeLn("{0} : {1}", Song.SongName, Song.ArtistName);
    end;
  end
  else begin
    writeLn("unable to retrieve playlist {0} in {1}",
            Playlist, PlaylistContainer);
  end;
end;

//*******************************************************************************

method Jukebox.PlayPlaylist(Playlist: String);
begin
  //ScopePlaylist = Playlist;
  var PlaylistSongsFound := false;
  const theListSongs = new List<SongMetadata>;
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
  PlaySongs(false, Artist, Album);
end;

//*******************************************************************************

method Jukebox.DeleteSong(SongUid: String; UploadMetadata: Boolean): Boolean;
begin
  var IsDeleted := false;
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

  exit IsDeleted;
end;

//*******************************************************************************

method Jukebox.DeleteArtist(Artist: String): Boolean;
begin
  var IsDeleted := false;
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
            exit false;
          end;
        end;
        UploadMetadataDb;
        IsDeleted := true;
      end;
    end;
  end;

  exit IsDeleted;
end;

//*******************************************************************************

method Jukebox.DeleteAlbum(Album: String): Boolean;
begin
  var AlbumDeleted := false;
  const ContainsDoubleDash = Album.Contains(DOUBLE_DASHES);
  if ContainsDoubleDash then begin
    const NameComponents = Album.Split(DOUBLE_DASHES);
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
            //DIFFERENCE
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

  exit AlbumDeleted;
end;

//*******************************************************************************

method Jukebox.DeletePlaylist(PlaylistName: String): Boolean;
begin
  var IsDeleted := false;
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

  exit IsDeleted;
end;

//*******************************************************************************

method Jukebox.ImportAlbumArt;
var
  FileRead: Boolean;
  FileContents: array of Byte;
begin
  if JukeboxDb <> nil then begin
    if JukeboxDb.IsOpen then begin
      var FileImportCount := 0;
      const DirListing = Utils.ListFilesInDirectory(AlbumArtImportDirPath);
      if DirListing.Count = 0 then begin
        writeLn("no album art found");
        exit;
      end;

      var HaveContainer := false;

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