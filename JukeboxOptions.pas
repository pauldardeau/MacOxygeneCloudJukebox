namespace MacOxygeneCloudJukebox;

interface

type
  JukeboxOptions = public class
  public
    DebugMode: Boolean;
    UseEncryption: Boolean;
    UseCompression: Boolean;
    CheckDataIntegrity: Boolean;
    FileCacheCount: Integer;
    NumberSongs: Integer;
    EncryptionKey: String;
    EncryptionKeyFile: String;
    EncryptionIv: String;
    SuppressMetadataDownload: Boolean;
    Directory: String;

    constructor();
  end;

implementation

constructor JukeboxOptions;
begin
  DebugMode := false;
  UseEncryption := false;
  UseCompression := false;
  CheckDataIntegrity := false;
  FileCacheCount := 0;
  NumberSongs := 0;
  EncryptionKey := "";
  EncryptionKeyFile := "";
  EncryptionIv := "";
  SuppressMetadataDownload := false;
  Directory := "";
end;

end.