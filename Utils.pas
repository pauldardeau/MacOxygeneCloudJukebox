namespace MacOxygeneCloudJukebox;

type
	Utils = public static class

	public
		const PLATFORM_MAC = "mac";
		const PLATFORM_LINUX = "linux";
		const PLATFORM_WINDOWS = "windows";
		const PLATFORM_UNKNOWN = "unknown";

//*******************************************************************************

		method DirectoryExists(DirPath: String): Boolean;
		begin
			exit RemObjects.Elements.RTL.Folder(DirPath).Exists();
		end;

//*******************************************************************************

		method CreateDirectory(DirPath: String): Boolean;
		begin
			if DirectoryExists(DirPath) then begin
				exit false;
			end
			else begin
				try
					RemObjects.Elements.RTL.Folder(DirPath).Create();
					exit true;
				except
					exit false;
				end;
			end;
		end;

//*******************************************************************************

		method DeleteDirectory(DirPath: String): Boolean;
		begin
			if DirectoryExists(DirPath) then begin
				try
					RemObjects.Elements.RTL.Folder(DirPath).Delete();
					exit true;
				except
					exit false;
				end;
			end
			else begin
				exit false;
			end;
		end;

//*******************************************************************************

		method ListFilesInDirectory(DirPath: String): List<String>;
		begin
			var theFolder := RemObjects.Elements.RTL.Folder(DirPath);
			const lenDirPath = DirPath.Length;
			var listFiles := new List<String>;
			var strippedFile: String;
			for each fileWithPath in theFolder.GetFiles() do begin
				strippedFile := fileWithPath.Substring(lenDirPath);
				if strippedFile[0] = RemObjects.Elements.RTL.Path.DirectorySeparatorChar then begin
					strippedFile := strippedFile.Substring(1);
				end;
				listFiles.Add(strippedFile);
			end;
			result := listFiles;
		end;

//*******************************************************************************

		method ListDirsInDirectory(DirPath: String): List<String>;
		begin
			const lenDirPath = DirPath.Length;
			var listSubdirs := new List<String>;
			var strippedDir: String;
			for each subDirWithPath in RemObjects.Elements.RTL.Folder(DirPath).GetSubfolders() do begin
				strippedDir := subDirWithPath.Substring(lenDirPath);
				if strippedDir[0] = RemObjects.Elements.RTL.Path.DirectorySeparatorChar then begin
					strippedDir := strippedDir.Substring(1);
				end;
				listSubdirs.Add(strippedDir);
			end;
			result := listSubdirs;
		end;

//*******************************************************************************

		method DeleteFilesInDirectory(DirPath: String);
		begin
			const listFiles = ListFilesInDirectory(DirPath);
			for each FileName in listFiles do begin
				const FilePath = PathJoin(DirPath, FileName);
				DeleteFile(FilePath);
			end;
		end;

//*******************************************************************************

		method PathJoin(DirPath: String; FileName: String): String;
		begin
			const DirPathSeparator = RemObjects.Elements.RTL.Path.DirectorySeparatorChar;
			if not DirPath.EndsWith(DirPathSeparator) then begin
				exit DirPath + DirPathSeparator + FileName;
			end
			else begin
				exit DirPath + FileName;
			end;
			//result := RemObjects.Elements.RTL.Path.Combine(DirPath, FileName);
		end;

//*******************************************************************************

		method PathSplitExt(FilePath: String): tuple of (String, String);
		begin
			// splitext("bar") -> ("bar", "")
			// splitext("foo.bar.exe") -> ("foo.bar", ".exe")
			// splitext("/foo/bar.exe") -> ("/foo/bar", ".exe")
			// splitext(".cshrc") -> (".cshrc", "")
			// splitext("/foo/....jpg") -> ("/foo/....jpg", "")

			var Root := "";
			var Ext := "";

			if FilePath.Length > 0 then begin
				const PosLastDot = FilePath.LastIndexOf('.');
				if PosLastDot = -1 then begin
					// no '.' exists in path (i.e., "bar")
					Root := FilePath;
				end
				else begin
					// is the last '.' the first character? (i.e., ".cshrc")
					if PosLastDot = 0 then begin
						Root := FilePath;
					end
					else begin
						const preceding = FilePath[PosLastDot-1];
						// is the preceding char also a '.'? (i.e., "/foo/....jpg")
						if preceding = '.' then begin
							Root := FilePath;
						end
						else begin
							// splitext("foo.bar.exe") -> ("foo.bar", ".exe")
							// splitext("/foo/bar.exe") -> ("/foo/bar", ".exe")
							Root := FilePath.Substring(0, PosLastDot);
							Ext := FilePath.Substring(PosLastDot);
						end;
					end;
				end;
			end;

			result := (Root, Ext);
		end;

//*******************************************************************************

		method FileExists(FilePath: String): Boolean;
		begin
			exit RemObjects.Elements.RTL.File(FilePath).Exists();
		end;

//*******************************************************************************

		method DeleteFile(FilePath: String): Boolean;
		begin
			if FileExists(FilePath) then begin
				try
					RemObjects.Elements.RTL.File(FilePath).Delete();
					exit true;
				except
					exit false;
				end;
			end
			else begin
				exit false;
			end;
		end;

//*******************************************************************************

		method DeleteFileIfExists(FilePath: String): Boolean;
		begin
			if FileExists(FilePath) then begin
				exit DeleteFile(FilePath);
			end
			else begin
				exit false;
			end;
		end;

//*******************************************************************************

		method RenameFile(OldPath: String; NewPath: String): Boolean;
		begin
			if FileExists(OldPath) then begin
				try
					var NewFile := RemObjects.Elements.RTL.File(OldPath).Rename(NewPath);
					exit NewFile.Exists();
				except
					exit false;
				end;
			end
			else begin
				exit false;
			end;
		end;

//*******************************************************************************

		method FileCopy(Source: String; Target: String): Boolean;
		begin
			try
				var SourceFile := RemObjects.Elements.RTL.File(Source);
				SourceFile.CopyTo(Target);
				exit true;
			except
				exit false;
			end;
		end;

//*******************************************************************************

		method FileSetPermissions(FilePath: String;
															UserPerms: Integer;
															GroupPerms: Integer;
															WorldPerms: Integer): Boolean;
		begin
			//TODO: implement FileSetPermissions
			exit false;
		end;

//*******************************************************************************

		method FileWriteAllBytes(FilePath: String; Contents: array of Byte): Boolean;
		begin
			try
				RemObjects.Elements.RTL.File.WriteBytes(FilePath, Contents);
				exit true;
			except
				exit false;
			end;
		end;

//*******************************************************************************

		method FileReadAllBytes(FilePath: String): array of Byte;
		begin
			exit RemObjects.Elements.RTL.File.ReadBytes(FilePath);
		end;

//*******************************************************************************

		method FileWriteAllText(FilePath: String; Contents: String): Boolean;
		begin
			try
				const Encoding = RemObjects.Elements.RTL.Encoding.UTF8;
				RemObjects.Elements.RTL.File.WriteText(FilePath, Contents, Encoding);
				exit true;
			except
				exit false;
			end;
		end;

//*******************************************************************************

		method FileAppendAllText(FilePath: String; Contents: String): Boolean;
		begin
			if FileExists(FilePath) then begin
				try
					RemObjects.Elements.RTL.File.AppendText(FilePath, Contents);
					exit true;
				except
					exit false;
				end;
			end
			else begin
				exit FileWriteAllText(FilePath, Contents);
			end;
		end;

//*******************************************************************************

		method FileReadAllText(FilePath: String): String;
		begin
			exit RemObjects.Elements.RTL.File.ReadText(FilePath);
		end;

//*******************************************************************************

		method FileReadTextLines(FilePath: String): ImmutableList<String>;
		begin
			const Encoding = RemObjects.Elements.RTL.Encoding.UTF8;
			exit RemObjects.Elements.RTL.File.ReadLines(FilePath, Encoding);
		end;

//*******************************************************************************

		method Md5ForFile(IniFileName: String; PathToFile: String): String;
		begin
			if not FileExists(IniFileName) then begin
				writeLn("error (Md5ForFile): ini file does not exist '{0}'", IniFileName);
				exit "";
			end;

			if not FileExists(PathToFile) then begin
				writeLn("error (Md5ForFile): file does not exist '%s'", PathToFile);
				exit "";
			end;

			var Kvp := new KeyValuePairs;
			if GetPlatformConfigValues(IniFileName, Kvp) then begin
				const KeyExe = "md5_exe_file_name";
				const KeyFieldNumber = "md5_hash_output_field";
				if Kvp.ContainsKey(KeyExe) then begin
					const Md5Exe = Kvp.GetValue(KeyExe);
					if not FileExists(Md5Exe) then begin
						writeLn("error: md5 executable not found: '{0}'", Md5Exe);
						exit "";
					end;

					var ProgramArgs := new List<String>;
					ProgramArgs.Add(PathToFile);
					var ExitCode := 0;
					var StdOut := "";
					var StdErr := "";

					if ExecuteProgram(Md5Exe,
														ProgramArgs,
														var ExitCode,
														out StdOut,
														out StdErr) then begin
						if ExitCode = 0 then begin
							if StdOut.Length() > 0 then begin
								var FieldNumber := 1;
								if Kvp.ContainsKey(KeyFieldNumber) then begin
									const FieldNumberText = Kvp.GetValue(KeyFieldNumber);
									if FieldNumberText.Length() > 0 then begin
										try
											FieldNumber := Convert.ToInt32(FieldNumberText);
										except
											writeLn("error: unable to convert value '{0}' for '{1}' to integer",
															FieldNumberText,
															KeyFieldNumber);
												writeLn("will attempt to use first field");
										end;
									end;
								end;
								const FileLines = StdOut.Split(Environment.LineBreak);
								if FileLines.Count > 0 then begin
									const FirstLine = FileLines[0];
									const LineFields = FirstLine.Split(" ");
									if LineFields.Count > 0 then begin
										exit LineFields[FieldNumber-1];
									end
									else begin
										if FirstLine.Length() > 0 then begin
											exit FirstLine;
										end
										else begin
											writeLn("error: Md5ForFile - first stdout line is empty");
										end;
									end;
								end
								else begin
									writeLn("error: Md5ForFile - stdout split by lines is empty");
								end;
							end
							else begin
								writeLn("error: Md5ForFile - no content for stdout captured");
							end;
						end
						else begin
							writeLn("error: Md5ForFile - non-zero exit code for md5 utility. value={0}", ExitCode);
						end;
					end
					else begin
						writeLn("error: Md5ForFile - unable to execute md5 sum utility '{0}'", Md5Exe);
					end;
				end
				else begin
					writeLn("error: Md5ForFile - no value present for '{0}'", KeyExe);
				end;
			end
			else begin
				writeLn("error: Md5ForFile - unable to retrieve platform config values");
			end;

			result := '';
		end;

//*******************************************************************************

		method GetPid(): Integer;
		begin
			{$IFDEF MACOS}
			//TODO: obtain PID on MacOS
			exit Environment.ProcessID;
			{$ELSE}
				{$IFDEF ISLAND}
				exit RemObjects.Elements.System.Process.CurrentProcessId();
				{$ELSE}
				exit Environment.ProcessID;
				{$ENDIF}
			{$ENDIF}
		end;

//*******************************************************************************

		method GetFileSize(FilePath: String): Int64;
		begin
			exit RemObjects.Elements.RTL.File(FilePath).Size;
		end;

//*******************************************************************************

		method GetCurrentDirectory: String;
		begin
			exit RemObjects.Elements.RTL.Environment.CurrentDirectory;
		end;

//*******************************************************************************

		method SleepSeconds(seconds: Integer);
		begin
			RemObjects.Elements.RTL.Thread.Sleep(1000 * seconds);
		end;

//*******************************************************************************

		method GetBaseFileName(FileName: String): String;
		begin
			exit RemObjects.Elements.RTL.Path.GetFileNameWithoutExtension(FileName);
		end;

//*******************************************************************************

		method GetFileExtension(FileName: String): String;
		begin
			exit RemObjects.Elements.RTL.File(FileName).Extension;
		end;

//*******************************************************************************

		method ExecuteProgram(ProgramPath: String;
													ProgramArgs: ImmutableList<String>;
													var ExitCode: Integer;
													out StdOut: String;
													out StdErr: String): Boolean;
		begin
			try
				ExitCode := Process.Run(ProgramPath,
																ProgramArgs,
																nil,
																nil,
																out StdOut,
																out StdErr);
				exit true;
			except
				exit false;
			end;
		end;

//*******************************************************************************

		method GetPlatformIdentifier: String;
		begin
			{$IFDEF MACOS}
			exit PLATFORM_MAC;
			{$ELSEIF LINUX}
			exit PLATFORM_LINUX;
			{$ELSEIF WINDOWS}
			exit PLATFORM_WINDOWS;
			{$ELSE}
			exit PLATFORM_UNKNOWN;
			{$ENDIF}
		end;

//*******************************************************************************

		method GetPlatformConfigValues(IniFileName: String;
																	 Kvp: KeyValuePairs): Boolean;
		begin
			const OsIdentifier = GetPlatformIdentifier();
			if (OsIdentifier = PLATFORM_UNKNOWN) or (OsIdentifier.Length() = 0) then begin
				writeLn("error: unknown platform");
				exit false;
			end;

			try
				const Reader = new IniReader(IniFileName);
				if not Reader.ReadSection(OsIdentifier, Kvp) then begin
					writeLn("error: no config section present for '{0}'", OsIdentifier);
					exit false;
				end
				else begin
					exit true;
				end;
			except
				writeLn("error: unable to read {0}", IniFileName);
				exit false;
			end;
		end;

//*******************************************************************************

end;

end.