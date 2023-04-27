namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestPropertySet = public class(Test)
  private
  protected
  public
    method FirstTest;
  end;

implementation

method TestPropertySet.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.