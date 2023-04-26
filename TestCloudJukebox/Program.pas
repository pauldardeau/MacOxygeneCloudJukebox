namespace TestCloudJukebox;

uses
  RemObjects.Elements.EUnit;

type
  Program = public static class
  private

    method Main(args: array of String): Int32; public;
    begin
      var lTests := Discovery.DiscoverTests();
      Runner.RunTests(lTests) withListener(Runner.DefaultListener);
    end;

  end;

end.