namespace CloudJukeboxSharedProject;

interface
type
  S3ExtStorageSystem = public class(StorageSystem)
  private
    DebugMode: Boolean;
    EndpointUrl: String;
    Region: String;
    Directory: String;
    ScriptDirectory: String;
    ListContainers: List<String>;

  public
    const PROP_CONTENT_LENGTH = "Content-Length";
    const PROP_CONTENT_TYPE = "Content-Type";
    const PROP_CONTENT_MD5 = "Content-MD5";
    const PROP_CONTENT_ENCODING = "Content-Encoding";

    const runScriptNamePrefix = "exec-";
    const scrTemplateListContainers = "s3-list-containers.sh";
    const scrTemplateCreateContainer = "s3-create-container.sh";
    const scrTemplateDeleteContainer = "s3-delete-container.sh";
    const scrTemplateListContainerContents = "s3-list-container-contents.sh";
    const scrTemplateHeadObject = "s3-head-object.sh";
    const scrTemplatePutObjectWithProperties = "s3-put-object-props.sh";
    const scrTemplatePutObject = "s3-put-object.sh";
    const scrTemplateDeleteObject = "s3-delete-object.sh";
    const scrTemplateGetObject = "s3-get-object.sh";


    constructor(aEndpointUrl: String;
                aRegion: String;
                aDirectory: String;
                aDebugMode: Boolean);

    method Enter(): Boolean; override;
    method Leave(); override;
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
    method PutObjectFromFile(ContainerName: String;
                             ObjectName: String;
                             FilePath: String;
                             Headers: PropertySet): Boolean; override;
    method DeleteObject(ContainerName: String;
                        ObjectName: String): Boolean; override;
    method GetObject(ContainerName: String;
                     ObjectName: String;
                     LocalFilePath: String): Int64; override;

  protected
    method PopulateCommonVariables(Kvp: KeyValuePairs);
    method PopulateBucket(Kvp: KeyValuePairs; BucketName: String);
    method PopulateObject(Kvp: KeyValuePairs; ObjectName: String);
    method RunProgram(ProgramPath: String;
                      ListOutputLines: List<String>): Boolean;
    method RunProgram(ProgramPath: String): Boolean;
    method RunProgram(ProgramPath: String; out StdOut: String): Boolean;
    method PrepareRunScript(ScriptTemplate: String;
                            RunScript: String;
                            Kvp: KeyValuePairs): Boolean;
    method RunScriptNameForTemplate(ScriptTemplate: String): String;

  end;

//*******************************************************************************

implementation

constructor S3ExtStorageSystem(aEndpointUrl: String;
                               aRegion: String;
                               aDirectory: String;
                               aDebugMode: Boolean);
begin
  DebugMode := aDebugMode;
  EndpointUrl := aEndpointUrl;
  Region := aRegion;
  Directory := aDirectory;
  ScriptDirectory := Utils.PathJoin(Directory, "scripts");
  ListContainers := new List<String>;
end;

//*******************************************************************************

method S3ExtStorageSystem.Enter(): Boolean;
begin
  if DebugMode then begin
     writeLn("S3ExtStorageSystem.Enter");
  end;

  ListContainers := ListAccountContainers();
  exit true;
end;

//*******************************************************************************

method S3ExtStorageSystem.Leave();
begin
  if DebugMode then begin
     writeLn("S3ExtStorageSystem.Leave");
  end;
end;

//*******************************************************************************

method S3ExtStorageSystem.ListAccountContainers: List<String>;
const methodName = "S3ExtStorageSystem.ListAccountContainers";
begin
  if DebugMode then begin
    writeLn("entering {0}", methodName);
  end;

  var ListOfContainers := new List<String>;
  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);

  const ScriptTemplate = scrTemplateListContainers;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if not RunProgram(RunScript, ListOfContainers) then begin
        ListOfContainers.RemoveAll();
        writeLn("{0} - error: unable to run script", methodName);
      end;
    end
    else begin
      writeLn("{0} - error: unable to prepare script", methodName);
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ListOfContainers;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetContainerNames: ImmutableList<String>;
begin
  exit ListContainers;
end;

//*******************************************************************************

method S3ExtStorageSystem.HasContainer(ContainerName: String): Boolean;
begin
  exit ListContainers.Contains(ContainerName);
end;

//*******************************************************************************

method S3ExtStorageSystem.CreateContainer(ContainerName: String): Boolean;
const methodName = "S3ExtStorageSystem.CreateContainer";
begin
  if DebugMode then begin
    writeLn("entering {0} with ContainerName='{1}'", methodName, ContainerName);
  end;

  var ContainerCreated := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);

  const ScriptTemplate = scrTemplateCreateContainer;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript) then begin
        ContainerCreated := true;
      end
      else begin
        writeLn("{0} - error: create container '{1}' failed",
                methodName, ContainerName);
      end;
    end
    else begin
      writeLn("{0} - error: unable to prepare run script", methodName);
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ContainerCreated;
end;

//*******************************************************************************

method S3ExtStorageSystem.DeleteContainer(ContainerName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("DeleteContainer: {0}", ContainerName);
  end;

  var ContainerDeleted := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);

  const ScriptTemplate = scrTemplateDeleteContainer;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript) then begin
        ContainerDeleted := true;
      end;
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ContainerDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.ListContainerContents(ContainerName: String): ImmutableList<String>;
const methodName = "S3ExtStorageSystem.ListContainerContents";
begin
  if DebugMode then begin
    writeLn("entering {0} with ContainerName='{1}'", methodName, ContainerName);
  end;

  var ListObjects := new List<String>;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);

  const ScriptTemplate = scrTemplateListContainerContents;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if not RunProgram(RunScript, ListObjects) then begin
        ListObjects.RemoveAll();
        writeLn("{0} - error: unable to run program", methodName);
      end;
    end
    else begin
      writeLn("{0} - error: unable to prepare run script", methodName);
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ListObjects;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetObjectMetadata(ContainerName: String;
                                            ObjectName: String;
                                            DictProps: PropertySet): Boolean;
var
  StdOut: String;
begin
  if DebugMode then begin
    writeLn("GetObjectMetadata: Container={0}, Object={1}",
            ContainerName, ObjectName);
  end;

  var Success := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);
  PopulateObject(Kvp, ObjectName);

  const ScriptTemplate = scrTemplateHeadObject;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript, out StdOut) then begin
        writeLn("{0}", StdOut);
        Success := true;
      end;
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit Success;
end;

//*******************************************************************************

method S3ExtStorageSystem.PutObject(ContainerName: String;
                                    ObjectName: String;
                                    FileContents: array of Byte;
                                    Headers: PropertySet): Boolean;
begin
  if DebugMode then begin
    writeLn("PutObject: Container={0}, Object={1}, Length={3}",
            ContainerName,
            ObjectName,
            FileContents.length);
  end;

  var ObjectAdded := false;

  const TmpFile = "tmp_" + ContainerName + "_" + ObjectName;

  if Utils.FileWriteAllBytes(TmpFile, FileContents) then begin
    Utils.FileSetPermissions(TmpFile, 6, 0, 0);
    ObjectAdded := PutObjectFromFile(ContainerName,
                                     ObjectName,
                                     TmpFile,
                                     Headers);
    Utils.DeleteFile(TmpFile);
  end
  else begin
    writeLn("error: PutObject not able to write to tmp file");
  end;

  exit ObjectAdded;
end;

//*******************************************************************************

method S3ExtStorageSystem.PutObjectFromFile(ContainerName: String;
                                            ObjectName: String;
                                            FilePath: String;
                                            Headers: PropertySet): Boolean;
begin
  if DebugMode then begin
    writeLn("PutObjectFromFile: Container={0}, Object={1}, FilePath={2}",
            ContainerName,
            ObjectName,
            FilePath);
  end;

  var ObjectAdded := false;
  var sbMetadataProps := new StringBuilder;

  if Headers <> nil then begin
    if Headers.Contains(PROP_CONTENT_LENGTH) then begin
      const contentLength =
           Headers.GetULongValue(PROP_CONTENT_LENGTH);
      sbMetadataProps.Append("contentLength=");
      sbMetadataProps.Append(Convert.ToString(contentLength));
      sbMetadataProps.Append(" ");
    end;

    if Headers.Contains(PROP_CONTENT_TYPE) then begin
      const contentType =
          Headers.GetStringValue(PROP_CONTENT_TYPE);
      // contentType
      if contentType.Length > 0 then begin
        sbMetadataProps.Append("contentType=");
        sbMetadataProps.Append(contentType);
        sbMetadataProps.Append(" ");
      end;
    end;

    if Headers.Contains(PROP_CONTENT_MD5) then begin
      const contentMd5 =
        Headers.GetStringValue(PROP_CONTENT_MD5);
      // md5
      if contentMd5.Length > 0 then begin
        sbMetadataProps.Append("md5=");
        sbMetadataProps.Append(contentMd5);
        sbMetadataProps.Append(" ");
      end;
    end;

    if Headers.Contains(PROP_CONTENT_ENCODING) then begin
      const contentEncoding =
        Headers.GetStringValue(PROP_CONTENT_ENCODING);
      // contentEncoding
      if contentEncoding.Length > 0 then begin
        sbMetadataProps.Append("contentEncoding=");
        sbMetadataProps.Append(contentEncoding);
        sbMetadataProps.Append(" ");
      end;
    end;
  end;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);
  PopulateObject(Kvp, ObjectName);

  var ScriptTemplate := "";

  var MetadataProps: String := sbMetadataProps.ToString();
  MetadataProps := MetadataProps.Trim();

  if MetadataProps.Length > 0 then begin
    ScriptTemplate := scrTemplatePutObjectWithProperties;
    Kvp.AddPair("%%METADATA_PROPERTIES%%", MetadataProps);
  end
  else begin
    ScriptTemplate := scrTemplatePutObject;
  end;

  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript) then begin
        ObjectAdded := true;
      end;
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ObjectAdded;
end;

//*******************************************************************************

method S3ExtStorageSystem.DeleteObject(ContainerName: String;
                                       ObjectName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("DeleteObject: Container={0}, Object={1}",
             ContainerName, ObjectName);
  end;

  var ObjectDeleted := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);
  PopulateObject(Kvp, ObjectName);

  const ScriptTemplate = scrTemplateDeleteObject;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript) then begin
        ObjectDeleted := true;
      end;
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  exit ObjectDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetObject(ContainerName: String;
                                    ObjectName: String;
                                    LocalFilePath: String): Int64;
begin
  if DebugMode then begin
    writeLn("GetObject: Container={0}, Object={1}, LocalFilePath={2}",
             ContainerName, ObjectName,
             LocalFilePath);
  end;

  if LocalFilePath.Length = 0 then begin
    writeLn("error: local file path is empty");
    exit 0;
  end;

  var Success := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);
  PopulateObject(Kvp, ObjectName);
  Kvp.AddPair("%%OUTPUT_FILE%%", LocalFilePath);

  const ScriptTemplate = scrTemplateGetObject;
  const RunScript = Utils.PathJoin(ScriptDirectory,
                                   RunScriptNameForTemplate(ScriptTemplate));

  try
    if PrepareRunScript(ScriptTemplate, RunScript, Kvp) then begin
      if RunProgram(RunScript) then begin
        Success := true;
      end;
    end;
  finally
    Utils.DeleteFileIfExists(RunScript);
  end;

  if Success and Utils.FileExists(LocalFilePath) then begin
    exit Utils.GetFileSize(LocalFilePath);
  end
  else begin
    exit 0;
  end;
end;

//*******************************************************************************

method S3ExtStorageSystem.PopulateCommonVariables(Kvp: KeyValuePairs);
begin
  Kvp.AddPair("%%S3_ENDPOINT_URL%%", EndpointUrl);
  Kvp.AddPair("%%S3_REGION%%", Region);
end;

//*****************************************************************************

method S3ExtStorageSystem.PopulateBucket(Kvp: KeyValuePairs; BucketName: String);
begin
  Kvp.AddPair("%%BUCKET_NAME%%", BucketName);
end;

//*****************************************************************************

method S3ExtStorageSystem.PopulateObject(Kvp: KeyValuePairs; ObjectName: String);
begin
  Kvp.AddPair("%%OBJECT_NAME%%", ObjectName);
end;

//*****************************************************************************

method S3ExtStorageSystem.RunProgram(ProgramPath: String;
                                     ListOutputLines: List<String>): Boolean;
begin
  var StdOut := "";
  var StdErr := "";
  var Success := false;

  if not Utils.FileExists(ProgramPath) then begin
    writeLn("RunProgram: error '{0}' does not exist", ProgramPath);
    exit false;
  end;

  var IsShellScript := false;
  var ExecutablePath := ProgramPath;

  if ProgramPath.EndsWith(".sh") then begin
    const FileLines = Utils.FileReadTextLines(ProgramPath);
    if FileLines.Count = 0 then begin
      writeLn("RunProgram: unable to read file '{0}'", ProgramPath);
      exit false;
    end;
    const FirstLine = FileLines[0];
    if FirstLine.StartsWith("#!") then begin
      const LineLength = FirstLine.Length;
      ExecutablePath := FirstLine.Substring(2, LineLength-2);
    end
    else begin
      ExecutablePath := "/bin/sh";
    end;
    IsShellScript := true;
  end;

  var ProgramArgs := new List<String>;
  var ExitCode := 0;

  if IsShellScript then begin
    ProgramArgs.Add(ProgramPath);
  end;

  if Utils.ExecuteProgram(ExecutablePath,
                          ProgramArgs,
                          var ExitCode,
                          out StdOut,
                          out StdErr) then begin

    if DebugMode then begin
      writeLn("ExitCode = {0}", ExitCode);
      writeLn("*********** START STDOUT **************");
      writeLn("{0}", StdOut);
      writeLn("*********** END STDOUT **************");
    end;

    if ExitCode = 0 then begin
      if StdOut.Length > 0 then begin
        const OutputLines = StdOut.Split(Environment.LineBreak, true);
        for each line in OutputLines do begin
          if line.Length > 0 then begin
            ListOutputLines.Add(line);
          end;
        end;
      end;
      Success := true;
    end;
  end;

  exit Success;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunProgram(ProgramPath: String;
                                     out StdOut: String): Boolean;
begin
  var StdErr := "";
  var Success := false;

  if not Utils.FileExists(ProgramPath) then begin
    writeLn("RunProgram: error '{0}' does not exist", ProgramPath);
    exit false;
  end;

  var IsShellScript := false;
  var ExecutablePath := ProgramPath;

  if ProgramPath.EndsWith(".sh") then begin
    const FileLines = Utils.FileReadTextLines(ProgramPath);
    if FileLines.Count = 0 then begin
      writeLn("RunProgram: unable to read file '{0}'", ProgramPath);
      exit false;
    end;
    const FirstLine = FileLines[0];
    if FirstLine.StartsWith("#!") then begin
      const LineLength = FirstLine.Length;
      ExecutablePath := FirstLine.Substring(2, LineLength-2);
    end
    else begin
      ExecutablePath := "/bin/sh";
    end;
    IsShellScript := true;
  end;

  var ProgramArgs := new List<String>;
  var ExitCode := 0;

  if IsShellScript then begin
    ProgramArgs.Add(ProgramPath);
  end;

  if Utils.ExecuteProgram(ExecutablePath,
                          ProgramArgs,
                          var ExitCode,
                          out StdOut,
                          out StdErr) then begin
    if ExitCode = 0 then begin
      Success := true;
    end;
  end;

  exit Success;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunProgram(ProgramPath: String): Boolean;
begin
  var StdOut := "";
  var StdErr := "";
  var Success := false;

  if not Utils.FileExists(ProgramPath) then begin
    writeLn("RunProgram: error '{0}' does not exist", ProgramPath);
    exit false;
  end;

  var IsShellScript := false;
  var ExecutablePath := ProgramPath;

  if ProgramPath.EndsWith(".sh") then begin
    const FileLines = Utils.FileReadTextLines(ProgramPath);
    if FileLines.Count = 0 then begin
      writeLn("RunProgram: unable to read file '{0}'", ProgramPath);
      exit false;
    end;
    const FirstLine = FileLines[0];
    if FirstLine.StartsWith("#!") then begin
      const LineLength = FirstLine.Length;
      ExecutablePath := FirstLine.Substring(2, LineLength-2);
    end
    else begin
      ExecutablePath := "/bin/sh";
    end;
    IsShellScript := true;
  end;

  var ProgramArgs := new List<String>;
  var ExitCode := 0;

  if IsShellScript then begin
    ProgramArgs.Add(ProgramPath);
  end;

  if Utils.ExecuteProgram(ExecutablePath,
                          ProgramArgs,
                          var ExitCode,
                          out StdOut,
                          out StdErr) then begin
    if ExitCode = 0 then begin
      Success := true;
    end;
  end;

  exit Success;
end;

//*****************************************************************************

method S3ExtStorageSystem.PrepareRunScript(ScriptTemplate: String;
                                           RunScript: String;
                                           Kvp: KeyValuePairs): Boolean;
begin
  Utils.DeleteFileIfExists(RunScript);

  if not Utils.FileCopy(Utils.PathJoin(ScriptDirectory, ScriptTemplate), RunScript) then begin
    exit false;
  end;

  //if not Utils.FileSetPermissions(RunScript, 7, 0, 0) then begin
  //   exit false;
  //end;

  var FileText := Utils.FileReadAllText(RunScript);
  if FileText.Length = 0 then begin
    exit false;
  end;

  const kvpKeys = Kvp.GetKeys();
  for each key in kvpKeys do begin
    const value = Kvp.GetValue(key);
    FileText := FileText.Replace(key, value);
  end;

  if not Utils.FileWriteAllText(RunScript, FileText) then begin
    exit false;
  end;

  exit true;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunScriptNameForTemplate(ScriptTemplate: String): String;
begin
  exit runScriptNamePrefix + ScriptTemplate;
end;

//*****************************************************************************

end.