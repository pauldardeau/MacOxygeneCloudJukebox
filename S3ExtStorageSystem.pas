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
    constructor(accessKey: String;
                secretKey: String;
                protocol: String;
                host: String;
                containerPrefix: String;
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
    method populate_common_variables(kvp: KeyValuePairs);
    method populate_bucket(kvp: KeyValuePairs; BucketName: String);
    method populate_object(kvp: KeyValuePairs; ObjectName: String);
    method run_program(program_path: String; list_output_lines: List<String>): Boolean;
    method run_program(program_path: String): Boolean;
    method run_program(program_path: String; out StdOut: String): Boolean;
    method prepare_run_script(script_template: String; kvp: KeyValuePairs): Boolean;
    method run_script_name_for_template(script_template: String): String;

  end;

//*******************************************************************************

implementation

constructor S3ExtStorageSystem(accessKey: String;
                               secretKey: String;
                               protocol: String;
                               host: String;
                               containerPrefix: String;
                               aDebugMode: Boolean);
begin
  DebugMode := aDebugMode;
  AwsAccessKey := accessKey;
  AwsSecretKey := secretKey;
  S3Host := host;
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
  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);

  const script_template = "s3-list-containers.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if not run_program(run_script, ListOfContainers) then begin
        ListOfContainers.RemoveAll();
       writeLn("S3ExtStorageSystem.list_account_containers - error: unable to run script");
     end;
  end
  else begin
    writeLn("S3ExtStorageSystem.list_account_containers - error: unable to prepare script");
  end;

  Utils.DeleteFile(run_script);

  result := ListOfContainers;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetContainerNames: ImmutableList<String>;
begin

end;

//*******************************************************************************

method S3ExtStorageSystem.HasContainer(ContainerName: String): Boolean;
begin

end;

//*******************************************************************************

method S3ExtStorageSystem.CreateContainer(ContainerName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("create_container: {0}", ContainerName);
  end;

  var ContainerCreated := false;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);

  const script_template = "s3-create-container.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script) then begin
        ContainerCreated := true;
     end
     else begin
       writeLn("S3ExtStorageSystem.CreateContainer - error: create container '%s' failed", ContainerName);
     end;
  end
  else begin
    writeLn("S3ExtStorageSystem.CreateContainer - error: unable to prepare run script");
  end;

  Utils.DeleteFile(run_script);

  result := ContainerCreated;
end;

//*******************************************************************************

method S3ExtStorageSystem.DeleteContainer(ContainerName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("delete_container: {0}", ContainerName);
  end;

  var ContainerDeleted := false;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);

  const script_template = "s3-delete-container.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script) then begin
        ContainerDeleted := true;
     end;
  end;

  Utils.DeleteFile(run_script);

  result := ContainerDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.ListContainerContents(ContainerName: String): ImmutableList<String>;
begin
  if DebugMode then begin
    writeLn("list_container_contents: {0}", ContainerName);
  end;

  var list_objects := new List<String>;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);

  const script_template = "s3-list-container-contents.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if not run_program(run_script, list_objects) then begin
        list_objects.RemoveAll();
        writeLn("S3ExtStorageSystem.list_container_contents - error: unable to run program");
     end;
  end
  else begin
    writeLn("S3ExtStorageSystem.list_container_contents - error: unable to prepare run script");
  end;

  Utils.DeleteFile(run_script);

  result := list_objects;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetObjectMetadata(ContainerName: String;
                                            ObjectName: String;
                                            DictProps: PropertySet): Boolean;
var
  StdOut: String;
begin
  if DebugMode then begin
    writeLn("get_object_metadata: container={0}, object={1}",
            ContainerName, ObjectName);
  end;

  var success := false;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);
  populate_object(kvp, ObjectName);

  const script_template = "s3-head-object.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script, out StdOut) then begin
       writeLn("{0}", StdOut);
       success := true;
     end;
  end;

  Utils.DeleteFile(run_script);

  result := success;
end;

//*******************************************************************************

method S3ExtStorageSystem.PutObject(ContainerName: String;
                                    ObjectName: String;
                                    FileContents: array of Byte;
                                    Headers: PropertySet): Boolean;
begin
  if DebugMode then begin
    writeLn("put_object: container=%s, object=%s, length=%ld\n",
             ContainerName,
             ObjectName,
             FileContents.length);
  end;

  var ObjectAdded := false;

  const tmp_file = "tmp_" + ContainerName + "_" + ObjectName;

   if Utils.FileWriteAllBytes(tmp_file, FileContents) then begin
      Utils.FileSetPermissions(tmp_file, 6, 0, 0);
      ObjectAdded := PutObjectFromFile(ContainerName,
                                       ObjectName,
                                       tmp_file,
                                       Headers);
      Utils.DeleteFile(tmp_file);
   end
   else begin
     writeLn("error: put_object not able to write to tmp file");
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
    writeLn("put_object_from_file: container={0}, object={1}, file_path={2}",
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

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);
  populate_object(kvp, ObjectName);

  var script_template := "";

  var MetadataProps: String := sbMetadataProps.ToString();
  MetadataProps := MetadataProps.Trim();

  if MetadataProps.Length() > 0 then begin
    script_template := "s3-put-object-props.sh";
    kvp.AddPair("%%METADATA_PROPERTIES%%", MetadataProps);
  end
  else begin
    script_template := "s3-put-object.sh";
  end;

  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script) then begin
        ObjectAdded := true;
     end;
  end;

  Utils.DeleteFile(run_script);

  result := ObjectAdded;
end;

//*******************************************************************************

method S3ExtStorageSystem.DeleteObject(ContainerName: String;
                                       ObjectName: String): Boolean;
begin
  if DebugMode then begin
    writeLn("delete_object: container={0}, object={1}",
             ContainerName, ObjectName);
  end;

  var ObjectDeleted := false;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);
  populate_object(kvp, ObjectName);

  const script_template = "s3-delete-object.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script) then begin
        ObjectDeleted := true;
     end;
  end;

  Utils.DeleteFile(run_script);

  result := ObjectDeleted;
end;

//*******************************************************************************

method S3ExtStorageSystem.GetObject(ContainerName: String;
                                    ObjectName: String;
                                    LocalFilePath: String): Int64;
begin
  if DebugMode then begin
    writeLn("get_object: container={0}, object={1}, local_file_path={3}",
             ContainerName, ObjectName,
             LocalFilePath);
  end;

  if LocalFilePath.Length() = 0 then begin
    writeLn("error: local file path is empty");
    exit 0;
  end;

  var success := false;

  var kvp := new KeyValuePairs;
  populate_common_variables(kvp);
  populate_bucket(kvp, ContainerName);
  populate_object(kvp, ObjectName);
  kvp.AddPair("%%OUTPUT_FILE%%", LocalFilePath);

  const script_template = "s3-get-object.sh";
  const run_script = run_script_name_for_template(script_template);

  if prepare_run_script(script_template, kvp) then begin
     if run_program(run_script) then begin
        success := true;
     end;
  end;

  Utils.DeleteFile(run_script);

  if success then begin
     result := Utils.GetFileSize(LocalFilePath);
  end
  else begin
     result := 0;
  end;
end;

//*******************************************************************************

method S3ExtStorageSystem.populate_common_variables(kvp: KeyValuePairs);
begin
   kvp.AddPair("%%S3_ACCESS_KEY%%", AwsAccessKey);
   kvp.AddPair("%%S3_SECRET_KEY%%", AwsSecretKey);
   kvp.AddPair("%%S3_HOST%%", S3Host);
end;

//*****************************************************************************

method S3ExtStorageSystem.populate_bucket(kvp: KeyValuePairs; BucketName: String);
begin
   kvp.AddPair("%%BUCKET_NAME%%", BucketName);
end;

//*****************************************************************************

method S3ExtStorageSystem.populate_object(kvp: KeyValuePairs; ObjectName: String);
begin
   kvp.AddPair("%%OBJECT_NAME%%", ObjectName);
end;

//*****************************************************************************

method S3ExtStorageSystem.run_program(program_path: String;
                                      list_output_lines: List<String>): Boolean;
var
  StdOut: String;
  StdErr: String;
begin
   var success := false;

   if not Utils.FileExists(program_path) then begin
      writeLn("run_program: error '{0}' does not exist", program_path);
      exit false;
   end;

   var is_shell_script := false;
   var executable_path := program_path;

   if program_path.EndsWith(".sh") then begin
      const file_lines = Utils.FileReadTextLines(program_path);
      if file_lines.Count = 0 then begin
         writeLn("run_program: unable to read file '{0}'", program_path);
         exit false;
      end;
      const first_line = file_lines[0];
      if first_line.StartsWith("#!") then begin
         const line_length = first_line.Length();
         executable_path := first_line.Substring(2, line_length-2);
      end
      else begin
         executable_path := "/bin/sh";
      end;
      is_shell_script := true;
   end;

   var program_args := new List<String>;
   var ExitCode := 0;

   if is_shell_script then begin
      program_args.Add(program_path);
   end;

   if Utils.ExecuteProgram(executable_path,
                           program_args,
                           var ExitCode,
                           out StdOut,
                           out StdErr) then begin
      //writeLn("exit_code = {0}", exit_code);
      //writeLn("*********** START STDOUT **************");
      //writeLn("{0}", StdOut);
      //writeLn("*********** END STDOUT **************");

      if ExitCode = 0 then begin
         if StdOut.Length() > 0 then begin
            const OutputLines = StdOut.Split("\n", true);
            for each line in OutputLines do begin
               if line.Length() > 0 then begin
                  list_output_lines.Add(line);
               end;
            end;
         end;
         success := true;
      end;
   end;

   result := success;
end;

//*****************************************************************************

method S3ExtStorageSystem.run_program(program_path: String;
                                      out StdOut: String): Boolean;
var
  StdErr: String;
begin
   var success := false;

   if not Utils.FileExists(program_path) then begin
      writeLn("run_program: error '{0}' does not exist", program_path);
      exit false;
   end;

   var is_shell_script := false;
   var executable_path := program_path;

   if program_path.EndsWith(".sh") then begin
      const FileLines = Utils.FileReadTextLines(program_path);
      if FileLines.Count = 0 then begin
         writeLn("run_program: unable to read file '{0}'", program_path);
         exit false;
      end;
      const FirstLine = FileLines[0];
      if FirstLine.StartsWith("#!") then begin
         const LineLength = FirstLine.Length();
         executable_path := FirstLine.Substring(2, LineLength-2);
      end
      else begin
         executable_path := "/bin/sh";
      end;
      is_shell_script := true;
   end;

   var program_args := new List<String>;
   var ExitCode := 0;

   if is_shell_script then begin
      program_args.Add(program_path);
   end;

   if Utils.ExecuteProgram(executable_path,
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

method S3ExtStorageSystem.run_program(program_path: String): Boolean;
var
  StdOut: String;
  StdErr: String;
begin
   var success := false;

   if not Utils.FileExists(program_path) then begin
      writeLn("run_program: error '{0}' does not exist", program_path);
      exit false;
   end;

   var is_shell_script := false;
   var executable_path := program_path;

   if program_path.EndsWith(".sh") then begin
      const file_lines = Utils.FileReadTextLines(program_path);
      if file_lines.Count = 0 then begin
         writeLn("run_program: unable to read file '{0}'", program_path);
         exit false;
      end;
      const first_line = file_lines[0];
      if first_line.StartsWith("#!") then begin
         const line_length = first_line.Length();
         executable_path := first_line.Substring(2, line_length-2);
      end
      else begin
         executable_path := "/bin/sh";
      end;
      is_shell_script := true;
   end;

   var program_args := new List<String>;
   var ExitCode := 0;

   if is_shell_script then begin
      program_args.Add(program_path);
   end;

   if Utils.ExecuteProgram(executable_path,
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

method S3ExtStorageSystem.prepare_run_script(script_template: String;
                                             kvp: KeyValuePairs): Boolean;
begin
   const run_script = run_script_name_for_template(script_template);

   if not Utils.FileCopy(script_template, run_script) then begin
      exit false;
   end;

   if not Utils.FileSetPermissions(run_script, 7, 0, 0) then begin
      exit false;
   end;

   var file_text := Utils.FileReadAllText(run_script);
   if file_text.Length = 0 then begin
      exit false;
   end;

   const kvp_keys = kvp.GetKeys();
   for each key in kvp_keys do begin
      const value = kvp.GetValue(key);
      file_text := file_text.Replace(key, value);
   end;

   if not Utils.FileWriteAllText(run_script, file_text) then begin
      exit false;
   end;

   result := true;
end;

//*****************************************************************************

method S3ExtStorageSystem.run_script_name_for_template(script_template: String): String;
begin
   result := "exec-" + script_template;
end;

//*****************************************************************************

end.