# AppPack

An installer for a bundle of common Windows applications, created using the
[NSIS](https://nsis.sourceforge.io/Main_Page) technology.

> **_NOTE_**: There is no intention of appropriating any of the application executables
used. All the applications belong to their respective owners.

## Build

The [NSIS package](https://nsis.sourceforge.io/Download) must be installed,
which comes with the NSI compiler. It is highly recommended to use the
[NSIS extension](https://marketplace.visualstudio.com/items?itemName=idleberg.nsis)
for Visual Studio Code to build the installer.

Some additional plugins are required. In order to install them, the simple guide
[*"How can I install a plugin?"*](https://nsis.sourceforge.io/How_can_I_install_a_plugin)
from the NSIS page must be followed.

- [NScurl](https://nsis.sourceforge.io/NScurl_plug-in): Downloads safely the application
setups with HTTPS.
- [NsJSON](https://nsis.sourceforge.io/NsJSON_plug-in): Reads the JSON file that has all
the information of each application to install.
