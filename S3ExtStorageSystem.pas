namespace MacOxygeneCloudJukebox;

interface
type
  S3ExtStorageSystem = public class(StorageSystem)
  private
    DebugMode: Boolean;
    AwsAccessKey: String;
    AwsSecretKey: String;
    S3Host: String;
    ListContainers: List<String>;

  public
    constructor(AccessKey: String;
                SecretKey: String;
                Protocol: String;
                Host: String;
                ContainerPrefix: String;
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
                             Headers: PropertySet): Boolean;
    method DeleteObject(ContainerName: String; ObjectName: String): Boolean; override;
    method GetObject(ContainerName: String;
                     ObjectName: String;
                     LocalFilePath: String): Int64; override;

  protected
    method PopulateCommonVariables(Kvp: KeyValuePairs);
    method PopulateBucket(Kvp: KeyValuePairs; BucketName: String);
    method PopulateObject(Kvp: KeyValuePairs; ObjectName: String);
    method RunProgram(ProgramPath: String; ListOutputLines: List<String>): Boolean;
    method RunProgram(ProgramPath: String): Boolean;
    method RunProgram(ProgramPath: String; out StdOut: String): Boolean;
    method PrepareRunScript(ScriptTemplate: String; Kvp: KeyValuePairs): Boolean;
    method RunScriptNameForTemplate(ScriptTemplate: String): String;

  end;

//*******************************************************************************

implementation

constructor S3ExtStorageSystem(AccessKey: String;
                               SecretKey: String;
                               Protocol: String;
                               Host: String;
                               ContainerPrefix: String;
                               aDebugMode: Boolean);
begin
  DebugMode := aDebugMode;
  AwsAccessKey := AccessKey;
  AwsSecretKey := SecretKey;
  S3Host := Host;
  ListContainers := new List<String>;
end;

//*******************************************************************************

method S3ExtStorageSystem.Enter(): Boolean;
begin
  if DebugMode then begin
     writeLn("S3ExtStorageSystem.enter");
  end;

  ListContainers := ListAccountContainers();
  result := true;
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
begin
  if DebugMode then begin
    writeLn("ListAccountContainers");
  end;

  var ListOfContainers := new List<String>;
  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);

  const ScriptTemplate = "s3-list-containers.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if not RunProgram(RunScript, ListOfContainers) then begin
      ListOfContainers.RemoveAll();
      writeLn("S3ExtStorageSystem.ListAccountContainers - error: unable to run script");
    end;
  end
  else begin
    writeLn("S3ExtStorageSystem.ListAccountContainers - error: unable to prepare script");
  end;

  Utils.DeleteFile(RunScript);

  result := ListOfContainers;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetContainerNames: ImmutableList<String>;
begin
  result := ListContainers;
end;

//*******************************************************************************

method S3ExtStorageSystem.HasContainer(ContainerName: String): Boolean;
begin
  result := ListContainers.Contains(ContainerName);
end;

//*******************************************************************************

method S3ExtStorageSystem.CreateContainer(ContainerName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("CreateContainer: {0}", ContainerName);
  end;

  var ContainerCreated := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);

  const ScriptTemplate = "s3-create-container.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if RunProgram(RunScript) then begin
      ContainerCreated := true;
    end
    else begin
      writeLn("S3ExtStorageSystem.CreateContainer - error: create container '%s' failed", ContainerName);
    end;
  end
  else begin
    writeLn("S3ExtStorageSystem.CreateContainer - error: unable to prepare run script");
  end;

  Utils.DeleteFile(RunScript);

  result := ContainerCreated;
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

  const ScriptTemplate = "s3-delete-container.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if RunProgram(RunScript) then begin
      ContainerDeleted := true;
    end;
  end;

  Utils.DeleteFile(RunScript);

  result := ContainerDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.ListContainerContents(ContainerName: String): ImmutableList<String>;
begin
  if DebugMode then begin
    writeLn("ListContainerContents: {0}", ContainerName);
  end;

  var ListObjects := new List<String>;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);

  const ScriptTemplate = "s3-list-container-contents.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if not RunProgram(RunScript, ListObjects) then begin
      ListObjects.RemoveAll();
      writeLn("S3ExtStorageSystem.ListContainerContents - error: unable to run program");
    end;
  end
  else begin
    writeLn("S3ExtStorageSystem.ListContainerContents - error: unable to prepare run script");
  end;

  Utils.DeleteFile(RunScript);

  result := ListObjects;
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

  const ScriptTemplate = "s3-head-object.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
     if RunProgram(RunScript, out StdOut) then begin
       writeLn("{0}", StdOut);
       Success := true;
     end;
  end;

  Utils.DeleteFile(RunScript);

  result := Success;
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

  result := ObjectAdded;
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

  /*
  put                  : Puts an object
    <bucket>/<key>     : Bucket/key to put object to
    [filename]         : Filename to read source data from (default is stdin)
    [contentLength]    : How many bytes of source data to put (required if
                         source file is stdin)
    [cacheControl]     : Cache-Control HTTP header string to associate with
                         object
    [contentType]      : Content-Type HTTP header string to associate with
                         object
    [md5]              : MD5 for validating source data
    [contentDispositionFilename] : Content-Disposition filename string to
                         associate with object
    [contentEncoding]  : Content-Encoding HTTP header string to associate
                         with object
    [expires]          : Expiration date to associate with object
    [cannedAcl]        : Canned ACL for the object (see Canned ACLs)
    [x-amz-meta-...]]  : Metadata headers to associate with the object
  */

  // each metadata property (aside from predefined ones) gets "x-amz-meta-" prefix

  // predefined properties:
  //   contentLength
  //   cacheControl
  //   contentType
  //   md5
  //   contentDispositionFilename
  //   contentEncoding
  //   expires
  //   cannedAcl

  var sbMetadataProps := new StringBuilder;

  if Headers <> nil then begin
    if Headers.Contains(PropertySet.PROP_CONTENT_LENGTH) then begin
      const content_length =
           Headers.GetULongValue(PropertySet.PROP_CONTENT_LENGTH);
      sbMetadataProps.Append("contentLength=");
      sbMetadataProps.Append(String(content_length));
      sbMetadataProps.Append(" ");
    end;

    if Headers.Contains(PropertySet.PROP_CONTENT_TYPE) then begin
      const content_type =
          Headers.GetStringValue(PropertySet.PROP_CONTENT_TYPE);
      // contentType
      if content_type.Length() > 0 then begin
        sbMetadataProps.Append("contentType=");
        sbMetadataProps.Append(content_type);
        sbMetadataProps.Append(" ");
      end;
    end;

    if Headers.Contains(PropertySet.PROP_CONTENT_MD5) then begin
      const content_md5 =
        Headers.GetStringValue(PropertySet.PROP_CONTENT_MD5);
      // md5
      if content_md5.Length() > 0 then begin
        sbMetadataProps.Append("md5=");
        sbMetadataProps.Append(content_md5);
        sbMetadataProps.Append(" ");
      end;
    end;

    if Headers.Contains(PropertySet.PROP_CONTENT_ENCODING) then begin
      const content_encoding =
        Headers.GetStringValue(PropertySet.PROP_CONTENT_ENCODING);
      // contentEncoding
      if content_encoding.Length() > 0 then begin
        sbMetadataProps.Append("contentEncoding=");
        sbMetadataProps.Append(content_encoding);
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

  if MetadataProps.Length() > 0 then begin
    ScriptTemplate := "s3-put-object-props.sh";
    Kvp.AddPair("%%METADATA_PROPERTIES%%", MetadataProps);
  end
  else begin
    ScriptTemplate := "s3-put-object.sh";
  end;

  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if RunProgram(RunScript) then begin
      ObjectAdded := true;
    end;
  end;

  Utils.DeleteFile(RunScript);

  result := ObjectAdded;
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

  const ScriptTemplate = "s3-delete-object.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if RunProgram(RunScript) then begin
      ObjectDeleted := true;
    end;
  end;

  Utils.DeleteFile(RunScript);

  result := ObjectDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetObject(ContainerName: String;
                                    ObjectName: String;
                                    LocalFilePath: String): Int64;
begin
  if DebugMode then begin
    writeLn("GetObject: Container={0}, Object={1}, LocalFilePath={3}",
             ContainerName, ObjectName,
             LocalFilePath);
  end;

  if LocalFilePath.Length() = 0 then begin
    writeLn("error: local file path is empty");
    exit 0;
  end;

  var Success := false;

  var Kvp := new KeyValuePairs;
  PopulateCommonVariables(Kvp);
  PopulateBucket(Kvp, ContainerName);
  PopulateObject(Kvp, ObjectName);
  Kvp.AddPair("%%OUTPUT_FILE%%", LocalFilePath);

  const ScriptTemplate = "s3-get-object.sh";
  const RunScript = RunScriptNameForTemplate(ScriptTemplate);

  if PrepareRunScript(ScriptTemplate, Kvp) then begin
    if RunProgram(RunScript) then begin
      Success := true;
    end;
  end;

  Utils.DeleteFile(RunScript);

  if Success then begin
    result := Utils.GetFileSize(LocalFilePath);
  end
  else begin
    result := 0;
  end;
end;

//*******************************************************************************

method S3ExtStorageSystem.PopulateCommonVariables(Kvp: KeyValuePairs);
begin
  Kvp.AddPair("%%S3_ACCESS_KEY%%", AwsAccessKey);
  Kvp.AddPair("%%S3_SECRET_KEY%%", AwsSecretKey);
  Kvp.AddPair("%%S3_HOST%%", S3Host);
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
var
  StdOut: String;
  StdErr: String;
begin
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
      const LineLength = FirstLine.Length();
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
      if StdOut.Length() > 0 then begin
        const OutputLines = StdOut.Split("\n", true);
        for each line in OutputLines do begin
          if line.Length() > 0 then begin
            ListOutputLines.Add(line);
          end;
        end;
      end;
      Success := true;
    end;
  end;

  result := Success;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunProgram(ProgramPath: String;
                                     out StdOut: String): Boolean;
var
  StdErr: String;
begin
   var success := false;

   if not Utils.FileExists(ProgramPath) then begin
      writeLn("RunProgram: error '{0}' does not exist", ProgramPath);
      exit false;
   end;

   var is_shell_script := false;
   var ExecutablePath := ProgramPath;

   if ProgramPath.EndsWith(".sh") then begin
      const FileLines = Utils.FileReadTextLines(ProgramPath);
      if FileLines.Count = 0 then begin
         writeLn("RunProgram: unable to read file '{0}'", ProgramPath);
         exit false;
      end;
      const FirstLine = FileLines[0];
      if FirstLine.StartsWith("#!") then begin
         const LineLength = FirstLine.Length();
         ExecutablePath := FirstLine.Substring(2, LineLength-2);
      end
      else begin
         ExecutablePath := "/bin/sh";
      end;
      is_shell_script := true;
   end;

   var program_args := new List<String>;
   var ExitCode := 0;

   if is_shell_script then begin
      program_args.Add(ProgramPath);
   end;

   if Utils.ExecuteProgram(ExecutablePath,
                           program_args,
                           var ExitCode,
                           out StdOut,
                           out StdErr) then begin
      if ExitCode = 0 then begin
         success := true;
      end;
   end;

   result := success;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunProgram(ProgramPath: String): Boolean;
var
  StdOut: String;
  StdErr: String;
begin
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
      const LineLength = FirstLine.Length();
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

  result := Success;
end;

//*****************************************************************************

method S3ExtStorageSystem.PrepareRunScript(ScriptTemplate: String;
                                           Kvp: KeyValuePairs): Boolean;
begin
   const RunScript = RunScriptNameForTemplate(ScriptTemplate);

   if not Utils.FileCopy(ScriptTemplate, RunScript) then begin
      exit false;
   end;

   if not Utils.FileSetPermissions(RunScript, 7, 0, 0) then begin
      exit false;
   end;

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

   result := true;
end;

//*****************************************************************************

method S3ExtStorageSystem.RunScriptNameForTemplate(ScriptTemplate: String): String;
begin
   result := "exec-" + ScriptTemplate;
end;

//*****************************************************************************

end.