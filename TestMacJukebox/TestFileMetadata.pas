namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestFileMetadata = public class(Test)
  private
  protected
  public
    method FirstTest;
  end;

implementation

method TestFileMetadata.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.