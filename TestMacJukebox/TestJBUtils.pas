namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestJBUtils = public class(Test)
  public
    method TestDecodeValue;
    method TestEncodeValue;
    method TestEncodeArtistAlbum;
    method TestEncodeArtistAlbumSong;
    method TestRemovePunctuation;
    method TestComponentsFromFileName;
    method TestArtistFromFileName;
    method TestAlbumFromFileName;
    method TestSongFromFileName;
  end;

implementation

//*******************************************************************************

method TestJBUtils.TestDecodeValue;
begin
  const EncodedValue = "I-Put-a-Spell-on-You.flac";
  const DecodedValue = JBUtils.DecodeValue(EncodedValue);
  Assert.AreEqual(DecodedValue, "I Put a Spell on You.flac");
end;

//*******************************************************************************

method TestJBUtils.TestEncodeValue;
begin
  const DecodedValue = "I Put a Spell on You.flac";
  const EncodedValue = JBUtils.EncodeValue(DecodedValue);
  Assert.AreEqual(EncodedValue, "I-Put-a-Spell-on-You.flac");
end;

//*******************************************************************************

method TestJBUtils.TestEncodeArtistAlbum;
begin
  var Artist := "The Who";
  var Album := "Who's Next";
  var EncodedValue := JBUtils.EncodeArtistAlbum(Artist, Album);
  Assert.AreEqual(EncodedValue, "The-Who--Whos-Next");
end;

//*******************************************************************************

method TestJBUtils.TestEncodeArtistAlbumSong;
begin
  var Artist := "The Who";
  var Album := "Who's Next";
  var Song := "My Wife";
  var EncodedValue := JBUtils.EncodeArtistAlbumSong(Artist, Album, Song);
  Assert.AreEqual(EncodedValue, "The-Who--Whos-Next--My-Wife");
end;

//*******************************************************************************

method TestJBUtils.TestRemovePunctuation;
begin
  var HasPunctuation := "How Soon Is Now?";
  var NoPunctuation := JBUtils.RemovePunctuation(HasPunctuation);
  Assert.AreEqual(NoPunctuation, "How Soon Is Now");

  HasPunctuation := "Eureka!";
  NoPunctuation := JBUtils.RemovePunctuation(HasPunctuation);
  Assert.AreEqual(NoPunctuation, "Eureka");

  HasPunctuation := "Wherever you go, there you are!";
  NoPunctuation := JBUtils.RemovePunctuation(HasPunctuation);
  Assert.AreEqual(NoPunctuation, "Wherever you go there you are");

  HasPunctuation := "Derek & The Dominos";
  NoPunctuation := JBUtils.RemovePunctuation(HasPunctuation);
  Assert.AreEqual(NoPunctuation, "Derek The Dominos");
end;

//*******************************************************************************

method TestJBUtils.TestComponentsFromFileName;
begin
  var Artist := "";
  var Album := "";
  var Song := "";

  (Artist, Album, Song) := JBUtils.ComponentsFromFileName("");
  Assert.AreEqual("", Artist);
  Assert.AreEqual("", Album);
  Assert.AreEqual("", Song);

  (Artist, Album, Song) := JBUtils.ComponentsFromFileName("Steely-Dan--Aja--Black-Cow");
  Assert.AreEqual("Steely Dan", Artist);
  Assert.AreEqual("Aja", Album);
  Assert.AreEqual("Black Cow", Song);
end;

//*******************************************************************************

method TestJBUtils.TestArtistFromFileName;
begin
  var Artist := "";

  Artist := JBUtils.ArtistFromFileName("");
  Assert.AreEqual("", Artist);

  Artist := JBUtils.ArtistFromFileName("Steely-Dan--Aja--Black-Cow");
  Assert.AreEqual("Steely Dan", Artist);
end;

//*******************************************************************************

method TestJBUtils.TestAlbumFromFileName;
begin
  var Album := "";

  Album := JBUtils.AlbumFromFileName("");
  Assert.AreEqual("", Album);

  Album := JBUtils.AlbumFromFileName("Steely-Dan--Aja--Black-Cow");
  Assert.AreEqual("Aja", Album);
end;

//*******************************************************************************

method TestJBUtils.TestSongFromFileName;
begin
  var Song := "";

  Song := JBUtils.SongFromFileName("");
  Assert.AreEqual("", Song);

  Song := JBUtils.SongFromFileName("Steely-Dan--Aja--Black-Cow");
  Assert.AreEqual("Black Cow", Song);
end;

//*******************************************************************************

end.