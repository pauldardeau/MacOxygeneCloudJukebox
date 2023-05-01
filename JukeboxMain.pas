namespace MacOxygeneCloudJukebox;

uses
  CloudJukeboxSharedProject;

interface

type
  JukeboxMain = public class
  private
    Artist: String;
    Album: String;
    Song: String;
    Playlist: String;
    DebugMode: Boolean;
    Directory: String;

  public
    const ARG_PREFIX           = "--";
    const ARG_DEBUG            = "debug";
    const ARG_FILE_CACHE_COUNT = "file-cache-count";
    const ARG_INTEGRITY_CHECKS = "integrity-checks";
    const ARG_STORAGE          = "storage";
    const ARG_ARTIST           = "artist";
    const ARG_PLAYLIST         = "playlist";
    const ARG_SONG             = "song";
    const ARG_ALBUM            = "album";
    const ARG_COMMAND          = "command";
    const ARG_FORMAT           = "format";
    const ARG_DIRECTORY        = "directory";

    const CMD_DELETE_ALBUM       = "delete-album";
    const CMD_DELETE_ARTIST      = "delete-artist";
    const CMD_DELETE_PLAYLIST    = "delete-playlist";
    const CMD_DELETE_SONG        = "delete-song";
    const CMD_EXPORT_ALBUM       = "export-album";
    const CMD_EXPORT_ARTIST      = "export-artist";
    const CMD_EXPORT_PLAYLIST    = "export-playlist";
    const CMD_HELP               = "help";
    const CMD_IMPORT_ALBUM       = "import-album";
    const CMD_IMPORT_ALBUM_ART   = "import-album-art";
    const CMD_IMPORT_PLAYLISTS   = "import-playlists";
    const CMD_IMPORT_SONGS       = "import-songs";
    const CMD_INIT_STORAGE       = "init-storage";
    const CMD_LIST_ALBUMS        = "list-albums";
    const CMD_LIST_ARTISTS       = "list-artists";
    const CMD_LIST_CONTAINERS    = "list-containers";
    const CMD_LIST_GENRES        = "list-genres";
    const CMD_LIST_PLAYLISTS     = "list-playlists";
    const CMD_LIST_SONGS         = "list-songs";
    const CMD_PLAY               = "play";
    const CMD_PLAY_ALBUM         = "play-album";
    const CMD_PLAY_PLAYLIST      = "play-playlist";
    const CMD_RETRIEVE_CATALOG   = "retrieve-catalog";
    const CMD_SHOW_ALBUM         = "show-album";
    const CMD_SHOW_PLAYLIST      = "show-playlist";
    const CMD_SHUFFLE_PLAY       = "shuffle-play";
    const CMD_UPLOAD_METADATA_DB = "upload-metadata-db";
    const CMD_USAGE              = "usage";

    const SS_FS = "fs";
    const SS_S3 = "s3";

    const CREDS_FILE_SUFFIX      = "_creds.txt";
    const CREDS_CONTAINER_PREFIX = "container_prefix";

    const S3_ENDPOINT_URL = "endpoint_url";
    const S3_REGION       = "region";

    const FS_ROOT_DIR = "root_dir";

    const AUDIO_FILE_TYPE_MP3  = "mp3";
    const AUDIO_FILE_TYPE_M4A  = "m4a";
    const AUDIO_FILE_TYPE_FLAC = "flac";


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
end;

//*******************************************************************************

method JukeboxMain.ConnectFsSystem(Credentials: PropertySet;
                                   Prefix: String): StorageSystem;
begin
  if Credentials.Contains(FS_ROOT_DIR) then begin
    const RootDir = Credentials.GetStringValue(FS_ROOT_DIR);
    if DebugMode then begin
      writeLn("{0} = '{0}'", FS_ROOT_DIR, RootDir);
    end;
    exit new FSStorageSystem(RootDir, DebugMode);
  end
  else begin
    writeLn("error: '{0}' must be specified in {1}{2}",
            FS_ROOT_DIR, SS_FS, CREDS_FILE_SUFFIX);
    exit nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.ConnectS3System(Credentials: PropertySet;
                                   Prefix: String): StorageSystem;
begin
  var theEndpointUrl := "";
  var theRegion := "";

  if Credentials.Contains(S3_ENDPOINT_URL) then begin
    theEndpointUrl := Credentials.GetStringValue(S3_ENDPOINT_URL);
  end;

  if Credentials.Contains(S3_REGION) then begin
    theRegion := Credentials.GetStringValue(S3_REGION);
  end;

  if DebugMode then begin
    writeLn("{0}={1}", S3_ENDPOINT_URL, theEndpointUrl);
    if (theRegion.Length > 0) then begin
      writeLn("{0}={1}", S3_REGION, theRegion);
    end;
  end;

  exit new S3ExtStorageSystem(theEndpointUrl,
                              theRegion,
                              Directory,
                              DebugMode);
end;

//*******************************************************************************

method JukeboxMain.ConnectStorageSystem(SystemName: String;
                                        Credentials: PropertySet;
                                        Prefix: String): StorageSystem;
begin
  if SystemName = SS_FS then begin
    exit ConnectFsSystem(Credentials, Prefix);
  end
  else if (SystemName = SS_S3) or (SystemName= "s3ext") then begin
    exit ConnectS3System(Credentials, Prefix);
  end
  else begin
    writeLn("error: unrecognized storage system {0}", SystemName);
    exit nil;
  end;
end;

//*******************************************************************************

method JukeboxMain.InitStorageSystem(StorageSys: StorageSystem;
                                     ContainerPrefix: String): Boolean;
begin
  var Success: Boolean;
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
  exit Success;
end;

//*******************************************************************************

method JukeboxMain.ShowUsage;
begin
  writeLn("Supported Commands:");
  writeLn("{0}       - delete specified album", CMD_DELETE_ALBUM);
  writeLn("{0}      - delete specified artist", CMD_DELETE_ARTIST);
  writeLn("{0}    - delete specified playlist", CMD_DELETE_PLAYLIST);
  writeLn("{0}        - delete specified song", CMD_DELETE_SONG);
  writeLn("{0}       - FUTURE", CMD_EXPORT_ALBUM);
  writeLn("{0}      - FUTURE", CMD_EXPORT_ARTIST);
  writeLn("{0}    - FUTURE", CMD_EXPORT_PLAYLIST);
  writeLn("{0}               - show this help message", CMD_HELP);
  writeLn("{0}   - import all album art from album-art-import subdirectory", CMD_IMPORT_ALBUM_ART);
  writeLn("{0}   - import all new playlists from playlist-import subdirectory", CMD_IMPORT_PLAYLISTS);
  writeLn("{0}       - import all new songs from song-import subdirectory", CMD_IMPORT_SONGS);
  writeLn("{0}       - initialize storage system", CMD_INIT_STORAGE);
  writeLn("{0}        - show listing of all available albums", CMD_LIST_ALBUMS);
  writeLn("{0}       - show listing of all available artists", CMD_LIST_ARTISTS);
  writeLn("{0}    - show listing of all available storage containers", CMD_LIST_CONTAINERS);
  writeLn("{0}        - show listing of all available genres", CMD_LIST_GENRES);
  writeLn("{0}     - show listing of all available playlists", CMD_LIST_PLAYLISTS);
  writeLn("{0}         - show listing of all available songs", CMD_LIST_SONGS);
  writeLn("{0}               - start playing songs", CMD_PLAY);
  writeLn("{0}      - play specified playlist", CMD_PLAY_PLAYLIST);
  writeLn("{0}         - show songs in a specified album", CMD_SHOW_ALBUM);
  writeLn("{0}      - show songs in specified playlist", CMD_SHOW_PLAYLIST);
  writeLn("{0}       - play songs randomly", CMD_SHUFFLE_PLAY);
  writeLn("{0}   - retrieve copy of music catalog", CMD_RETRIEVE_CATALOG);
  writeLn("{0} - upload SQLite metadata", CMD_UPLOAD_METADATA_DB);
  writeLn("{0}              - show this help message", CMD_USAGE);
  writeLn("");
end;

//*******************************************************************************

method JukeboxMain.RunJukeboxCommand(jukebox: Jukebox; Command: String): Integer;
begin
  var ExitCode := 0;
  var Shuffle := false;

  if Command = CMD_IMPORT_SONGS then begin
    jukebox.ImportSongs();
  end
  else if Command = CMD_IMPORT_PLAYLISTS then begin
    jukebox.ImportPlaylists();
  end
  else if Command = CMD_PLAY then begin
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = CMD_SHUFFLE_PLAY then begin
    Shuffle := true;
    jukebox.PlaySongs(Shuffle, Artist, Album);
  end
  else if Command = CMD_LIST_SONGS then begin
    jukebox.ShowListings();
  end
  else if Command = CMD_LIST_ARTISTS then begin
    jukebox.ShowArtists();
  end
  else if Command = CMD_LIST_CONTAINERS then begin
    jukebox.ShowListContainers();
  end
  else if Command = CMD_LIST_GENRES then begin
    jukebox.ShowGenres();
  end
  else if Command = CMD_LIST_ALBUMS then begin
    jukebox.ShowAlbums();
  end
  else if Command = CMD_SHOW_ALBUM then begin
    if (Artist.Length > 0) and (Album.Length > 0) then begin
      jukebox.ShowAlbum(Artist, Album);
    end
    else begin
      writeLn("error: artist and album must be specified using {0}{1} and {2}{3} options",
              ARG_PREFIX, ARG_ARTIST, ARG_PREFIX, ARG_ALBUM);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_PLAY_ALBUM then begin
    if (Artist.Length > 0) and (Album.Length > 0) then begin
      jukebox.PlayAlbum(Artist, Album);
    end
    else begin
      writeLn("error: artist and album must be specified using {0}{1} and {2}{3} options",
              ARG_PREFIX, ARG_ARTIST, ARG_PREFIX, ARG_ALBUM);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_LIST_PLAYLISTS then begin
    jukebox.ShowPlaylists();
  end
  else if Command = CMD_SHOW_PLAYLIST then begin
    if Playlist.Length > 0 then begin
      jukebox.ShowPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using {0}{1} option",
              ARG_PREFIX, ARG_PLAYLIST);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_PLAY_PLAYLIST then begin
    if Playlist.Length > 0 then begin
      jukebox.PlayPlaylist(Playlist);
    end
    else begin
      writeLn("error: playlist must be specified using {0}{1} option",
              ARG_PREFIX, ARG_PLAYLIST);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_RETRIEVE_CATALOG then begin
    writeLn("{0} not yet implemented", CMD_RETRIEVE_CATALOG);
  end
  else if Command = CMD_DELETE_SONG then begin
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
      writeLn("error: song must be specified using {0}{1} option",
              ARG_PREFIX, ARG_SONG);
      ExitCode := 1;
    end
  end
  else if Command = CMD_DELETE_ARTIST then begin
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
      writeLn("error: artist must be specified using {0}{1} option",
              ARG_PREFIX, ARG_ARTIST);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_DELETE_ALBUM then begin
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
      writeLn("error: album must be specified using {0}{1} option",
              ARG_PREFIX, ARG_ALBUM);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_DELETE_PLAYLIST then begin
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
      writeLn("error: playlist must be specified using {0}{1} option",
              ARG_PREFIX, ARG_PLAYLIST);
      ExitCode := 1;
    end;
  end
  else if Command = CMD_UPLOAD_METADATA_DB then begin
    if jukebox.UploadMetadataDb() then begin
      writeLn("metadata db uploaded");
    end
    else begin
      writeLn("error: unable to upload metadata db");
      ExitCode := 1;
    end;
  end
  else if Command = CMD_IMPORT_ALBUM_ART then begin
    jukebox.ImportAlbumArt();
  end;

  exit ExitCode;
end;

//*******************************************************************************

method JukeboxMain.Run(ConsoleArgs: ImmutableList<String>): Int32;
var
  SupportedSystems: StringSet;
  HelpCommands: StringSet;
  NonHelpCommands: StringSet;
  UpdateCommands: StringSet;
  AllCommands: StringSet;
  Creds: PropertySet;
begin
  var ExitCode := 0;
  var StorageType := SS_FS;
  Artist := "";
  Album := "";
  Song := "";
  Playlist := "";

  var OptParser := new ArgumentParser;
  OptParser.AddOptionalBoolFlag(ARG_PREFIX+ARG_DEBUG, "run in debug mode");
  OptParser.AddOptionalIntArgument(ARG_PREFIX+ARG_FILE_CACHE_COUNT, "number of songs to buffer in cache");
  OptParser.AddOptionalBoolFlag(ARG_PREFIX+ARG_INTEGRITY_CHECKS, "check file integrity after download");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_STORAGE, "storage system type (s3, fs)");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_ARTIST, "limit operations to specified artist");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_PLAYLIST, "limit operations to specified playlist");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_SONG, "limit operations to specified song");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_ALBUM, "limit operations to specified album");
  OptParser.AddOptionalStringArgument(ARG_PREFIX+ARG_DIRECTORY, "specify directory where audio player should run");
  OptParser.AddRequiredArgument(ARG_COMMAND, "command for jukebox");

  const Args = OptParser.ParseArgs(ConsoleArgs);
  if Args = nil then begin
    writeLn("error: unable to obtain command-line arguments");
    exit 1;
  end;

  var Options := new JukeboxOptions;

  if Args.Contains(ARG_DEBUG) then begin
    DebugMode := true;
    Options.DebugMode := true;
  end;

  if Args.Contains(ARG_FILE_CACHE_COUNT) then begin
    const FileCacheCount = Args.GetIntValue(ARG_FILE_CACHE_COUNT);
    if DebugMode then begin
      writeLn("setting file cache count={0}", FileCacheCount);
    end;
    Options.FileCacheCount := FileCacheCount;
  end;

  if Args.Contains(ARG_INTEGRITY_CHECKS) then begin
    if DebugMode then begin
      writeLn("setting integrity checks on");
    end;
    Options.CheckDataIntegrity := true;
  end;

  if Args.Contains(ARG_STORAGE) then begin
    const Storage = Args.GetStringValue(ARG_STORAGE);
    SupportedSystems := new StringSet;
    SupportedSystems.Add(SS_FS);
    SupportedSystems.Add(SS_S3);
    if not SupportedSystems.Contains(Storage) then begin
      writeLn("error: invalid storage type {0}", Storage);
      writeLn("supported systems are: {0}", SupportedSystems.ToString());
      exit 1;
    end
    else begin
      if DebugMode then begin
        writeLn("setting storage system to {0}", Storage);
      end;
      StorageType := Storage;
    end;
  end;

  if Args.Contains(ARG_ARTIST) then begin
    Artist := Args.GetStringValue(ARG_ARTIST);
  end;

  if Args.Contains(ARG_PLAYLIST) then begin
    Playlist := Args.GetStringValue(ARG_PLAYLIST);
  end;

  if Args.Contains(ARG_SONG) then begin
    Song := Args.GetStringValue(ARG_SONG);
  end;

  if Args.Contains(ARG_ALBUM) then begin
    Album := Args.GetStringValue(ARG_ALBUM);
  end;

  if Args.Contains(ARG_DIRECTORY) then begin
    Directory := Args.GetStringValue(ARG_DIRECTORY);
  end
  else begin
    Directory := Utils.GetCurrentDirectory();
  end;

  if Args.Contains(ARG_COMMAND) then begin
    if DebugMode then begin
      writeLn("using storage system type {0}", StorageType);
    end;

    var ContainerPrefix := "";
    const CredsFile = StorageType + CREDS_FILE_SUFFIX;
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
              if Key = CREDS_CONTAINER_PREFIX then begin
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

    const Command = Args.GetStringValue(ARG_COMMAND);

    HelpCommands := new StringSet;
    HelpCommands.Add(CMD_HELP);
    HelpCommands.Add(CMD_USAGE);

    NonHelpCommands := new StringSet;
    NonHelpCommands.Add(CMD_IMPORT_SONGS);
    NonHelpCommands.Add(CMD_PLAY);
    NonHelpCommands.Add(CMD_SHUFFLE_PLAY);
    NonHelpCommands.Add(CMD_LIST_SONGS);
    NonHelpCommands.Add(CMD_LIST_ARTISTS);
    NonHelpCommands.Add(CMD_LIST_CONTAINERS);
    NonHelpCommands.Add(CMD_LIST_GENRES);
    NonHelpCommands.Add(CMD_LIST_ALBUMS);
    NonHelpCommands.Add(CMD_RETRIEVE_CATALOG);
    NonHelpCommands.Add(CMD_IMPORT_PLAYLISTS);
    NonHelpCommands.Add(CMD_LIST_PLAYLISTS);
    NonHelpCommands.Add(CMD_SHOW_ALBUM);
    NonHelpCommands.Add(CMD_PLAY_ALBUM);
    NonHelpCommands.Add(CMD_SHOW_PLAYLIST);
    NonHelpCommands.Add(CMD_PLAY_PLAYLIST);
    NonHelpCommands.Add(CMD_DELETE_SONG);
    NonHelpCommands.Add(CMD_DELETE_ALBUM);
    NonHelpCommands.Add(CMD_DELETE_PLAYLIST);
    NonHelpCommands.Add(CMD_DELETE_ARTIST);
    NonHelpCommands.Add(CMD_UPLOAD_METADATA_DB);
    NonHelpCommands.Add(CMD_IMPORT_ALBUM_ART);

    // Commands that will alter the cloud storage (or content)
    // These commands may require a different set of credentials
    UpdateCommands := new StringSet;
    UpdateCommands.Add(CMD_IMPORT_SONGS);
    UpdateCommands.Add(CMD_IMPORT_PLAYLISTS);
    UpdateCommands.Add(CMD_DELETE_SONG);
    UpdateCommands.Add(CMD_DELETE_ALBUM);
    UpdateCommands.Add(CMD_DELETE_PLAYLIST);
    UpdateCommands.Add(CMD_DELETE_ARTIST);
    UpdateCommands.Add(CMD_UPLOAD_METADATA_DB);
    UpdateCommands.Add(CMD_IMPORT_ALBUM_ART);
    UpdateCommands.Add(CMD_INIT_STORAGE);

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

        if Command = CMD_UPLOAD_METADATA_DB then begin
          Options.SuppressMetadataDownload := true;
        end
        else begin
          Options.SuppressMetadataDownload := false;
        end;

        Options.Directory := Directory;

        var StorageSystem := ConnectStorageSystem(StorageType,
                                                  Creds,
                                                  ContainerPrefix);

        if StorageSystem = nil then begin
          writeLn("error: unable to connect to storage system");
          exit 1;
        end;

        if not StorageSystem.Enter() then begin
          writeLn("error: unable to enter storage system");
          exit 1;
        end;

        if Command = CMD_INIT_STORAGE then begin
          if InitStorageSystem(StorageSystem, ContainerPrefix) then begin
            exit 0;
          end
          else begin
            exit 1;
          end;
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

  exit ExitCode;
end;

//*******************************************************************************

end.