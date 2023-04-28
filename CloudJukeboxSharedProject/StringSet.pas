namespace CloudJukeboxSharedProject;

interface

type
  StringSet = public class
  private
    MapStrings: Dictionary<String, Boolean>;

  public
    constructor();

    method Add(Value: String);
    method Clear;
    method Contains(Value: String): Boolean;
    method GetValues(): ImmutableList<String>;
    method Count(): Integer;
    method Append(aSet: StringSet);
    method ToString(): String;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor StringSet;
begin
  MapStrings := new Dictionary<String, Boolean>;
end;

//*******************************************************************************

method StringSet.Add(Value: String);
begin
  MapStrings.Add(Value, true);
end;

//*******************************************************************************

method StringSet.Clear;
begin
  MapStrings.RemoveAll;
end;

//*******************************************************************************

method StringSet.Contains(Value: String): Boolean;
begin
  exit MapStrings.ContainsKey(Value);
end;

//*******************************************************************************

method StringSet.GetValues(): ImmutableList<String>;
begin
  exit MapStrings.Keys;
end;

//*******************************************************************************

method StringSet.Count(): Integer;
begin
  exit MapStrings.Count;
end;

//*******************************************************************************

method StringSet.Append(aSet: StringSet);
begin
  for each Value in aSet.GetValues() do begin
    MapStrings.Add(Value, true);
  end;
end;

//*******************************************************************************

method StringSet.ToString(): String;
begin
  const sb = new StringBuilder;
  for each Value in MapStrings.Keys do begin
    if sb.Length > 0 then begin
      sb.Append(", ");
    end;
    sb.Append(Value);
  end;
  exit sb.ToString;
end;

//*******************************************************************************

end.