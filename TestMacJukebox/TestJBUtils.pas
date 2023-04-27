namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestJBUtils = public class(Test)
  private
  protected
  public
    method TestDecodeValue;
    method TestEncodeValue;
    method TestEncodeArtistAlbum;
    method TestEncodeArtistAlbumSong;
    method TestRemovePunctuation;
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
end;

//*******************************************************************************

end.