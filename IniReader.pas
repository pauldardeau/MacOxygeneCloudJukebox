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
    method ReadSection(Section: String; SectionValues: KeyValuePairs): Boolean;
    method GetSectionKeyValue(Section: String;
                              Key: String;
                              out Value: String): Boolean;
    method HasSection(Section: String): Boolean;

  protected
    method ReadFile(): Boolean;
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
                             SectionValues: KeyValuePairs): Boolean;
var
  SectionContents: String;
  PosEOL: Integer;
  Line: String;
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
    SectionContents := FileContents.substr(PosEndSection,
                                           StartNextSection - PosEndSection);
  end
  else begin 
    // no, this is the last section -- read everything left in
    // the file
    SectionContents := FileContents.Substring(PosEndSection);
  end;
    
  var Index := 0;
    
  // process each line of the section
  while (PosEol := SectionContents.IndexOf(EOL_LF, Index)) <> -1 do begin
      
    Line := SectionContents.Substring(Index, PosEol - Index);
    if Line.Length() = 0 then begin 
      const PosCR = Line.IndexOf(EOL_CR);
      if PosCR <> -1 then begin
        Line := Line.Substring(0, PosCR);
      end;
            
      const PosEqual = Line.IndexOf('=');
            
      if (PosEqual <> -1) and (PosEqual < Line.Length()) then begin
        const Key = Line.Substring(0, PosEqual).Strip();
                
        // if the line is not a comment
        if not Key.StartsWith(COMMENT_IDENTIFIER) then begin
          SectionValues.AddPair(Key,
                                Line.Substring(PosEqual + 1).Strip());
        end;
      end;
    end;
        
    Index := PosEol + 1;
  end;
    
  exit true;
end;

//*******************************************************************************

method IniReader.GetSectionKeyValue(Section: String;
                                    Key: String;
                                    out Value: String): Boolean;
begin
  var Map := new KeyValuePairs;
    
  if not ReadSection(Section, Map) then begin 
    writeLn('IniReader ReadSection returned false');
    exit false;
  end;
    
  const StrippedKey = Key.Strip();
    
  if not Map.HasKey(StrippedKey) then begin
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
  FileContents := Utils.FileReadAllText(IniFileName);
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
  exit OPEN_BRACKET + SectionName.Strip() + CLOSE_BRACKET;
end;

//*******************************************************************************

end;

//*******************************************************************************

end.

