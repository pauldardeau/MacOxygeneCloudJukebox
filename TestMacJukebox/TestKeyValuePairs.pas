namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestKeyValuePairs = public class(Test)
  private
  protected
  public
    method FirstTest;
  end;

implementation

method TestKeyValuePairs.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.