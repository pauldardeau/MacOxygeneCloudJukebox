namespace MacOxygeneCloudJukebox;

type
  JBUtils = public static class

  public

//*******************************************************************************

    method UnencodeValue(EncodedValue: String): String;
    begin
      result := EncodedValue.Replace('-', ' ');
    end;

//*******************************************************************************

    method EncodeValue(Value: String): String;
    begin
      result := Value.Replace(' ', '-');
    end;

//*******************************************************************************

  end;

end.