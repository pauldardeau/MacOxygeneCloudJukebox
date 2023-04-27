namespace TestMacJukebox;

interface

uses
  RemObjects.Elements.EUnit, CloudJukeboxSharedProject;

type
  TestPropertyValue = public class(Test)
  private
  protected
  public
    method ConstructWithBool;
    method ConstructWithInt;
    method ConstructWithLong;
    method ConstructWithULong;
    method ConstructWithString;
    method ConstructWithDouble;
    method ConstructWithNull;
  end;

implementation

method TestPropertyValue.ConstructWithBool;
begin
  const pv = new PropertyValue(true);
  Assert.IsTrue(pv.IsBool);
  Assert.IsTrue(pv.GetBoolValue);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsULong);
end;

method TestPropertyValue.ConstructWithInt;
begin
  const IntValue = 17;
  const pv = new PropertyValue(IntValue);
  Assert.IsTrue(pv.IsInt);
  Assert.AreEqual(IntValue, pv.GetIntValue);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsBool);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsULong);
end;

method TestPropertyValue.ConstructWithLong;
begin
  const LongValue: Int64 = 384234;
  const pv = new PropertyValue(LongValue);
  Assert.IsTrue(pv.IsLong);
  Assert.AreEqual(LongValue, pv.GetLongValue);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsBool);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsULong);
end;

method TestPropertyValue.ConstructWithULong;
begin
  const ULongValue: UInt64 = 98462;
  const pv = new PropertyValue(ULongValue);
  Assert.IsTrue(pv.IsULong);
  Assert.AreEqual(ULongValue, pv.GetULongValue);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsBool);
end;

method TestPropertyValue.ConstructWithString;
begin
  const StringValue = "Testing is fun";
  const pv = new PropertyValue(StringValue);
  Assert.IsTrue(pv.IsString);
  Assert.AreEqual(StringValue, pv.GetStringValue);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsBool);
  Assert.IsFalse(pv.IsULong);
end;

method TestPropertyValue.ConstructWithDouble;
begin
  const DoubleValue = 3.14;
  const pv = new PropertyValue(DoubleValue);
  Assert.IsTrue(pv.IsDouble);
  Assert.AreEqual(DoubleValue, pv.GetDoubleValue);

  Assert.IsFalse(pv.IsBool);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsNull);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsULong);
end;

method TestPropertyValue.ConstructWithNull;
begin
  const pv = new PropertyValue;
  Assert.IsTrue(pv.IsNull);

  Assert.IsFalse(pv.IsDouble);
  Assert.IsFalse(pv.IsInt);
  Assert.IsFalse(pv.IsLong);
  Assert.IsFalse(pv.IsBool);
  Assert.IsFalse(pv.IsString);
  Assert.IsFalse(pv.IsULong);
end;

end.