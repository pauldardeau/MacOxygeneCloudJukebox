namespace CloudJukeboxSharedProject;

interface

type
  PropertyValue = public class
  private
    DataType: String;
    IntValue: Integer;
    LongValue: Int64;
    ULongValue: UInt64;
    BoolValue: Boolean;
    StringValue: String;
    DoubleValue: Real;

  public
    const TYPE_INT = "Int";
    const TYPE_LONG = "Long";
    const TYPE_ULONG = "ULong";
    const TYPE_BOOL = "Bool";
    const TYPE_STRING = "String";
    const TYPE_DOUBLE = "Double";
    const TYPE_NULL = "Null";

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
  DataType := TYPE_INT;
  IntValue := aIntValue;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
end;

//*******************************************************************************

constructor PropertyValue(aLongValue: Int64);
begin
  DataType := TYPE_LONG;
  IntValue := 0;
  LongValue := aLongValue;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
end;

//*******************************************************************************

constructor PropertyValue(aULongValue: UInt64);
begin
  DataType := TYPE_ULONG;
  IntValue := 0;
  LongValue := 0;
  ULongValue := aULongValue;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
end;

//*******************************************************************************

constructor PropertyValue(aBoolValue: Boolean);
begin
  DataType := TYPE_BOOL;
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := aBoolValue;
  StringValue := "";
  DoubleValue := 0.0;
end;

//*******************************************************************************

constructor PropertyValue(aStringValue: String);
begin
  DataType := TYPE_STRING;
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := aStringValue;
  DoubleValue := 0.0;
end;

//*******************************************************************************

constructor PropertyValue(aDoubleValue: Real);
begin
  DataType := TYPE_DOUBLE;
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := aDoubleValue;
end;

//*******************************************************************************

constructor PropertyValue();
begin
  DataType := TYPE_NULL;
  IntValue := 0;
  LongValue := 0;
  ULongValue := 0;
  BoolValue := false;
  StringValue := "";
  DoubleValue := 0.0;
end;

//*******************************************************************************

method PropertyValue.IsInt(): Boolean;
begin
  result := DataType = TYPE_INT;
end;

//*******************************************************************************

method PropertyValue.IsLong(): Boolean;
begin
  result := DataType = TYPE_LONG;
end;

//*******************************************************************************

method PropertyValue.IsULong(): Boolean;
begin
  result := DataType = TYPE_ULONG;
end;

//*******************************************************************************

method PropertyValue.IsBool(): Boolean;
begin
  result := DataType = TYPE_BOOL;
end;

//*******************************************************************************

method PropertyValue.IsString(): Boolean;
begin
  result := DataType = TYPE_STRING;
end;

//*******************************************************************************

method PropertyValue.IsDouble(): Boolean;
begin
  result := DataType = TYPE_DOUBLE;
end;

//*******************************************************************************

method PropertyValue.IsNull(): Boolean;
begin
  result := DataType = TYPE_NULL;
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