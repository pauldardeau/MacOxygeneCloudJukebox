namespace CloudJukeboxSharedProject;

interface

type
  PropertySet = public class
  private
    MapProps: Dictionary<String, PropertyValue>;

  public
    const VALUE_TRUE = "true";
    const VALUE_FALSE = "false";

    const TYPE_BOOL = "bool";
    const TYPE_STRING = "string";
    const TYPE_INT = "int";
    const TYPE_LONG = "long";
    const TYPE_ULONG = "ulong";
    const TYPE_DOUBLE = "double";
    const TYPE_NULL = "null";

    constructor();

    method Add(PropName: String; PropValue: PropertyValue);
    method Clear;
    method Contains(PropName: String): Boolean;
    method GetKeys(): ImmutableList<String>;
    method Get(PropName: String): PropertyValue;
    method GetIntValue(PropName: String): Integer;
    method GetLongValue(PropName: String): Int64;
    method GetULongValue(PropName: String): UInt64;
    method GetBoolValue(PropName: String): Boolean;
    method GetStringValue(PropName: String): String;
    method GetDoubleValue(PropName: String): Real;
    method Count():Integer;
    method ToString: String;
    method PopulateFromString(EncodedPropertySet: String): Boolean;
    method WriteToFile(FileName: String): Boolean;
    method ReadFromFile(FileName: String): Boolean;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor PropertySet;
begin
  MapProps := new Dictionary<String, PropertyValue>;
end;

//*******************************************************************************

method PropertySet.Add(PropName: String; PropValue: PropertyValue);
begin
  MapProps.Add(PropName, PropValue);
end;

//*******************************************************************************

method PropertySet.Clear;
begin
  MapProps.RemoveAll;
end;

//*******************************************************************************

method PropertySet.Contains(PropName: String): Boolean;
begin
  result := MapProps.ContainsKey(PropName);
end;

//*******************************************************************************

method PropertySet.GetKeys(): ImmutableList<String>;
begin
  result := MapProps.Keys;
end;

//*******************************************************************************

method PropertySet.Get(PropName: String): PropertyValue;
begin
  result := MapProps.Item[PropName];
end;

//*******************************************************************************

method PropertySet.GetIntValue(PropName: String): Integer;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetIntValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertySet.GetLongValue(PropName: String): Int64;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetLongValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertySet.GetULongValue(PropName: String): UInt64;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetULongValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertySet.GetBoolValue(PropName: String): Boolean;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetBoolValue
  else
    result := false;
end;

//*******************************************************************************

method PropertySet.GetStringValue(PropName: String): String;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetStringValue
  else
    result := "";
end;

//*******************************************************************************

method PropertySet.GetDoubleValue(PropName: String): Real;
begin
  var pv := Get(PropName);
  if pv <> nil then
    result := pv.GetDoubleValue
  else
    result := 0.0;
end;

//*******************************************************************************

method PropertySet.Count():Integer;
begin
  result := MapProps.Count;
end;

//*******************************************************************************

method PropertySet.ToString: String;
begin
  var Encoded := new StringBuilder;
  const nl = Environment.LineBreak;

  for each PropName in GetKeys() do begin
    const PV = Get(PropName);

    if PV.IsBool() then begin
      var BoolValue := "";
      if PV.GetBoolValue() then begin
        BoolValue := VALUE_TRUE;
      end
      else begin
        BoolValue := VALUE_FALSE;
      end;
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_BOOL, PropName, BoolValue));
    end
    else if PV.IsString() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_STRING, PropName, PV.GetStringValue()));
    end
    else if PV.IsInt() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_INT, PropName, PV.GetIntValue()));
    end
    else if PV.IsLong() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_LONG, PropName, PV.GetLongValue()));
    end
    else if PV.IsULong() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_ULONG, PropName, PV.GetULongValue()));
    end
    else if PV.IsDouble() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_DOUBLE, PropName, PV.GetDoubleValue()));
    end
    else if PV.IsNull() then begin
      Encoded.Append(String.Format("{0}|{1}|{2}" + nl, TYPE_NULL, PropName, " "));
    end;
  end;

  result := Encoded.ToString;
end;

//*******************************************************************************

method PropertySet.WriteToFile(FileName: String): Boolean;
begin
  result := Utils.FileWriteAllText(FileName, ToString());
end;

//*******************************************************************************

method PropertySet.PopulateFromString(EncodedPropertySet: String): Boolean;
var
  Success: Boolean;
  IntValue: Int32;
  LongValue: Int64;
  ULongValue: Int64;
  DoubleValue: Real;
begin
  Success := false;

  if EncodedPropertySet <> nil then begin
    if EncodedPropertySet.Length > 0 then begin
      const FileLines = EncodedPropertySet.Split(Environment.LineBreak);
      for each FileLine in FileLines do begin
        const StrippedFileLine = FileLine.Trim();
        if StrippedFileLine.Length > 0 then begin
          const Fields = StrippedFileLine.Split("|");
          if Fields.Count = 3 then begin
            const DataType = Fields[0].Trim();
            const PropName = Fields[1].Trim();
            const PropValue = Fields[2].Trim();
            if (DataType.Length > 0) and (PropName.Length > 0) then begin
              if DataType = TYPE_NULL then begin
                Add(PropName, new PropertyValue);
              end
              else begin
                if PropValue.Length > 0 then begin
                  if DataType = TYPE_BOOL then begin
                    if PropValue = VALUE_TRUE then begin
                      Add(PropName, new PropertyValue(true));
                    end
                    else if PropValue = VALUE_FALSE then begin
                      Add(PropName, new PropertyValue(false));
                    end
                    else begin
                      writeLn("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, TYPE_BOOL, PropName);
                    end;
                  end
                  else if DataType = TYPE_STRING then begin
                    Add(PropName, new PropertyValue(PropValue));
                  end
                  else if DataType = TYPE_INT then begin
                    IntValue := Convert.TryToInt32(PropValue);
                    if IntValue <> nil then begin
                      Add(PropName, new PropertyValue(IntValue));
                    end
                    else begin
                      writeLn("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, TYPE_INT, PropName);
                    end;
                  end
                  else if DataType = TYPE_LONG then begin
                    LongValue := Convert.TryToInt64(PropValue);
                    if LongValue <> nil then begin
                      Add(PropName, new PropertyValue(LongValue));
                    end
                    else begin
                      writeLn("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, TYPE_LONG, PropName);
                    end;
                  end
                  else if DataType = TYPE_ULONG then begin
                    ULongValue := Convert.TryToInt64(PropValue);
                    if ULongValue <> nil then begin
                      Add(PropName, new PropertyValue(ULongValue));
                    end
                    else begin
                      writeLn("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, TYPE_ULONG, PropName);
                    end;
                  end
                  else if DataType = TYPE_DOUBLE then begin
                    DoubleValue := Convert.TryToDouble(PropValue);
                    if DoubleValue <> nil then begin
                      Add(PropName, new PropertyValue(DoubleValue));
                    end
                    else begin
                      writeLn("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, TYPE_ULONG, PropName);
                    end;
                  end
                  else begin
                    writeLn("error: unrecognized data type '{0}' for property '{1}'", DataType, PropName);
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  result := Success;
end;

//*******************************************************************************

method PropertySet.ReadFromFile(FileName: String): Boolean;
begin
  result := PopulateFromString(Utils.FileReadAllText(FileName));
end;

//*******************************************************************************

end.