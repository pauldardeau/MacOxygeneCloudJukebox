namespace CloudJukeboxSharedProject;

interface

type
  KeyValuePairs = public class
  private
    DictKeyValues: Dictionary<String, String>;

  public
    constructor();

    method AddPair(Key: String; Value: String);
    method Clear;
    method ContainsKey(Key: String): Boolean;
    method Count():Integer;
    method GetValue(Key: String): String;
    method GetKeys(): ImmutableList<String>;
    method ShowContents;
  end;

//*****************************************************************************
//*****************************************************************************

implementation

//*****************************************************************************

constructor KeyValuePairs();
begin
  DictKeyValues := new Dictionary<String, String>;
end;

//*****************************************************************************

method KeyValuePairs.AddPair(Key: String; Value: String);
begin
  DictKeyValues.Add(Key, Value);
end;

//*****************************************************************************

method KeyValuePairs.Clear;
begin
  DictKeyValues.RemoveAll;
end;

//*****************************************************************************

method KeyValuePairs.ContainsKey(Key: String): Boolean;
begin
  result := DictKeyValues.ContainsKey(Key);
end;

//*****************************************************************************

method KeyValuePairs.Count(): Integer;
begin
  result := DictKeyValues.Count;
end;

//*****************************************************************************

method KeyValuePairs.GetValue(Key: String): String;
begin
  result := DictKeyValues[Key];
end;

//*****************************************************************************

method KeyValuePairs.GetKeys(): ImmutableList<String>;
begin
  result := DictKeyValues.Keys;
end;

//*****************************************************************************

method KeyValuePairs.ShowContents;
begin
  for each key in DictKeyValues.Keys do begin
    writeLn("key = '{0}', value = '{1}'", key, GetValue(key));
  end;
end;

end.