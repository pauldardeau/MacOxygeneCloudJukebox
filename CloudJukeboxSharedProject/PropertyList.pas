﻿namespace CloudJukeboxSharedProject;

interface

type
  PropertyList = public class
  public
    ListProps: List<PropertyValue>;

    constructor();

    method Append(PropValue: PropertyValue);
    method Clear;
    method Get(aIndex: Integer): PropertyValue;
    method GetIntValue(aIndex: Integer): Integer;
    method GetLongValue(aIndex: Integer): Int64;
    method GetULongValue(aIndex: Integer): UInt64;
    method GetBoolValue(aIndex: Integer): Boolean;
    method GetStringValue(aIndex: Integer): String;
    method GetDoubleValue(aIndex: Integer): Real;
    method Count():Integer;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor PropertyList();
begin
  ListProps := new List<PropertyValue>();
end;

//*******************************************************************************

method PropertyList.Append(PropValue: PropertyValue);
begin
  ListProps.Add(PropValue);
end;

//*******************************************************************************

method PropertyList.Clear;
begin
  ListProps.RemoveAll;
end;

//*******************************************************************************

method PropertyList.Get(aIndex: Integer): PropertyValue;
begin
  result := ListProps.Item[aIndex];
end;

//*******************************************************************************

method PropertyList.GetIntValue(aIndex: Integer): Integer;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetIntValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertyList.GetLongValue(aIndex: Integer): Int64;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetLongValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertyList.GetULongValue(aIndex: Integer): UInt64;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetULongValue
  else
    result := 0;
end;

//*******************************************************************************

method PropertyList.GetBoolValue(aIndex: Integer): Boolean;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetBoolValue
  else
    result := false;
end;

//*******************************************************************************

method PropertyList.GetStringValue(aIndex: Integer): String;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetStringValue
  else
    result := "";
end;

//*******************************************************************************

method PropertyList.GetDoubleValue(aIndex: Integer): Real;
begin
  var pv := Get(aIndex);
  if pv <> nil then
    result := pv.GetDoubleValue
  else
    result := 0.0;
end;

//*******************************************************************************

method PropertyList.Count():Integer;
begin
  result := ListProps.Count;
end;

//*******************************************************************************

end.