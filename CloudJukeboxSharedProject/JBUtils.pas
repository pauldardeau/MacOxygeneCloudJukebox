namespace CloudJukeboxSharedProject;

type
  JBUtils = public static class

  public
    const DOUBLE_DASHES = "--";

//*******************************************************************************

    method DecodeValue(EncodedValue: String): String;
    begin
      result := EncodedValue.Replace('-', ' ');
    end;

//*******************************************************************************

    method EncodeValue(Value: String): String;
    begin
      const ValueWithoutPunctuation = RemovePunctuation(Value);
      result := ValueWithoutPunctuation.Replace(' ', '-');
    end;

//*******************************************************************************

    method EncodeArtistAlbum(artist: String; album: String): String;
    begin
      result := EncodeValue(artist) + DOUBLE_DASHES + EncodeValue(album);
    end;

//*******************************************************************************

    method EncodeArtistAlbumSong(artist: String;
                                 album: String;
                                 song: String): String;
    begin
      result := EncodeArtistAlbum(artist, album) +
                DOUBLE_DASHES +
                EncodeValue(song);
    end;

//*******************************************************************************

    method RemovePunctuation(s: String): String;
    begin
      if s.Contains("'") then begin
        s := s.Replace("'", "");
      end;

      if s.Contains("!") then begin
        s := s.Replace("!", "");
      end;

      if s.Contains("?") then begin
        s := s.Replace("?", "");
      end;

      if s.Contains("&") then begin
        s := s.Replace("&", "");
      end;

      result := s;
    end;

//*******************************************************************************

  end;

end.