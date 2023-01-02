namespace MacOxygeneCloudJukebox;

interface

type
  FSStorageSystem = public class(StorageSystem)
  private
    RootDir: String;
    DebugMode: Boolean;

  public
    const MetadataFileSuffix = '.meta';

    constructor(aRootDir: String; aDebugMode: Boolean);
    method Enter: Boolean; override;
    method Leave; override;
    method ListAccountContainers: List<String>; override;
    method GetContainerNames: ImmutableList<String>; override;
    method HasContainer(ContainerName: String): Boolean; override;
    method CreateContainer(ContainerName: String): Boolean; override;
    method DeleteContainer(ContainerName: String): Boolean; override;
    method ListContainerContents(ContainerName: String): ImmutableList<String>; override;
    method GetObjectMetadata(ContainerName: String;
                             ObjectName: String;
                             DictProps: PropertySet): Boolean; override;
    method PutObject(ContainerName: String;
                     ObjectName: String;
                     FileContents: array of Byte;
                     Headers: PropertySet): Boolean; override;
    method DeleteObject(ContainerName: String; ObjectName: String): Boolean; override;
    method GetObject(ContainerName: String;
                     ObjectName: String;
                     LocalFilePath: String): Int64; override;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor FSStorageSystem(aRootDir: String; aDebugMode: Boolean);
begin
  RootDir := aRootDir;
  DebugMode := aDebugMode;
end;

//*******************************************************************************

method FSStorageSystem.Enter: Boolean;
begin
  if not Utils.DirectoryExists(RootDir) then
    result := Utils.CreateDirectory(RootDir)
  else
    result := true;
end;

//*******************************************************************************

method FSStorageSystem.Leave;
begin
  // nothing to do
end;

//*******************************************************************************

method FSStorageSystem.ListAccountContainers: List<String>;
begin
  result := Utils.ListDirsInDirectory(RootDir);
end;

//*******************************************************************************

method FSStorageSystem.GetContainerNames: ImmutableList<String>;
begin
  result := ListAccountContainers;
end;

//*******************************************************************************

method FSStorageSystem.HasContainer(ContainerName: String): Boolean;
var
  ContainerFound: Boolean;
begin
  ContainerFound := false;
  const ListContainers = ListAccountContainers();
  if ListContainers.Count > 0 then begin
    for each Container: String in ListContainers do begin
      if ContainerName = Container then begin
        ContainerFound := true;
        break;
      end;
    end;
  end;
  result := ContainerFound;
end;

//*******************************************************************************

method FSStorageSystem.CreateContainer(ContainerName: String): Boolean;
begin
  const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
  const ContainerCreated = Utils.CreateDirectory(ContainerDir);
  if ContainerCreated then begin
    if DebugMode then begin
      writeLn(String.Format("container created: '{0}'", ContainerName));
    end;
  end;
  result := ContainerCreated;
end;

//*******************************************************************************

method FSStorageSystem.DeleteContainer(ContainerName: String): Boolean;
begin
  const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
  const ContainerDeleted = Utils.DeleteDirectory(ContainerDir);
  if ContainerDeleted then begin
    if DebugMode then begin
      writeLn(String.Format("container deleted: '{0}'", ContainerName));
    end;
  end;
  result := ContainerDeleted;
end;

//*******************************************************************************

method FSStorageSystem.ListContainerContents(ContainerName: String): ImmutableList<String>;
var
  ContainerContents: ImmutableList<String>;
begin
  const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
  if Utils.DirectoryExists(ContainerDir) then
    ContainerContents := Utils.ListFilesInDirectory(ContainerDir)
  else
    ContainerContents := new ImmutableList<String>;
  result := ContainerContents;
end;

//*******************************************************************************

method FSStorageSystem.GetObjectMetadata(ContainerName: String;
                                         ObjectName: String;
                                         DictProps: PropertySet): Boolean;
var
  RetrievedMetadata: Boolean;
begin
  RetrievedMetadata := false;
  if ContainerName.Length > 0 and ObjectName.Length > 0 then begin
    const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
    if Utils.DirectoryExists(ContainerDir) then begin
      const ObjectPath = Utils.PathJoin(ContainerDir, ObjectName);
      const MetaPath = ObjectPath + MetadataFileSuffix;
      if Utils.FileExists(MetaPath) then begin
        RetrievedMetadata := DictProps.ReadFromFile(MetaPath);
      end;
    end;
  end;
  result := RetrievedMetadata;
end;

//*******************************************************************************

method FSStorageSystem.PutObject(ContainerName: String;
                                 ObjectName: String;
                                 FileContents: array of Byte;
                                 Headers: PropertySet): Boolean;
var
  ObjectAdded: Boolean;
begin
  ObjectAdded := false;
  if (ContainerName.Length > 0) and
     (ObjectName.Length > 0) and
     (FileContents.length > 0) then begin

    const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
    if Utils.DirectoryExists(ContainerDir) then begin
      const ObjectPath = Utils.PathJoin(ContainerDir, ObjectName);
      ObjectAdded := Utils.FileWriteAllBytes(ObjectPath, FileContents);
      if ObjectAdded then begin
        if DebugMode then begin
          writeLn(String.Format("object added: {0}/{1}",
                                ContainerName,
                                ObjectName));
        end;
        if Headers <> nil then begin
          if Headers.Count() > 0 then begin
            const MetaPath = ObjectPath + MetadataFileSuffix;
            Headers.WriteToFile(MetaPath);
          end;
        end;
      end
      else begin
        writeLn("FileWriteAllBytes failed to write object contents, put failed");
      end;
    end
    else begin
      if DebugMode then begin
        writeLn("container doesn't exist, can't put object");
      end;
    end;
  end
  else begin
    if DebugMode then begin
      if ContainerName.Length = 0 then begin
        writeLn("container name is missing, can't put object");
      end
      else begin
        if ObjectName.Length = 0 then begin
          writeLn("object name is missing, can't put object");
        end
        else begin
          if FileContents.Count = 0 then begin
            writeLn("object content is empty, can't put object");
          end;
        end;
      end;
    end;
  end;
  result := ObjectAdded;
end;

//*******************************************************************************

method FSStorageSystem.DeleteObject(ContainerName: String;
                                    ObjectName: String): Boolean;
var
  ObjectDeleted: Boolean;
begin
  ObjectDeleted := false;
  if ContainerName.Length > 0 and ObjectName.Length > 0 then begin
    const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
    const ObjectPath = Utils.PathJoin(ContainerDir, ObjectName);

    if Utils.FileExists(ObjectPath) then begin
      ObjectDeleted := Utils.DeleteFile(ObjectPath);
      if ObjectDeleted then begin
        if DebugMode then begin
          writeLn(String.Format("object deleted: {0}/{1}",
                                ContainerName,
                                ObjectName));
        end;
        const MetaPath = ObjectPath + MetadataFileSuffix;
        if Utils.FileExists(MetaPath) then begin
          Utils.DeleteFile(MetaPath);
        end;
      end
      else begin
        if DebugMode then begin
          writeLn("delete of object file failed");
        end;
      end;
    end
    else begin
      if DebugMode then begin
        writeLn("cannot delete object, path doesn't exist");
      end;
    end;
  end
  else begin
    if DebugMode then begin
      writeLn("cannot delete object, container name or object name is missing");
    end;
  end;
  result := ObjectDeleted;
end;

//*******************************************************************************

method FSStorageSystem.GetObject(ContainerName: String;
                                 ObjectName: String;
                                 LocalFilePath: String): Int64;
var
  BytesRetrieved: Int64;
begin
  BytesRetrieved := 0;

  if (ContainerName.Length > 0) and
     (ObjectName.Length > 0) and
     (LocalFilePath.Length > 0) then begin

    const ContainerDir = Utils.PathJoin(RootDir, ContainerName);
    const ObjectPath = Utils.PathJoin(ContainerDir, ObjectName);

    if Utils.FileExists(ObjectPath) then begin
      const ObjFileContents = Utils.FileReadAllBytes(ObjectPath);
      if ObjFileContents.Count > 0 then begin
        if DebugMode then begin
          writeLn(String.Format("attempting to write object to '{0}'",
                                LocalFilePath));
        end;
        if Utils.FileWriteAllBytes(LocalFilePath, ObjFileContents) then begin
          BytesRetrieved := Int64(ObjFileContents.Count);
        end;
      end
      else begin
        writeLn(String.Format("error: unable to read object file '{0}'",
                              ObjectPath));
      end;
    end;
  end;
  result := BytesRetrieved;
end;

//*******************************************************************************

end.