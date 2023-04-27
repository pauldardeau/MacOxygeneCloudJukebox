namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestKeyValuePairs = public class(Test)
  public
    method TestConstructor;
    method TestWithValues;
  end;

implementation

method TestKeyValuePairs.TestConstructor;
begin
  const kvp = new KeyValuePairs;
  Assert.AreEqual(0, kvp.Count);
  Assert.IsFalse(kvp.ContainsKey("foo"));
  const listKeys = kvp.GetKeys;
  Assert.AreEqual(0, listKeys.Count);
end;

method TestKeyValuePairs.TestWithValues;
begin
  const kvp = new KeyValuePairs;
  kvp.AddPair("stooge1", "Moe");
  kvp.AddPair("stooge2", "Larry");
  kvp.AddPair("stooge3", "Curly");
  Assert.AreEqual(3, kvp.Count);
  Assert.AreEqual("Moe", kvp.GetValue("stooge1"));
  Assert.AreEqual("Larry", kvp.GetValue("stooge2"));
  Assert.AreEqual("Curly", kvp.GetValue("stooge3"));
  const listKeys = kvp.GetKeys;
  Assert.IsTrue(listKeys.Contains("stooge1"));
  Assert.IsTrue(listKeys.Contains("stooge2"));
  Assert.IsTrue(listKeys.Contains("stooge3"));

  kvp.Clear;
  Assert.AreEqual(0, kvp.Count);
  const listEmptyKeys = kvp.GetKeys;
  Assert.AreEqual(0, listEmptyKeys.Count);
end;

end.