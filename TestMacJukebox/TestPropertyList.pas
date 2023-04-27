namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestPropertyList = public class(Test)
  public
    method TestConstructor;
    method TestWithNull;
    method TestWithInt;
    method TestWithLong;
    method TestWithULong;
    method TestWithBool;
    method TestWithString;
    method TestWithDouble;
    method TestMultipleWithClear;
  end;

implementation

method TestPropertyList.TestConstructor;
begin
  const pl = new PropertyList;
  Assert.AreEqual(0, pl.Count);
end;

method TestPropertyList.TestWithNull;
begin
  const pl = new PropertyList;
  pl.Append(new PropertyValue);
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsNull);
end;

method TestPropertyList.TestWithInt;
begin
  const pl = new PropertyList;
  const IntValue = 21;
  pl.Append(new PropertyValue(IntValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsInt);
  Assert.AreEqual(IntValue, pv.GetIntValue);
end;

method TestPropertyList.TestWithLong;
begin
  const pl = new PropertyList;
  const LongValue: Int64 = 37;
  pl.Append(new PropertyValue(LongValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsLong);
  Assert.AreEqual(LongValue, pv.GetLongValue);
end;

method TestPropertyList.TestWithULong;
begin
  const pl = new PropertyList;
  const ULongValue: UInt64 = 95;
  pl.Append(new PropertyValue(ULongValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsULong);
  Assert.AreEqual(ULongValue, pv.GetULongValue);
end;

method TestPropertyList.TestWithBool;
begin
  const pl = new PropertyList;
  const BoolValue = true;
  pl.Append(new PropertyValue(BoolValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsBool);
  Assert.AreEqual(BoolValue, pv.GetBoolValue);
end;

method TestPropertyList.TestWithString;
begin
  const pl = new PropertyList;
  const StringValue = "This is part of PropertyList testing";
  pl.Append(new PropertyValue(StringValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsString);
  Assert.AreEqual(StringValue, pv.GetStringValue);
end;

method TestPropertyList.TestWithDouble;
begin
  const pl = new PropertyList;
  const DoubleValue = 72.584;
  pl.Append(new PropertyValue(DoubleValue));
  const pv = pl.Get(0);
  Assert.IsTrue(pv.IsDouble);
  Assert.AreEqual(DoubleValue, pv.GetDoubleValue);
end;

method TestPropertyList.TestMultipleWithClear;
begin
  const pl = new PropertyList;
  const BoolValue = false;
  const IntValue = 5;
  const LongValue: Int64 = 31;
  const ULongValue: UInt64 = 67;
  const StringValue = "This test has multiple properties";
  const DoubleValue = 35.7294;
  pl.Append(new PropertyValue(BoolValue));
  pl.Append(new PropertyValue(IntValue));
  pl.Append(new PropertyValue(LongValue));
  pl.Append(new PropertyValue(ULongValue));
  pl.Append(new PropertyValue(StringValue));
  pl.Append(new PropertyValue(DoubleValue));
  Assert.AreEqual(6, pl.Count);

  var pv := pl.Get(0);
  Assert.IsTrue(pv.IsBool);
  Assert.AreEqual(BoolValue, pv.GetBoolValue);

  pv := pl.Get(1);
  Assert.IsTrue(pv.IsInt);
  Assert.AreEqual(IntValue, pv.GetIntValue);

  pv := pl.Get(2);
  Assert.IsTrue(pv.IsLong);
  Assert.AreEqual(LongValue, pv.GetLongValue);

  pv := pl.Get(3);
  Assert.IsTrue(pv.IsULong);
  Assert.AreEqual(ULongValue, pv.GetULongValue);

  pv := pl.Get(4);
  Assert.IsTrue(pv.IsString);
  Assert.AreEqual(StringValue, pv.GetStringValue);

  pv := pl.Get(5);
  Assert.IsTrue(pv.IsDouble);
  Assert.AreEqual(DoubleValue, pv.GetDoubleValue);

  pl.Clear;

  Assert.AreEqual(0, pl.Count);

  pl.Append(new PropertyValue(5));
  pl.Append(new PropertyValue("foo"));
  Assert.AreEqual(2, pl.Count);
end;

end.