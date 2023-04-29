namespace CloudJukeboxSharedProject;

interface

type
  ArgumentParser = public class
  private
    DictAllReservedWords: Dictionary<String, String>;
    DictBoolOptions: Dictionary<String, String>;
    DictIntOptions: Dictionary<String, String>;
    DictStringOptions: Dictionary<String, String>;
    DictCommands: Dictionary<String, String>;
    ListCommands: List<String>;
    DebugMode: Boolean;

  public
    const DOUBLE_DASHES = '--';
    const TYPE_BOOL_VALUE = 'bool';
    const TYPE_INT_VALUE = 'int';
    const TYPE_STRING_VALUE = 'string';

    constructor(aDebugMode: Boolean := false);
    method AddOption(O: String; OptionType: String; Help: String): Boolean;
    method AddOptionalBoolFlag(Flag: String; Help: String);
    method AddOptionalIntArgument(Arg: String; Help: String);
    method AddOptionalStringArgument(Arg: String; Help: String);
    method AddRequiredArgument(Arg: String; Help: String);
    method ParseArgs(Args: ImmutableList<String>): PropertySet;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor ArgumentParser(aDebugMode: Boolean);
begin
  DictAllReservedWords := new Dictionary<String, String>;
  DictBoolOptions := new Dictionary<String, String>;
  DictIntOptions := new Dictionary<String, String>;
  DictStringOptions := new Dictionary<String, String>;
  DictCommands := new Dictionary<String, String>;
  ListCommands := new List<String>;
  DebugMode := aDebugMode;
end;

//*******************************************************************************

method ArgumentParser.AddOption(O: String;
                                OptionType: String;
                                Help: String): Boolean;
begin
  var OptionAdded := true;

  if OptionType = TYPE_BOOL_VALUE then
    DictBoolOptions[O] := Help
  else if OptionType = TYPE_INT_VALUE then
    DictIntOptions[O] := Help
  else if OptionType = TYPE_STRING_VALUE then
    DictStringOptions[O] := Help
  else
    OptionAdded := false;

  if OptionAdded then
    DictAllReservedWords[O] := OptionType;

  exit OptionAdded;
end;

//*******************************************************************************

method ArgumentParser.AddOptionalBoolFlag(Flag: String; Help: String);
begin
  AddOption(Flag, TYPE_BOOL_VALUE, Help);
end;

//*******************************************************************************

method ArgumentParser.AddOptionalIntArgument(Arg: String; Help: String);
begin
  AddOption(Arg, TYPE_INT_VALUE, Help);
end;

//*******************************************************************************

method ArgumentParser.AddOptionalStringArgument(Arg: String; Help: String);
begin
  AddOption(Arg, TYPE_STRING_VALUE, Help);
end;

//*******************************************************************************

method ArgumentParser.AddRequiredArgument(Arg: String; Help: String);
begin
  DictCommands[Arg] := Help;
  ListCommands.Add(Arg);
end;

//*******************************************************************************

method ArgumentParser.ParseArgs(Args: ImmutableList<String>): PropertySet;
var
  NumArgs: Integer;
  Working: Boolean;
  I: Integer;
  CommandsFound: Integer;
  Arg: String;
  ArgType: String;
  NextArg: String;
  CommandName: String;

begin
  var ps := new PropertySet;

  NumArgs := Args.Count;
  Working := true;
  I := 0;
  CommandsFound := 0;

  if NumArgs = 0 then
    Working := false;


  while Working do
  begin
    Arg := Args[I];
    if DictAllReservedWords.ContainsKey(Arg) then begin
      ArgType := DictAllReservedWords[Arg];
      Arg := Arg.Substring(2);
      if ArgType = TYPE_BOOL_VALUE then begin
        if DebugMode then begin
          writeLn("ArgumentParser: adding key={0} value=true", Arg);
        end;
        ps.Add(Arg, new PropertyValue(true));
      end
      else if ArgType = TYPE_INT_VALUE then begin
        inc(I);
        if I < NumArgs then begin
          NextArg := Args[I];
          var IntValue := Convert.TryToInt32(NextArg);
          if IntValue <> nil then begin
            if DebugMode then begin
              writeLn("ArgumentParser: adding key={0} value={1}", Arg, IntValue);
            end;
            ps.Add(Arg, new PropertyValue(IntValue));
          end;
        end
        else begin
          // missing int value
          writeLn("ArgumentParser: missing int value for key={0}", Arg);
        end;
      end
      else if ArgType = TYPE_STRING_VALUE then begin
        inc(I);
        if I < NumArgs then begin
          NextArg := Args[I];
          if DebugMode then begin
            writeLn("ArgumentParser: adding key={0} value={1}", Arg, NextArg);
          end;
          ps.Add(Arg, new PropertyValue(NextArg));
        end
        else begin
          // missing string value
          writeLn("ArgumentParser: missing string value for key={0}", Arg);
        end;
      end
      else begin
        // unrecognized type
        writeLn("ArgumentParser: unrecognized data type for key={0}", Arg);
      end;
    end
    else begin
      if Arg.StartsWith(DOUBLE_DASHES) then begin
        // unrecognized option
        writeLn("ArgumentParser: unrecognized option {0}", Arg);
      end
      else begin
        if CommandsFound < ListCommands.Count then begin
          CommandName := ListCommands[CommandsFound];
          if DebugMode then begin
            writeLn("ArgumentParser: adding key={0} value={1}", CommandName, Arg);
          end;
          ps.Add(CommandName, new PropertyValue(Arg));
          inc(CommandsFound);
        end
        else begin
          // unrecognized command
          writeLn("ArgumentParser: unrecognized command {0}", Arg);
        end;
      end;
    end;

    inc(I);
    if I >= NumArgs then begin
      Working := false;
    end;
  end;

  exit ps;
end;

//*******************************************************************************

end.