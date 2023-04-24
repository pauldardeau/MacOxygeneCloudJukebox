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
    //const MetadataFileSuffix = '.meta';
    const argPrefix          = "--";
    const argDebug           = "debug";
    const argFileCacheCount  = "file-cache-count";
    const argIntegrityChecks = "integrity-checks";
    const argStorage         = "storage";
    const argArtist          = "artist";
    const argPlaylist        = "playlist";
    const argSong            = "song";
    const argAlbum           = "album";
    const argCommand         = "command";
    const argFormat          = "format";
    const argDirectory       = "directory";

    const cmdDeleteAlbum      = "delete-album";
    const cmdDeleteArtist     = "delete-artist";
    const cmdDeletePlaylist   = "delete-playlist";
    const cmdDeleteSong       = "delete-song";
    const cmdExportAlbum      = "export-album";
    const cmdExportArtist     = "export-artist";
    const cmdExportPlaylist   = "export-playlist";
    const cmdHelp             = "help";
    const cmdImportAlbum      = "import-album";
    const cmdImportAlbumArt   = "import-album-art";
    const cmdImportPlaylists  = "import-playlists";
    const cmdImportSongs      = "import-songs";
    const cmdInitStorage      = "init-storage";
    const cmdListAlbums       = "list-albums";
    const cmdListArtists      = "list-artists";
    const cmdListContainers   = "list-containers";
    const cmdListGenres       = "list-genres";
    const cmdListPlaylists    = "list-playlists";
    const cmdListSongs        = "list-songs";
    const cmdPlay             = "play";
    const cmdPlayAlbum        = "play-album";
    const cmdPlayPlaylist     = "play-playlist";
    const cmdRetrieveCatalog  = "retrieve-catalog";
    const cmdShowAlbum        = "show-album";
    const cmdShowPlaylist     = "show-playlist";
    const cmdShufflePlay      = "shuffle-play";
    const cmdUploadMetadataDb = "upload-metadata-db";
    const cmdUsage            = "usage";

    const ssFs = "fs";
    const ssS3 = "s3";

    const credsFileSuffix      = "_creds.txt";
    const credsContainerPrefix = "container_prefix";

    const awsAccessKey       = "aws_access_key";
    const awsSecretKey       = "aws_secret_key";
    const updateAwsAccessKey = "update_aws_access_key";
    const updateAwsSecretKey = "update_aws_secret_key";
    const endpointUrl        = "endpoint_url";
    const region             = "region";

    const fsRootDir = "root_dir";

    const audioFileTypeMp3  = "mp3";
    const audioFileTypeM4a  = "m4a";
    const audioFileTypeFlac = "flac";


    constructor;
    method ConnectFsSystem(Credentials: PropertySet;
                           Prefix: String): StorageSystem;
    method ConnectS3System(Credentials: PropertySet;
                           Prefix: String): StorageSystem;
    method ConnectStorageSystem(SystemName: String;
                                Credentials: PropertySet;
                                Prefix: String): StorageSystem;
    method InitStorageSystem(StorageSys: StorageSystem;
                             ContainerPrefix: String): Boolean;
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
  if Credentials.Contains(fsRootDir) then begin
    const RootDir = Credentials.GetStringValue(fsRootDir);
    if DebugMode then begin
      writeLn("{0} = '{0}'", fsRootDir, RootDir);
    end;
    result := new FSStorageSystem(RootDir, DebugMode);
  end
  else begin
    writeLn("error: '{0}' must be specified in {1}{2}", fsRootDir, ssFs, credsFileSuffix);
    result := nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.ConnectS3System(Credentials: PropertySet;
                                   Prefix: String): StorageSystem;
begin
  var theAwsAccessKey := "";
  var theAwsSecretKey := "";
  var theUpdateAwsAccessKey := "";
  var theUpdateAwsSecretKey := "";
  var theEndpointUrl := "";
  var theRegion := "";

  if Credentials.Contains(awsAccessKey) then begin
    theAwsAccessKey := Credentials.GetStringValue(awsAccessKey);
  end;

  if Credentials.Contains(awsSecretKey) then begin
    theAwsSecretKey := Credentials.GetStringValue(awsSecretKey);
  end;

  if Credentials.Contains(endpointUrl) then begin
    theEndpointUrl := Credentials.GetStringValue(endpointUrl);
  end;

  if Credentials.Contains(region) then begin
    theRegion := Credentials.GetStringValue(region);
  end;

  if Credentials.Contains(updateAwsAccessKey) and
     Credentials.Contains(updateAwsSecretKey) then begin

    theUpdateAwsAccessKey := Credentials.GetStringValue(updateAwsAccessKey);
    theUpdateAwsSecretKey := Credentials.GetStringValue(updateAwsSecretKey);
  end;

  if DebugMode then begin
    writeLn("{0}={1}", awsAccessKey, theAwsAccessKey);
    writeLn("{0}={1}", awsSecretKey, theAwsSecretKey);
    if (theUpdateAwsAccessKey.Length() > 0) and (theUpdateAwsSecretKey.Length() > 0) then begin
      writeLn("{0}={1}", updateAwsAccessKey, theUpdateAwsAccessKey);
      writeLn("{0}={1}", updateAwsSecretKey, theUpdateAwsSecretKey);
    end;
    writeLn("endpoint_url={0}", theEndpointUrl);
    if (theRegion.Length() > 0) then begin
      writeLn("region={0}", theRegion);
    end;
  end;

  if (theAwsAccessKey.Length() = 0) or (theAwsSecretKey.Length() = 0) then begin
    writeLn("error: no s3 credentials given. please specify {0} and {1} in credentials file",
            awsAccessKey, awsSecretKey);
    exit nil;
  end
  else begin
    //if Host.Length() = 0 then begin
    //  writeLn("error: no s3 host given. please specify host in credentials file");
    //  exit nil;
    //end;

    var AccessKey := "";
    var SecretKey := "";

    if UpdateMode then begin
      AccessKey := theUpdateAwsAccessKey;
      SecretKey := theUpdateAwsSecretKey;
    end
    else begin
      AccessKey := theAwsAccessKey;
      SecretKey := theAwsSecretKey;
    end;

    result := new S3ExtStorageSystem(AccessKey,
                                     SecretKey,
                                     theEndpointUrl,
                                     theRegion,
                                     Directory,
                                     DebugMode);
  end;
end;

//*******************************************************************************

method JukeboxMain.ConnectStorageSystem(SystemName: String;
                                        Credentials: PropertySet;
                                        Prefix: String): StorageSystem;
begin
  if SystemName = ssFs then begin
    result := ConnectFsSystem(Credentials, Prefix);
  end
  else if (SystemName = ssS3) or (SystemName= "s3ext") then begin
    result := ConnectS3System(Credentials, Prefix);
  end
  else begin
    writeLn("error: unrecognized storage system {0}", SystemName);
    result := nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.InitStorageSystem(StorageSys: StorageSystem;
                                     ContainerPrefix: String): Boolean;
var
  Success: Boolean;
begin
  if Jukebox.InitializeStorageSystem(StorageSys,
                                     ContainerPrefix,
                                     DebugMode) then begin
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
  writeLn("{0}       - delete specified album", cmdDeleteAlbum);
  writeLn("{0}      - delete specified artist", cmdDeleteArtist);
  writeLn("{0}    - delete specified playlist", cmdDeletePlaylist);
  writeLn("{0}        - delete specified song", cmdDeleteSong);
  writeLn("{0}       - FUTURE", cmdExportAlbum);
  writeLn("{0}      - FUTURE", cmdExportArtist);
  writeLn("{0}    - FUTURE", cmdExportPlaylist);
  writeLn("{0}               - show this help message", cmdHelp);
  writeLn("{0}   - import all album art from album-art-import subdirectory", cmdImportAlbumArt);
  writeLn("{0}   - import all new playlists from playlist-import subdirectory", cmdImportPlaylists);
  writeLn("{0}       - import all new songs from song-import subdirectory", cmdImportSongs);
  writeLn("{0}       - initialize storage system", cmdInitStorage);
  writeLn("{0}        - show listing of all available albums", cmdListAlbums);
  writeLn("{0}       - show listing of all available artists", cmdListArtists);
  writeLn("{0}    - show listing of all available storage containers", cmdListContainers);
  writeLn("{0}        - show listing of all available genres", cmdListGenres);
  writeLn("{0}     - show listing of all available playlists", cmdListPlaylists);
  writeLn("{0}         - show listing of all available songs", cmdListSongs);
  writeLn("{0}               - start playing songs", cmdPlay);
  writeLn("{0}      - play specified playlist", cmdPlayPlaylist);
  writeLn("{0}         - show songs in a specified album", cmdShowAlbum);
  writeLn("{0}      - show songs in specified playlist", cmdShowPlaylist);
  writeLn("{0}       - play songs randomly", cmdShufflePlay);
  writeLn("{0}   - retrieve copy of music catalog", cmdRetrieveCatalog);
  writeLn("{0} - upload SQLite metadata", cmdUploadMetadataDb);
  writeLn("{0}              - show this help message", cmdUsage);
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

  if Command = cmdImportSongs then begin
    jukebox.ImportSongs();
  end
  else if Command = cmdImportPlaylists then begin
    jukebox.ImportPlaylists();
  end
  else if Command = cmdPlay then begin
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = cmdShufflePlay then begin
    Shuffle := true;
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = cmdListSongs then begin
    jukebox.ShowListings();
  end
  else if Command = cmdListArtists then begin
    jukebox.ShowArtists();
  end
  else if Command = cmdListContainers then begin
    jukebox.ShowListContainers();
  end
  else if Command = cmdListGenres then begin
    jukebox.ShowGenres();
  end
  else if Command = cmdListAlbums then begin
    jukebox.ShowAlbums();
  end
  else if Command = cmdShowAlbum then begin
    if Artist.Length > 0 then begin
      if Album.Length > 0 then begin
        jukebox.ShowAlbum(Artist, Album);
      end
      else begin
        writeLn("error: album must be specified using {0}{1} option", argPrefix, argAlbum);
        ExitCode := 1;
      end;
    end
    else begin
      writeLn("error: artist must be specified using {0}{1} option", argPrefix, argArtist);
    end;
  end
  else if Command = cmdListPlaylists then begin
    jukebox.ShowPlaylists();
  end
  else if Command = cmdShowPlaylist then begin
    if Playlist.Length > 0 then begin
      jukebox.ShowPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using {0}{1} option", argPrefix, argPlaylist);
      ExitCode := 1;
    end;
  end
  else if Command = cmdPlayPlaylist then begin
    if Playlist.Length > 0 then begin
      jukebox.PlayPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using {0}{1} option", argPrefix, argPlaylist);
      ExitCode := 1;
    end;
  end
  else if Command = cmdRetrieveCatalog then begin
    writeLn("{0} not yet implemented", cmdRetrieveCatalog);
  end
  else if Command = cmdDeleteSong then begin
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
      writeLn("error: song must be specified using {0}{1} option", argPrefix, argSong);
      ExitCode := 1;
    end
  end
  else if Command = cmdDeleteArtist then begin
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
      writeLn("error: artist must be specified using {0}{1} option", argPrefix, argArtist);
      ExitCode := 1;
    end;
  end
  else if Command = cmdDeleteAlbum then begin
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
      writeLn("error: album must be specified using {0}{1} option", argPrefix, argAlbum);
      ExitCode := 1;
    end;
  end
  else if Command = cmdDeletePlaylist then begin
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
      writeLn("error: playlist must be specified using {0}{1} option", argPrefix, argPlaylist);
      ExitCode := 1;
    end;
  end
  else if Command = cmdUploadMetadataDb then begin
    if jukebox.UploadMetadataDb() then begin
      writeLn("metadata db uploaded");
    end
    else begin
      writeLn("error: unable to upload metadata db");
      ExitCode := 1;
    end;
  end
  else if Command = cmdImportAlbumArt then begin
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
  StorageType := ssFs;
  Artist := "";
  Album := "";
  Song := "";
  Playlist := "";

  var OptParser := new ArgumentParser;
  OptParser.AddOptionalBoolFlag(argPrefix+argDebug, "run in debug mode");
  OptParser.AddOptionalIntArgument(argPrefix+argFileCacheCount, "number of songs to buffer in cache");
  OptParser.AddOptionalBoolFlag(argPrefix+argIntegrityChecks, "check file integrity after download");
  OptParser.AddOptionalStringArgument(argPrefix+argStorage, "storage system type (s3, fs)");
  OptParser.AddOptionalStringArgument(argPrefix+argArtist, "limit operations to specified artist");
  OptParser.AddOptionalStringArgument(argPrefix+argPlaylist, "limit operations to specified playlist");
  OptParser.AddOptionalStringArgument(argPrefix+argSong, "limit operations to specified song");
  OptParser.AddOptionalStringArgument(argPrefix+argAlbum, "limit operations to specified album");
  OptParser.AddOptionalStringArgument(argPrefix+argDirectory, "specify directory where audio player should run");
  OptParser.AddRequiredArgument(argCommand, "command for jukebox");

  var Args := OptParser.ParseArgs(ConsoleArgs);
  if Args = nil then begin
    writeLn("error: unable to obtain command-line arguments");
    result := 1;
    exit;
  end;

  var Options := new JukeboxOptions;

  if Args.Contains(argDebug) then begin
    DebugMode := true;
    Options.DebugMode := true;
  end;

  if Args.Contains(argFileCacheCount) then begin
    const FileCacheCount = Args.GetIntValue(argFileCacheCount);
    if DebugMode then begin
      writeLn("setting file cache count={0}", FileCacheCount);
    end;
    Options.FileCacheCount := FileCacheCount;
  end;

  if Args.Contains(argIntegrityChecks) then begin
    if DebugMode then begin
      writeLn("setting integrity checks on");
    end;
    Options.CheckDataIntegrity := true;
  end;

  if Args.Contains(argStorage) then begin
    const Storage = Args.GetStringValue(argStorage);
    SupportedSystems := new StringSet;
    SupportedSystems.Add(ssFs);
    SupportedSystems.Add(ssS3);
    if not SupportedSystems.Contains(Storage) then begin
      writeLn("error: invalid storage type {0}", Storage);
      writeLn("supported systems are: {0}", SupportedSystems.ToString());
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

  if Args.Contains(argArtist) then begin
    Artist := Args.GetStringValue(argArtist);
  end;

  if Args.Contains(argPlaylist) then begin
    Playlist := Args.GetStringValue(argPlaylist);
  end;

  if Args.Contains(argSong) then begin
    Song := Args.GetStringValue(argSong);
  end;

  if Args.Contains(argAlbum) then begin
    Album := Args.GetStringValue(argAlbum);
  end;

  if Args.Contains(argDirectory) then begin
    Directory := Args.GetStringValue(argDirectory);
  end
  else begin
    Directory := Utils.GetCurrentDirectory();
  end;

  if Args.Contains(argCommand) then begin
    if DebugMode then begin
      writeLn("using storage system type {0}", StorageType);
    end;
    var ContainerPrefix := "";
    const CredsFile = StorageType + credsFileSuffix;
    Creds := new PropertySet;
    const CredsFilePath = Utils.PathJoin(Directory, CredsFile);

    if Utils.FileExists(CredsFilePath) then begin
      if DebugMode then begin
        writeLn("reading creds file {0}", CredsFilePath);
      end;

      const FileContents = Utils.FileReadAllText(CredsFilePath);
      if (FileContents <> nil) and (FileContents.Length > 0) then begin
        const FileLines = FileContents.Split(Environment.LineBreak);

        for each FileLine in FileLines do begin
          const LineTokens = FileLine.Split("=");
          if LineTokens.Count = 2 then begin
            const Key = LineTokens[0].Trim();
            const Value = LineTokens[1].Trim();
            if (Key.Length > 0) and (Value.Length > 0) then begin
              Creds.Add(Key, new PropertyValue(Value));
              if Key = credsContainerPrefix then begin
                ContainerPrefix := Value;
              end;
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

    const Command = Args.GetStringValue(argCommand);
    Args := nil;

    HelpCommands := new StringSet;
    HelpCommands.Add(cmdHelp);
    HelpCommands.Add(cmdUsage);

    NonHelpCommands := new StringSet;
    NonHelpCommands.Add(cmdImportSongs);
    NonHelpCommands.Add(cmdPlay);
    NonHelpCommands.Add(cmdShufflePlay);
    NonHelpCommands.Add(cmdListSongs);
    NonHelpCommands.Add(cmdListArtists);
    NonHelpCommands.Add(cmdListContainers);
    NonHelpCommands.Add(cmdListGenres);
    NonHelpCommands.Add(cmdListAlbums);
    NonHelpCommands.Add(cmdRetrieveCatalog);
    NonHelpCommands.Add(cmdImportPlaylists);
    NonHelpCommands.Add(cmdListPlaylists);
    NonHelpCommands.Add(cmdShowAlbum);
    NonHelpCommands.Add(cmdShowPlaylist);
    NonHelpCommands.Add(cmdPlayPlaylist);
    NonHelpCommands.Add(cmdDeleteSong);
    NonHelpCommands.Add(cmdDeleteAlbum);
    NonHelpCommands.Add(cmdDeletePlaylist);
    NonHelpCommands.Add(cmdDeleteArtist);
    NonHelpCommands.Add(cmdUploadMetadataDb);
    NonHelpCommands.Add(cmdImportAlbumArt);

    UpdateCommands := new StringSet;
    UpdateCommands.Add(cmdImportSongs);
    UpdateCommands.Add(cmdImportPlaylists);
    UpdateCommands.Add(cmdDeleteSong);
    UpdateCommands.Add(cmdDeleteAlbum);
    UpdateCommands.Add(cmdDeletePlaylist);
    UpdateCommands.Add(cmdDeleteArtist);
    UpdateCommands.Add(cmdUploadMetadataDb);
    UpdateCommands.Add(cmdImportAlbumArt);
    UpdateCommands.Add(cmdInitStorage);

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

        if Command = cmdUploadMetadataDb then begin
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

        if Command = cmdInitStorage then begin
          if InitStorageSystem(StorageSystem, ContainerPrefix) then begin
            result := 0
          end
          else begin
            result := 1;
          end;
          exit;
        end;

        const jukebox = new Jukebox(Options,
                                    StorageSystem,
                                    ContainerPrefix,
                                    DebugMode);
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