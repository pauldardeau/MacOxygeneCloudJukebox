namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestIniReader = public class(Test)
  private
  protected
  public
    method Test;
  end;

implementation

method TestIniReader.Test;
begin
  const EOL = Environment.LineBreak;
  const FileName = "MyFile.ini";
  const IniContents =
  "[Windows]" + EOL +
  "image_editor_exe = MSPaint.exe" + EOL +
  "audio_player_exe = Winamp.exe" + EOL +
  "browser_exe = Firefox.exe" + EOL +
  EOL +
  "[Mac]" + EOL +
  "image_editor_exe = PhotoShop.app" + EOL +
  "audio_player_exe = afplay" + EOL +
  "browser_exe = Safari.app" + EOL +
  EOL +
  "[Linux]" + EOL +
  "image_editor_exe = gimp" + EOL +
  "audio_player_exe = mplayer" + EOL +
  "browser_exe = chrome" + EOL +
  EOL;


  const ExistingSection = "Mac";
  const MissingSection = "BeOS";
  const ExistingKey = "audio_player_exe";
  const MissingKey = "unicorn_player_exe";

  var Reader := new IniReader(FileName, IniContents);

  // BracketedSection
  var BracketedName := Reader.BracketedSection("Foo");
  Assert.AreEqual(BracketedName, "[Foo]");

  // HasSection
  Assert.IsTrue(Reader.HasSection(ExistingSection));
  Assert.IsTrue(Reader.HasSection("Windows"));
  Assert.IsTrue(Reader.HasSection("Linux"));
  Assert.IsFalse(Reader.HasSection(MissingSection));

  // ReadSection
  var kvp := new KeyValuePairs;
  var ReadSuccess := Reader.ReadSection(ExistingSection, var kvp);
  Assert.IsTrue(ReadSuccess);
  Assert.AreEqual(kvp.GetValue("audio_player_exe"), "afplay");
  Assert.IsTrue(kvp.Count = 3);
  Assert.IsTrue(kvp.ContainsKey("image_editor_exe"));
  Assert.IsTrue(kvp.ContainsKey("browser_exe"));

  ReadSuccess := Reader.ReadSection(MissingSection, var kvp);
  Assert.IsFalse(ReadSuccess);

  // GetSectionKeyValue
  var ConfigValue := "";
  var GetSuccess := Reader.GetSectionKeyValue(ExistingSection, ExistingKey, out ConfigValue);
  Assert.IsTrue(GetSuccess);
  Assert.AreEqual(ConfigValue, "afplay");

  ConfigValue := "";
  GetSuccess := Reader.GetSectionKeyValue(ExistingSection, MissingKey, out ConfigValue);
  Assert.IsFalse(GetSuccess);
  Assert.AreEqual(ConfigValue, "");

  ConfigValue := "";
  GetSuccess := Reader.GetSectionKeyValue(MissingSection, MissingKey, out ConfigValue);
  Assert.IsFalse(GetSuccess);
  Assert.AreEqual(ConfigValue, "");
end;

end.