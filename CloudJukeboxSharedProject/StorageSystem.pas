namespace CloudJukeboxSharedProject;

interface

type
  StorageSystem = abstract public class

  public
    method Enter: Boolean; abstract;
    method Leave; abstract;
    method ListAccountContainers: List<String>; abstract;
    method GetContainerNames: ImmutableList<String>; abstract;
    method HasContainer(ContainerName: String): Boolean; abstract;
    method CreateContainer(ContainerName: String): Boolean; abstract;
    method DeleteContainer(ContainerName: String): Boolean; abstract;
    method ListContainerContents(ContainerName: String): ImmutableList<String>; abstract;
    method GetObjectMetadata(ContainerName: String;
                             ObjectName: String;
                             DictProps: PropertySet): Boolean; abstract;
    method PutObject(ContainerName: String;
                     ObjectName: String;
                     FileContents: array of Byte;
                     Headers: PropertySet): Boolean; abstract;
    method PutObjectFromFile(ContainerName: String;
                             ObjectName: String;
                             FilePath: String;
                             Headers: PropertySet): Boolean; abstract;
    method DeleteObject(ContainerName: String;
                        ObjectName: String): Boolean; abstract;
    method GetObject(ContainerName: String;
                     ObjectName: String;
                     LocalFilePath: String): Int64; abstract;
  end;

implementation

end.