namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit,
  MacOxygeneCloudJukebox;

type
  TestJBUtils = public class(Test)
  private
  protected
  public
    method DecodeValue;
    method EncodeValue;
  end;

implementation

method TestJBUtils.DecodeValue;
begin
  Assert.IsTrue(true);
end;

method TestJBUtils.EncodeValue;
begin
  Assert.IsTrue(true);
end;

end.