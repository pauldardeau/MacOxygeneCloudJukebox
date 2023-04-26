namespace TestCloudJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestJBUtils = public class(Test)
  private
  protected
  public
    method TestDecodeValue;
    method TestEncodeValue;
  end;

implementation

method TestJBUtils.TestDecodeValue;
begin
  Assert.IsTrue(true);
end;

method TestJBUtils.TestEncodeValue;
begin
  Assert.IsTrue(true);
end;

end.