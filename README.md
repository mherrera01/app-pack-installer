# AppPack

AppPack is an open-source installer designed to simplify the process of setting
up a Windows 10/11 computer. It provides a bundle of essential third-party
applications across different categories, from which users can choose - all
conveniently housed in one place. The step-by-step installation wizard offers
a straightforward approach to create a custom system environment.

> [!NOTE]
> There is no intention of appropriating any of the third-party software components
in use. All the applications belong to their respective owners.

_Created using the [NSIS](https://nsis.sourceforge.io/Main_Page) technology_

## Build

The [NSIS package](https://nsis.sourceforge.io/Download) must be installed,
which comes with the NSI compiler. It is highly recommended to use the
[NSIS extension](https://marketplace.visualstudio.com/items?itemName=idleberg.nsis)
for Visual Studio Code to build AppPack.

Some additional plugins are required. In order to install them, the simple guide
[*"How can I install a plugin?"*](https://nsis.sourceforge.io/How_can_I_install_a_plugin)
from the NSIS page must be followed.

- [NScurl](https://nsis.sourceforge.io/NScurl_plug-in): Downloads safely the required
files from the internet with HTTPS.
- [NsThread](https://nsis.sourceforge.io/NsThread_plug-in): Allows the creation of threads.
- [NsArray](https://nsis.sourceforge.io/Arrays_in_NSIS#nsArray_plug-in): Enables to
store and manipulate dynamic sized arrays.

## Remarks

### Security Concerns

The installation of apps usually requires administrator privileges and may lead to
security threats. Therefore, AppPack is open source so that complete transparency
can be ensured. The bundle files currently maintained are available in this
[Github repository](https://github.com/mherrera01/app-pack-installer/tree/develop/appBundles)
and all the setup links are obtained from the official sites of each software provider.

> [!IMPORTANT]
> AppPack just executes the application setups specified in the bundle file. An
analysis to detect malware and other breaches is **not** performed. The user must be
held responsible for the external source bundles that are used.

### Silent Mode

Explanation about the silent mode.

## How to Create a Custom Bundle

A template file (link) is provided to create correctly a custom bundle.

### Encoding

The UTF-16LE (with BOM) encoding is used, as it is the Windows default for allowing
Unicode characters.
