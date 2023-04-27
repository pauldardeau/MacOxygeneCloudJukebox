namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestFSStorageSystem = public class(Test)
  public
    method FirstTest;
  end;

implementation

method TestFSStorageSystem.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.