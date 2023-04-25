namespace MacOxygeneCloudJukebox;

interface

type
	IniReader = public class
	private
		IniFile: String;
		FileContents: String;

	public
		const EOL_LF = #10;
		const EOL_CR = #13;
		const OPEN_BRACKET = '[';
		const CLOSE_BRACKET = ']';
		const COMMENT_IDENTIFIER = '#';

		constructor(aIniFile: String);
		method ReadSection(Section: String; var SectionValues: KeyValuePairs): Boolean;
		method GetSectionKeyValue(Section: String;
															Key: String;
															out Value: String): Boolean;
		method HasSection(Section: String): Boolean;
		method ReadFile(): Boolean;

	protected
		method BracketedSection(SectionName: String): String;
	end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor IniReader(aIniFile: String);
begin
	IniFile := aIniFile;
end;

//*******************************************************************************

method IniReader.ReadSection(Section: String;
														 var SectionValues: KeyValuePairs): Boolean;
var
	SectionContents: String;
begin
	const SectionId = BracketedSection(Section);
	const PosSection = FileContents.IndexOf(SectionId);

	if PosSection = -1 then begin
		exit false;
	end;

	const PosEndSection = PosSection + SectionId.Length();
	const StartNextSection =
			FileContents.IndexOf(OPEN_BRACKET, PosEndSection);

	// do we have another section?
	if StartNextSection <> -1 then begin
		// yes, we have another section in the file -- read everything
		// up to the next section
		SectionContents := FileContents.Substring(PosEndSection,
																							StartNextSection - PosEndSection);
	end
	else begin
		// no, this is the last section -- read everything left in
		// the file
		SectionContents := FileContents.Substring(PosEndSection);
	end;

	SectionContents := SectionContents.Trim;

	if SectionContents.Length = 0 then begin
		writeLn("section in .ini file is empty");
		exit false;
	end;

	var SectionLines := SectionContents.Split(Environment.LineBreak);
	var PairsAdded := 0;

	for each SectionLine in SectionLines do begin
		const TrimmedLine = SectionLine.Trim;
		if TrimmedLine.Length > 0 then begin
			if TrimmedLine.Contains("=") then begin
				const LineFields = TrimmedLine.Split("=");
				if LineFields.Count = 2 then begin
					const Key = LineFields[0].Trim;
					const Value = LineFields[1].Trim;
					if (Key.Length > 0) and (Value.Length > 0) then begin
						SectionValues.AddPair(Key, Value);
						inc(PairsAdded);
					end;
				end;
			end;
		end;
	end;

	if PairsAdded > 0 then begin
		exit true;
	end
	else begin
		exit false;
	end;
end;

//*******************************************************************************

method IniReader.GetSectionKeyValue(Section: String;
																		Key: String;
																		out Value: String): Boolean;
begin
	var Map := new KeyValuePairs;

	if not ReadSection(Section, var Map) then begin
		writeLn('IniReader ReadSection returned false');
		exit false;
	end;

	const StrippedKey = Key.Trim();

	if not Map.ContainsKey(StrippedKey) then begin
		writeLn("map does not contain key '{0}'", StrippedKey);
		exit false;
	end;

	Value := Map.GetValue(Key);

	exit true;
end;

//*******************************************************************************

method IniReader.HasSection(Section: String): Boolean;
begin
	const SectionId = BracketedSection(Section);
	exit (-1 <> FileContents.IndexOf(SectionId));
end;

//*******************************************************************************

method IniReader.ReadFile(): Boolean;
var
	PosCommentStart: Integer;
	PosCR: Integer;
	PosLF: Integer;
	PosEOL: Integer;
	BeforeComment: String;
	AfterComment: String;
begin
	FileContents := Utils.FileReadAllText(IniFile);
	if (FileContents = nil) or (FileContents.Length() = 0) then begin
		exit false;
	end;

	// strip out any comments
	var StrippingComments := true;
	var PosCurrent := 0;

	while StrippingComments do begin
		PosCommentStart := FileContents.IndexOf(COMMENT_IDENTIFIER, PosCurrent);
		if (-1 = PosCommentStart) then begin
			// not found
			StrippingComments := false;
		end
		else begin
			PosCR := FileContents.IndexOf(EOL_CR, PosCommentStart + 1);
			PosLF := FileContents.IndexOf(EOL_LF, PosCommentStart + 1);
			const HaveCR = (-1 <> PosCR);
			const HaveLF = (-1 <> PosLF);

			if (not HaveCR) and (not HaveLF) then begin
				// no end-of-line marker remaining
				// erase from start of comment to end of file
				FileContents := FileContents.Substring(0, PosCommentStart);
				StrippingComments := false;
			end
			else begin
				// at least one end-of-line marker was found

				// were both types found
				if HaveCR and HaveLF then begin
					PosEOL := PosCR;

					if PosLF < PosEOL then begin
						PosEOL := PosLF;
					end;
				end
				else begin
					if HaveCR then begin
						// CR found
						PosEOL := PosCR;
					end
					else begin
						// LF found
						PosEOL := PosLF;
					end;
				end;

				BeforeComment := FileContents.Substring(0, PosCommentStart);
				AfterComment := FileContents.Substring(PosEOL);
				FileContents := BeforeComment + AfterComment;
				PosCurrent := BeforeComment.Length();
			end;
		end;
	end;

	exit true;
end;

//*******************************************************************************

method IniReader.BracketedSection(SectionName: String): String;
begin
	exit OPEN_BRACKET + SectionName.Trim() + CLOSE_BRACKET;
end;

//*******************************************************************************

end.