namespace MacOxygeneCloudJukebox;

interface

type
  PropertySet = public class
  private
    MapProps: Dictionary<String, PropertyValue>;

  public
    const PROP_CONTENT_ENCODING = "Content-Encoding";
    const PROP_CONTENT_LENGTH = "Content-Length";
    const PROP_CONTENT_TYPE = "Content-Type";
    const PROP_CONTENT_MD5 = "Content-MD5";

    const valueTrue = "true";
    const valueFalse = "false";

    const typeBool = "bool";
    const typeString = "string";
    const typeInt = "int";
    const typeLong = "long";
    const typeULong = "ulong";
    const typeNull = "null";

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

method PropertySet.WriteToFile(FileName: String): Boolean;
var
  FileContents: StringBuilder;
begin
  FileContents := new StringBuilder;

  for each PropName in GetKeys() do begin
    const PV = Get(PropName);

    if PV.IsBool() then begin
      var BoolValue := "";
      if PV.GetBoolValue() then begin
        BoolValue := valueTrue;
      end
      else begin
        BoolValue := valueFalse;
      end;
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeBool, PropName, BoolValue));
    end
    else if PV.IsString() then begin
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeString, PropName, PV.GetStringValue()));
    end
    else if PV.IsInt() then begin
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeInt, PropName, PV.GetIntValue()));
    end
    else if PV.IsLong() then begin
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeLong, PropName, PV.GetLongValue()));
    end
    else if PV.IsULong() then begin
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeULong, PropName, PV.GetULongValue()));
    end
    else if PV.IsNull() then begin
      FileContents.Append(String.Format("{0}|{1}|{2}\n", typeNull, PropName, " "));
    end;
  end;

  result := Utils.FileWriteAllText(FileName, FileContents.ToString());
end;

//*******************************************************************************

method PropertySet.ReadFromFile(FileName: String): Boolean;
var
  Success: Boolean;
  IntValue: Int32;
  LongValue: Int64;
  ULongValue: Int64;
begin
  Success := false;

  const FileContents = Utils.FileReadAllText(FileName);
  if FileContents <> nil then begin
    if FileContents.Length > 0 then begin
      const FileLines = FileContents.Split("\n");
      for each FileLine in FileLines do begin
        const StrippedFileLine = FileLine.Trim();
        if StrippedFileLine.Length > 0 then begin
          const Fields = StrippedFileLine.Split("|");
          if Fields.Count = 3 then begin
            const DataType = Fields[0].Trim();
            const PropName = Fields[1].Trim();
            const PropValue = Fields[2].Trim();
            if (DataType.Length > 0) and (PropName.Length > 0) then begin
              if DataType = typeNull then begin
                Add(PropName, new PropertyValue);
              end
              else begin
                if PropValue.Length > 0 then begin
                  if DataType = typeBool then begin
                    if PropValue = valueTrue then begin
                      Add(PropName, new PropertyValue(true));
                    end
                    else if PropValue = valueFalse then begin
                      Add(PropName, new PropertyValue(false));
                    end
                    else begin
                      writeLn(String.Format("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, typeBool, PropName));
                    end;
                  end
                  else if DataType = typeString then begin
                    Add(PropName, new PropertyValue(PropValue));
                  end
                  else if DataType = typeInt then begin
                    IntValue := Convert.TryToInt32(PropValue);
                    if IntValue <> nil then begin
                      Add(PropName, new PropertyValue(IntValue));
                    end
                    else begin
                      writeLn(String.Format("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, typeInt, PropName));
                    end;
                  end
                  else if DataType = typeLong then begin
                    LongValue := Convert.TryToInt64(PropValue);
                    if LongValue <> nil then begin
                      Add(PropName, new PropertyValue(LongValue));
                    end
                    else begin
                      writeLn(String.Format("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, typeLong, PropName));
                    end;
                  end
                  else if DataType = typeULong then begin
                    ULongValue := Convert.TryToInt64(PropValue);
                    if ULongValue <> nil then begin
                      Add(PropName, new PropertyValue(ULongValue));
                    end
                    else begin
                      writeLn(String.Format("error: unrecognized value '{0}' for {1} property '{2}'", PropValue, typeULong, PropName));
                    end;
                  end
                  else begin
                    writeLn(String.Format("error: unrecognized data type '{0}' for property '{1}'", DataType, PropName));
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

end.