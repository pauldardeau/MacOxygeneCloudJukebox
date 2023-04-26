namespace CloudJukeboxSharedProject;

interface

type
  FileMetadata = public class
  public
    FileUid: String;
    FileName: String;
    OriginFileSize: Int64;
    StoredFileSize: Int64;
    PadCharCount: Int64;
    FileTime: String;
    Md5Hash: String;
    Compressed: Boolean;
    Encrypted: Boolean;
    ContainerName: String;
    ObjectName: String;

    constructor();
  end;

implementation

constructor FileMetadata();
begin
  FileUid := "";
  FileName := "";
  OriginFileSize := 0;
  StoredFileSize := 0;
  PadCharCount := 0;
  FileTime := "";
  Md5Hash := "";
  Compressed := false;
  Encrypted := false;
  ContainerName := "";
  ObjectName := "";
end;

end.