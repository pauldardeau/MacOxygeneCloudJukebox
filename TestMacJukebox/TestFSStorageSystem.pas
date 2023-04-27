namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestFSStorageSystem = public class(Test)
  private
  protected
  public
    method FirstTest;
  end;

implementation

method TestFSStorageSystem.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.