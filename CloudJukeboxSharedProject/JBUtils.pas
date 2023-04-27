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

      if s.Contains(" & ") then begin
        s := s.Replace("& ", "");
      end;

      if s.Contains(",") then begin
        s := s.Replace(",", "");
      end;

      result := s;
    end;

//*******************************************************************************

    method ComponentsFromFileName(FileName: String): tuple of (String, String, String);
    begin
      if FileName.Length = 0 then begin
        exit ("", "", "");
      end;

      const BaseFileName = Utils.GetBaseFileName(FileName);

      const Components = BaseFileName.Split(DOUBLE_DASHES, true);
      if Components.Count = 3 then begin
        exit (DecodeValue(Components[0]),
              DecodeValue(Components[1]),
              DecodeValue(Components[2]));
      end
      else begin
        exit ("", "", "");
      end;
    end;

//*******************************************************************************

    method ArtistFromFileName(FileName: String): String;
    begin
      var Artist := "";
      if FileName.Length > 0 then begin
        (Artist, _, _) := ComponentsFromFileName(FileName);
      end;
      result := Artist;
    end;

//*******************************************************************************

    method AlbumFromFileName(FileName: String): String;
    begin
      var Album := "";
      if FileName.Length > 0 then begin
        (_, Album, _) := ComponentsFromFileName(FileName);
      end;
      result := Album;
    end;

//*******************************************************************************

    method SongFromFileName(FileName: String): String;
    begin
      var Song := "";
      if FileName.Length > 0 then begin
        (_, _, Song) := ComponentsFromFileName(FileName);
      end;
      result := Song;
    end;

//*******************************************************************************

  end;

end.