# AppPack

An installer for a bundle of common Windows 10/11 applications, created using the
[NSIS](https://nsis.sourceforge.io/Main_Page) technology.

> [!NOTE]
> There is no intention of appropriating any of the application executables
used. All the applications belong to their respective owners.

## Build

The [NSIS package](https://nsis.sourceforge.io/Download) must be installed,
which comes with the NSI compiler. It is highly recommended to use the
[NSIS extension](https://marketplace.visualstudio.com/items?itemName=idleberg.nsis)
for Visual Studio Code to build the installer.

Some additional plugins are required. In order to install them, the simple guide
[*"How can I install a plugin?"*](https://nsis.sourceforge.io/How_can_I_install_a_plugin)
from the NSIS page must be followed.

- [NScurl](https://nsis.sourceforge.io/NScurl_plug-in): Downloads safely the required
files from the internet with HTTPS.
- [NsJSON](https://nsis.sourceforge.io/NsJSON_plug-in): Reads the JSON file that has all
the information of each application to install.
- [NsThread](https://nsis.sourceforge.io/NsThread_plug-in): Allows the creation of threads.
- [NsArray](https://nsis.sourceforge.io/Arrays_in_NSIS#nsArray_plug-in): Enables to
store and manipulate dynamic sized arrays.

## Remarks

### Security Concerns

The installation of apps usually requires administrator privileges and may lead to
security threats. Therefore, AppPack is open source so that complete transparency
can be ensured. The setup links in the default bundle are obtained from the official
sites of each software provider.

> [!IMPORTANT]
> AppPack just executes the application setups specified in the JSON bundle. An
analysis to detect malware and other breaches is **not** performed. The user must be
held responsible for the custom bundles that are used. AppPack only maintains the
JSON files available in this
[Github repository](https://github.com/mherrera01/app-pack-installer/tree/develop/appBundles).

### Unicode Support

Due to a bug, the nsJSON plug-in cannot read UTF-8 files in unicode. So, the JSON
bundles are converted to a valid UTF-16 encoding, in order to allow all the language
characters.

### Silent Mode

Explanation about the silent mode.
