namespace MacOxygeneCloudJukebox;

interface

type
  PropertyValue = public class
  public
    DataType: String;
    IntValue: Integer;
    LongValue: Int64;
    ULongValue: UInt64;
    BoolValue: Boolean;
    StringValue: String;
    DoubleValue: Real;
    IsNullValue: Boolean;

    constructor(aIntValue: Integer);
    constructor(aLongValue: Int64);
    constructor(aULongValue: UInt64);
    constructor(aBoolValue: Boolean);
    constructor(aStringValue: String);
    constructor(aDoubleValue: Real);
    constructor();

    method IsInt(): Boolean;
    method IsLong(): Boolean;
    method IsULong(): Boolean;
    method IsBool(): Boolean;
    method IsString(): Boolean;
    method IsDouble(): Boolean;
    method IsNull(): Boolean;

    method GetIntValue(): Integer;
    method GetLongValue(): Int64;
    method GetULongValue(): UInt64;
    method GetBoolValue(): Boolean;
    method GetStringValue(): String;
    method GetDoubleValue(): Real;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor PropertyValue(aIntValue: Integer);
begin
  DataType := "Int";
  IntValue := aIntValue;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue(aLongValue: Int64);
begin
  DataType := "Long";
  IntValue := 0;
  LongValue := aLongValue;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue(aULongValue: UInt64);
begin
  DataType := "ULong";
  IntValue := 0;
  LongValue := 0;
  ULongValue := aULongValue;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue(aBoolValue: Boolean);
begin
  DataType := "Bool";
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := aBoolValue;
  StringValue := "";
  DoubleValue := 0.0;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue(aStringValue: String);
begin
  DataType := "String";
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := aStringValue;
  DoubleValue := 0.0;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue(aDoubleValue: Real);
begin
  DataType := "Double";
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := aDoubleValue;
  IsNullValue := false;
end;

//*******************************************************************************

constructor PropertyValue();
begin
  DataType := "Null";
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
  IsNullValue := true;
end;

//*******************************************************************************

method PropertyValue.IsInt(): Boolean;
begin
  result := DataType = "Int";
end;

//*******************************************************************************

method PropertyValue.IsLong(): Boolean;
begin
  result := DataType = "Long";
end;

//*******************************************************************************

method PropertyValue.IsULong(): Boolean;
begin
  result := DataType = "ULong";
end;

//*******************************************************************************

method PropertyValue.IsBool(): Boolean;
begin
  result := DataType = "Bool";
end;

//*******************************************************************************

method PropertyValue.IsString(): Boolean;
begin
  result := DataType = "String";
end;

//*******************************************************************************

method PropertyValue.IsDouble(): Boolean;
begin
  result := DataType = "Double";
end;

//*******************************************************************************

method PropertyValue.IsNull(): Boolean;
begin
  result := DataType = "Null";
end;

//*******************************************************************************

method PropertyValue.GetIntValue(): Integer;
begin
  result := IntValue;
end;

//*******************************************************************************

method PropertyValue.GetLongValue(): Int64;
begin
  result := LongValue;
end;

//*******************************************************************************

method PropertyValue.GetULongValue(): UInt64;
begin
  result := ULongValue;
end;

//*******************************************************************************

method PropertyValue.GetBoolValue(): Boolean;
begin
  result := BoolValue;
end;

//*******************************************************************************

method PropertyValue.GetStringValue(): String;
begin
  result := StringValue;
end;

//*******************************************************************************

method PropertyValue.GetDoubleValue(): Real;
begin
  result := DoubleValue;
end;

//*******************************************************************************

end.