# MacOxygeneCloudJukebox

This is an Oxygene (Object Pascal from Remobjects) on macOS implementation of my original Python cloud-jukebox (https://github.com/pauldardeau/cloud-jukebox).

Unlike the python, go, and c# implementations, this one interfaces with S3 differently. Instead of using a native (same language SDK), it interfaces
with S3 by running simple shell scripts. These scripts are found in the 'scripts' directory.
