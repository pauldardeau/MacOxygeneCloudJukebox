namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestStringSet = public class(Test)
  public
    method TestConstructor;
    method TestAdd;
    method TestAppend;
    method TestToString;
  end;

implementation

method TestStringSet.TestConstructor;
begin
  const ss = new StringSet;
  Assert.AreEqual(0, ss.Count);
end;

method TestStringSet.TestAdd;
begin
  const ss = new StringSet;
  ss.Add("red");
  ss.Add("green");
  ss.Add("blue");
  Assert.AreEqual(3, ss.Count);
  Assert.IsTrue(ss.Contains("red"));
  Assert.IsTrue(ss.Contains("green"));
  Assert.IsTrue(ss.Contains("blue"));
  const ssValues = ss.GetValues;
  Assert.IsTrue(ssValues <> nil);
  Assert.AreEqual(3, ssValues.Count);
  Assert.IsTrue(ssValues.Contains("red"));
  Assert.IsTrue(ssValues.Contains("green"));
  Assert.IsTrue(ssValues.Contains("blue"));

  ss.Clear;
  Assert.AreEqual(0, ss.Count);
  Assert.IsFalse(ss.Contains("red"));
  Assert.IsFalse(ss.Contains("green"));
  Assert.IsFalse(ss.Contains("blue"));
  const ssEmptyValues = ss.GetValues;
  Assert.IsTrue(ssEmptyValues <> nil);
  Assert.AreEqual(0, ssEmptyValues.Count);
end;

method TestStringSet.TestAppend;
begin
  const trees = new StringSet;
  trees.Add("oak");
  trees.Add("elm");
  trees.Add("maple");
  trees.Add("hickory");
  const treeCountBeforeAppend = trees.Count;

  const birds = new StringSet;
  birds.Add("cardinal");
  birds.Add("purple martin");
  birds.Add("house wren");
  birds.Add("hummingbird");
  birds.Add("parakeet");

  trees.Append(birds);
  Assert.AreEqual(treeCountBeforeAppend + birds.Count, trees.Count);
end;

method TestStringSet.TestToString;
begin
  const tools = new StringSet;
  tools.Add("hammer");
  tools.Add("chisel");
  tools.Add("saw");
  const toolsText = tools.ToString;
  Assert.IsTrue(toolsText.Contains("hammer"));
  Assert.IsTrue(toolsText.Contains("chisel"));
  Assert.IsTrue(toolsText.Contains("saw"));
end;

end.