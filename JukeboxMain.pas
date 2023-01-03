namespace MacOxygeneCloudJukebox;

interface

type
  JukeboxMain = public class
  private
    Artist: String;
    Album: String;
    Song: String;
    Playlist: String;
    DebugMode: Boolean;
    UpdateMode: Boolean;
    Directory: String;

  public
    constructor;
    method ConnectFsSystem(Credentials: PropertySet;
                           Prefix: String): StorageSystem;
    method ConnectS3System(Credentials: PropertySet;
                           Prefix: String): StorageSystem;
    method ConnectStorageSystem(SystemName: String;
                                Credentials: PropertySet;
                                Prefix: String): StorageSystem;
    method InitStorageSystem(StorageSys: StorageSystem): Boolean;
    method ShowUsage;
    method RunJukeboxCommand(jukebox: Jukebox; Command: String): Integer;
    method Run(ConsoleArgs: ImmutableList<String>): Int32;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor JukeboxMain;
begin
  DebugMode := false;
  UpdateMode := false;
end;

//*******************************************************************************

method JukeboxMain.ConnectFsSystem(Credentials: PropertySet;
                                   Prefix: String): StorageSystem;
begin
  if Credentials.Contains("root_dir") then begin
    const RootDir = Credentials.GetStringValue("root_dir");
    if DebugMode then begin
      writeLn("root_dir = '{0}'", RootDir);
    end;
    result := new FSStorageSystem(RootDir, DebugMode);
  end
  else begin
    writeLn("error: 'root_dir' must be specified in fs_creds.txt");
    result := nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.ConnectS3System(Credentials: PropertySet;
                                   Prefix: String): StorageSystem;
begin
  var AwsAccessKey := "";
  var AwsSecretKey := "";
  var UpdateAwsAccessKey := "";
  var UpdateAwsSecretKey := "";
  var Protocol := "";
  var Host := "";

  if Credentials.Contains("aws_access_key") then begin
    AwsAccessKey := Credentials.GetStringValue("aws_access_key");
  end;

  if Credentials.Contains("aws_secret_key") then begin
    AwsSecretKey := Credentials.GetStringValue("aws_secret_key");
  end;

  if Credentials.Contains("protocol") then begin
    Protocol := Credentials.GetStringValue("protocol");
  end;

  if Credentials.Contains("host") then begin
    Host := Credentials.GetStringValue("host");
  end;

  if Credentials.Contains("update_aws_access_key") and
     Credentials.Contains("update_aws_secret_key") then begin

    UpdateAwsAccessKey := Credentials.GetStringValue("update_aws_access_key");
    UpdateAwsSecretKey := Credentials.GetStringValue("update_aws_secret_key");
  end;

  if DebugMode then begin
    writeLn("aws_access_key={0}", AwsAccessKey);
    writeLn("aws_secret_key={0}", AwsSecretKey);
    if (UpdateAwsAccessKey.Length() > 0) and (UpdateAwsSecretKey.Length() > 0) then begin
      writeLn("update_aws_access_key={0}", UpdateAwsAccessKey);
      writeLn("update_aws_secret_key={0}", UpdateAwsSecretKey);
    end;
    writeLn("host={0}", Host);
  end;

  if (AwsAccessKey.Length() = 0) or (AwsSecretKey.Length() = 0) then begin
    writeLn("error: no s3 credentials given. please specify aws_access_key " +
            "and aws_secret_key in credentials file");
    exit nil;
  end
  else begin
    if Host.Length() = 0 then begin
      writeLn("error: no s3 host given. please specify host in credentials file");
      exit nil;
    end;

    var AccessKey := "";
    var SecretKey := "";

    if UpdateMode then begin
      AccessKey := UpdateAwsAccessKey;
      SecretKey := UpdateAwsSecretKey;
    end
    else begin
      AccessKey := AwsAccessKey;
      SecretKey := AwsSecretKey;
    end;

    result := new S3ExtStorageSystem(AccessKey,
                                     SecretKey,
                                     Protocol,
                                     Host,
                                     Prefix,
                                     DebugMode);
  end;
end;

//*******************************************************************************

method JukeboxMain.ConnectStorageSystem(SystemName: String;
                                        Credentials: PropertySet;
                                        Prefix: String): StorageSystem;
begin
  if SystemName = "fs" then begin
    result := ConnectFsSystem(Credentials, Prefix);
  end
  else if (SystemName = "s3") or (SystemName= "s3ext") then begin
    result := ConnectS3System(Credentials, Prefix);
  end
  else begin
    writeLn("error: unrecognized storage system {0}", SystemName);
    result := nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.InitStorageSystem(StorageSys: StorageSystem): Boolean;
var
  Success: Boolean;
begin
  if Jukebox.InitializeStorageSystem(StorageSys, DebugMode) then begin
    writeLn("storage system successfully initialized");
    Success := true;
  end
  else begin
    writeLn("error: unable to initialize storage system");
    Success := false;
  end;
  result := Success;
end;

//*******************************************************************************

method JukeboxMain.ShowUsage;
begin
  writeLn("Supported Commands:");
  writeLn("delete-album       - delete specified album");
  writeLn("delete-artist      - delete specified artist");
  writeLn("delete-playlist    - delete specified playlist");
  writeLn("delete-song        - delete specified song");
  writeLn("export-album       - FUTURE");
  writeLn("export-artist      - FUTURE");
  writeLn("export-playlist    - FUTURE");
  writeLn("help               - show this help message");
  writeLn("import-album-art   - import all album art from album-art-import subdirectory");
  writeLn("import-playlists   - import all new playlists from playlist-import subdirectory");
  writeLn("import-songs       - import all new songs from song-import subdirectory");
  writeLn("init-storage       - initialize storage system");
  writeLn("list-albums        - show listing of all available albums");
  writeLn("list-artists       - show listing of all available artists");
  writeLn("list-containers    - show listing of all available storage containers");
  writeLn("list-genres        - show listing of all available genres");
  writeLn("list-playlists     - show listing of all available playlists");
  writeLn("list-songs         - show listing of all available songs");
  writeLn("play               - start playing songs");
  writeLn("play-playlist      - play specified playlist");
  writeLn("show-album         - show songs in a specified album");
  writeLn("show-playlist      - show songs in specified playlist");
  writeLn("shuffle-play       - play songs randomly");
  writeLn("retrieve-catalog   - retrieve copy of music catalog");
  writeLn("upload-metadata-db - upload SQLite metadata");
  writeLn("usage              - show this help message");
  writeLn("");
end;

//*******************************************************************************

method JukeboxMain.RunJukeboxCommand(jukebox: Jukebox; Command: String): Integer;
var
  ExitCode: Integer;
  Shuffle: Boolean;
begin
  ExitCode := 0;
  Shuffle := false;

  if Command = "import-songs" then begin
    jukebox.ImportSongs();
  end
  else if Command = "import-playlists" then begin
    jukebox.ImportPlaylists();
  end
  else if Command = "play" then begin
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = "shuffle-play" then begin
    Shuffle := true;
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = "list-songs" then begin
    jukebox.ShowListings();
  end
  else if Command = "list-artists" then begin
    jukebox.ShowArtists();
  end
  else if Command = "list-containers" then begin
    jukebox.ShowListContainers();
  end
  else if Command = "list-genres" then begin
    jukebox.ShowGenres();
  end
  else if Command = "list-albums" then begin
    jukebox.ShowAlbums();
  end
  else if Command = "show-album" then begin
    if Artist.Length > 0 then begin
      if Album.Length > 0 then begin
        jukebox.ShowAlbum(Artist, Album);
      end
      else begin
        writeLn("error: album must be specified using --album option");
        ExitCode := 1;
      end;
    end
    else begin
      writeLn("error: artist must be specified using --artist option");
    end;
  end
  else if Command = "list-playlists" then begin
    jukebox.ShowPlaylists();
  end
  else if Command = "show-playlist" then begin
    if Playlist.Length > 0 then begin
      jukebox.ShowPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using --playlist option");
      ExitCode := 1;
    end;
  end
  else if Command = "play-playlist" then begin
    if Playlist.Length > 0 then begin
      jukebox.PlayPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using --playlist option");
      ExitCode := 1;
    end;
  end
  else if Command = "retrieve-catalog" then begin
    writeLn("retrieve-catalog not yet implemented");
  end
  else if Command = "delete-song" then begin
    if Song.Length > 0 then begin
      if jukebox.DeleteSong(Song, true) then begin
        writeLn("song deleted");
      end
      else begin
        writeLn("error: unable to delete song");
        ExitCode := 1;
      end;
    end
    else begin
      writeLn("error: song must be specified using --song option");
      ExitCode := 1;
    end
  end
  else if Command = "delete-artist" then begin
    if Artist.Length > 0 then begin
      if jukebox.DeleteArtist(Artist) then begin
        writeLn("artist deleted");
      end
      else begin
        writeLn("error: unable to delete artist");
        ExitCode := 1;
      end
    end
    else begin
      writeLn("error: artist must be specified using --artist option");
      ExitCode := 1;
    end;
  end
  else if Command = "delete-album" then begin
    if Album.Length > 0 then begin
      if jukebox.DeleteAlbum(Album) then begin
        writeLn("album deleted");
      end
      else begin
        writeLn("error: unable to delete album");
        ExitCode := 1;
      end;
    end
    else begin
      writeLn("error: album must be specified using --album option");
      ExitCode := 1;
    end;
  end
  else if Command = "delete-playlist" then begin
    if Playlist.Length > 0 then begin
      if jukebox.DeletePlaylist(Playlist) then begin
        writeLn("playlist deleted");
      end
      else begin
        writeLn("error: unable to delete playlist");
        ExitCode := 1;
      end;
    end
    else begin
      writeLn("error: playlist must be specified using --playlist option");
      ExitCode := 1;
    end;
  end
  else if Command = "upload-metadata-db" then begin
    if jukebox.UploadMetadataDb() then begin
      writeLn("metadata db uploaded");
    end
    else begin
      writeLn("error: unable to upload metadata db");
      ExitCode := 1;
    end;
  end
  else if Command = "import-album-art" then begin
    jukebox.ImportAlbumArt();
  end;

  result := ExitCode;
end;

//*******************************************************************************

method JukeboxMain.Run(ConsoleArgs: ImmutableList<String>): Int32;
var
  ExitCode: Integer;
  StorageType: String;
  SupportedSystems: StringSet;
  HelpCommands: StringSet;
  NonHelpCommands: StringSet;
  UpdateCommands: StringSet;
  AllCommands: StringSet;
  Creds: PropertySet;
begin
  ExitCode := 0;
  StorageType := "fs";
  Artist := "";
  Album := "";
  Song := "";
  Playlist := "";

  var OptParser := new ArgumentParser;
  OptParser.AddOptionalBoolFlag("--debug", "run in debug mode");
  OptParser.AddOptionalIntArgument("--file-cache-count", "number of songs to buffer in cache");
  OptParser.AddOptionalBoolFlag("--integrity-checks", "check file integrity after download");
  OptParser.AddOptionalBoolFlag("--compress", "use gzip compression");
  OptParser.AddOptionalBoolFlag("--encrypt", "encrypt file contents");
  OptParser.AddOptionalStringArgument("--key", "encryption key");
  OptParser.AddOptionalStringArgument("--keyfile", "path to file containing encryption key");
  OptParser.AddOptionalStringArgument("--storage", "storage system type (s3, swift, azure)");
  OptParser.AddOptionalStringArgument("--artist", "limit operations to specified artist");
  OptParser.AddOptionalStringArgument("--playlist", "limit operations to specified playlist");
  OptParser.AddOptionalStringArgument("--song", "limit operations to specified song");
  OptParser.AddOptionalStringArgument("--album", "limit operations to specified album");
  OptParser.AddOptionalStringArgument("--directory", "specify directory where audio player should run");
  OptParser.AddRequiredArgument("command", "command for jukebox");

  var Args := OptParser.ParseArgs(ConsoleArgs);
  if Args = nil then begin
    writeLn("error: unable to obtain command-line arguments");
    result := 1;
    exit;
  end;

  var Options := new JukeboxOptions;

  if Args.Contains("debug") then begin
    DebugMode := true;
    Options.DebugMode := true;
  end;

  if Args.Contains("file_cache_count") then begin
    const FileCacheCount = Args.GetIntValue("file_cache_count");
    if DebugMode then begin
      writeLn("setting file cache count={0}", FileCacheCount);
    end;
    Options.FileCacheCount := FileCacheCount;
  end;

  if Args.Contains("integrity_checks") then begin
    if DebugMode then begin
      writeLn("setting integrity checks on");
    end;
    Options.CheckDataIntegrity := true;
  end;

  if Args.Contains("compress") then begin
    if DebugMode then begin
      writeLn("setting compression on");
    end;
    Options.UseCompression := true;
  end;

  if Args.Contains("encrypt") then begin
    if DebugMode then begin
      writeLn("setting encryption on");
    end;
    Options.UseEncryption := true;
  end;

  if Args.Contains("key") then begin
    const Key = Args.GetStringValue("key");
    if DebugMode then begin
      writeLn("setting encryption key={0}", Key);
    end;
    Options.EncryptionKey := Key;
  end;

  if Args.Contains("keyfile") then begin
    const Keyfile = Args.GetStringValue("keyfile");
    if DebugMode then begin
      writeLn("reading encryption key file={0}", Keyfile);
    end;

    /*
    string encryption_key;
    if (Utils.FileReadAllText(keyfile, encryption_key) and
       encryption_key.Length > 0) {

      options.encryption_key = StrUtils::strip(encryption_key);
    } else {
      writeLn("error: unable to read key file {0}", keyfile);
      Utils.ProgramExit(1);
    }

    if (options.encryption_key.length() = 0) {
      writeLn("error: no key found in file {0}", keyfile);
      Utils.ProgramExit(1);
    }
    */
  end;

  if Args.Contains("storage") then begin
    const Storage = Args.GetStringValue("storage");
    SupportedSystems := new StringSet;
    SupportedSystems.Add("fs");
    SupportedSystems.Add("s3");
    if not SupportedSystems.Contains(Storage) then begin
      writeLn("error: invalid storage type {0}", Storage);
      //printf("supported systems are: %s\n", supported_systems.to_string());
      result := 1;
      exit;
    end
    else begin
      if DebugMode then begin
        writeLn("setting storage system to {0}", Storage);
      end;
      StorageType := Storage;
    end;
  end;

  if Args.Contains("artist") then begin
    Artist := Args.GetStringValue("artist");
  end;

  if Args.Contains("playlist") then begin
    Playlist := Args.GetStringValue("playlist");
  end;

  if Args.Contains("song") then begin
    Song := Args.GetStringValue("song");
  end;

  if Args.Contains("album") then begin
    Album := Args.GetStringValue("album");
  end;

  if Args.Contains("directory") then begin
    Directory := Args.GetStringValue("directory");
  end
  else begin
    Directory := Utils.GetCurrentDirectory();
  end;

  if Args.Contains("command") then begin
    if DebugMode then begin
      writeLn("using storage system type {0}", StorageType);
    end;
    const ContainerPrefix = "com.swampbits.jukebox.";
    const CredsFile = StorageType + "_creds.txt";
    Creds := new PropertySet;
    const CredsFilePath = Utils.PathJoin(Directory, CredsFile);

    if Utils.FileExists(CredsFilePath) then begin
      if DebugMode then begin
        writeLn("reading creds file {0}", CredsFilePath);
      end;

      const FileContents = Utils.FileReadAllText(CredsFilePath);
      if (FileContents <> nil) and (FileContents.Length > 0) then begin
        const FileLines = FileContents.Split("\n");

        for each FileLine in FileLines do begin
          const LineTokens = FileLine.Split("=");
          if LineTokens.Count = 2 then begin
            const Key = LineTokens[0].Trim();
            const Value = LineTokens[1].Trim();
            if (Key.Length > 0) and (Value.Length > 0) then begin
              Creds.Add(Key, new PropertyValue(Value));
            end;
          end;
        end;
      end
      else begin
        if DebugMode then begin
          writeLn("error: unable to read file {0}", CredsFilePath);
        end;
      end;
    end
    else begin
      writeLn("no creds file ({0})", CredsFilePath);
    end;

    Options.EncryptionIv := "sw4mpb1ts.juk3b0x";

    const Command = Args.GetStringValue("command");
    Args := nil;

    HelpCommands := new StringSet;
    HelpCommands.Add("help");
    HelpCommands.Add("usage");

    NonHelpCommands := new StringSet;
    NonHelpCommands.Add("import-songs");
    NonHelpCommands.Add("play");
    NonHelpCommands.Add("shuffle-play");
    NonHelpCommands.Add("list-songs");
    NonHelpCommands.Add("list-artists");
    NonHelpCommands.Add("list-containers");
    NonHelpCommands.Add("list-genres");
    NonHelpCommands.Add("list-albums");
    NonHelpCommands.Add("retrieve-catalog");
    NonHelpCommands.Add("import-playlists");
    NonHelpCommands.Add("list-playlists");
    NonHelpCommands.Add("show-album");
    NonHelpCommands.Add("show-playlist");
    NonHelpCommands.Add("play-playlist");
    NonHelpCommands.Add("delete-song");
    NonHelpCommands.Add("delete-album");
    NonHelpCommands.Add("delete-playlist");
    NonHelpCommands.Add("delete-artist");
    NonHelpCommands.Add("upload-metadata-db");
    NonHelpCommands.Add("import-album-art");

    UpdateCommands := new StringSet;
    UpdateCommands.Add("import-songs");
    UpdateCommands.Add("import-playlists");
    UpdateCommands.Add("delete-song");
    UpdateCommands.Add("delete-album");
    UpdateCommands.Add("delete-playlist");
    UpdateCommands.Add("delete-artist");
    UpdateCommands.Add("upload-metadata-db");
    UpdateCommands.Add("import-album-art");
    UpdateCommands.Add("init-storage");

    AllCommands := new StringSet;
    AllCommands.Append(HelpCommands);
    AllCommands.Append(NonHelpCommands);
    AllCommands.Append(UpdateCommands);

    if not AllCommands.Contains(Command) then begin
      writeLn("Unrecognized command {0}", Command);
      writeLn("");
      ShowUsage();
    end
    else begin
      if HelpCommands.Contains(Command) then begin
        ShowUsage();
      end
      else begin
        //if not Options.ValidateOptions() then begin
        //  Utils.ProgramExit(1);
        //end;

        if Command = "upload-metadata-db" then begin
          Options.SuppressMetadataDownload := true;
        end
        else begin
          Options.SuppressMetadataDownload := false;
        end;

        if UpdateCommands.Contains(Command) then begin
          UpdateMode := true;
        end;

        Options.Directory := Directory;

        var StorageSystem := ConnectStorageSystem(StorageType,
                                                  Creds,
                                                  ContainerPrefix);

        if StorageSystem = nil then begin
          writeLn("error: unable to connect to storage system");
          result := 1;
          exit;
        end;

        if not StorageSystem.Enter() then begin
          writeLn("error: unable to enter storage system");
          result := 1;
          exit;
        end;

        if Command = "init-storage" then begin
          if InitStorageSystem(StorageSystem) then begin
            result := 0
          end
          else begin
            result := 1;
          end;
          exit;
        end;

        const jukebox = new Jukebox(Options, StorageSystem, DebugMode);
        if jukebox.Enter() then begin
          ExitCode := RunJukeboxCommand(jukebox, Command);
        end
        else begin
          writeLn("error: unable to enter jukebox");
          ExitCode := 1;
        end;
      end;
    end;
  end
  else begin
    writeLn("Error: no command given");
    ShowUsage();
  end;

  result := ExitCode;
end;

//*******************************************************************************

end.