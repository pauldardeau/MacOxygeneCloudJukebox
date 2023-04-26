namespace MacOxygeneCloudJukebox;

uses
  Foundation, CloudJukeboxSharedProject;

type
  Program = class
  public

    class method Main(args: array of String): Int32;
    begin
      var ArgList := new List<String>;
      for each arg in args do begin
        ArgList.Add(arg);
      end;

      var JBMain := new JukeboxMain;
      result := JBMain.Run(ArgList);
    end;

  end;

end.