# Pyonkee

## Overview

[Pyonkee](http://softumeya.com/pyonkee/en/) is a visual-programming language running on iPad. It is based on Scratch from the MIT Media Laboratory.

Pyonkee has been developed from [the open-source code of "Scratch 1.4"](http://wiki.scratch.mit.edu/wiki/Scratch_1.4_Source_Code) from MIT. Since Pyonkee is fully compatible with Scratch 1.4, millions of existing Scratch projects can be used for reference. 

Pyonkee's user interface is optimized for touch devices. We do not need cumbersome typing, even a mouse. Just write programs wherever you like. Pyonkee nicely supports pinch-in/out, and font scaling for small devices. Moreover, sound recorder and camera are provided for importing your sounds and pictures into the projects. We can mix various media on Pyonkee and program them.

## History

Pyonkee was originally started as a fork of [John M McIntosh](https://www.smalltalkconsulting.com)'s Scratch Viewer - [Scratch.app.for.iOS](https://github.com/johnmci/Scratch.app.for.iOS). While Scratch Viewer just works as a viewer of the existing Scratch projects, Pyonkee supports creation/edit of projects.

### Other major modifications from the viewer:

- User interfaces are optimized for iPad (Viewer supports both iPhone and iPad)
- Native font support
- Embedded camera support
- IME support
- Auto-saving project
- Sending/Receiving projects via e-mail
- Project import/export through iTunes
- Photo importer/trimmer
- Project sharing via AirDrop
- iPad built-in sensors support
- "Mesh" network protocol support - (project variables/events are sharable with connected peers)
- Built-in MIDI synth
- Virtual MIDI support
- iCloud based project/sprite/costume/sounds sharing
- Touch scrolling support

## How to build

From version 2.3, [Carthage](https://github.com/Carthage/Carthage) is partly used for library management.
Before building from Xcode, please install Carthage and run the command below:

```carthage update --use-xcframeworks```

Note: from Xcode 12, you need a [workaround script for carthage](https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md).

### Note on iCloud feature

When attempting to build and run on a physical iPad (not the simulator), you will receive the message:

The 'iCloud' feature is only available to users enrolled in Apple Developer Program. Please visit https://developer.apple.com/programs/ to enroll.

To disable iCloud and allow the build to continue, change line 2168 of Pyonkee.xcodeproj/project.pbxproj from:

```
com.apple.iCloud = {
	enabled = 1;
};
```

to

```
com.apple.iCloud = {
	enabled = 0;
};
```

which will disable iCloud and allow the build to continue.

## License

Pyonkee is a derivative work of open-sourced Scratch 1.4 and licensed under the GPL v2. See the included gpl-2.0.txt for details. 

Additional Squeak image components in Scratch.image, Squeak VM source code (/src) and VM support code (/platforms) are under MIT license.

The Squeak iOS platform (/platforms/iOS, /CSCScratchiPhoneInterface) are under MIT License. 

Scratch sample Media files (/Resources/Media), and sample projects (/Resources/Projects), are licensed under the Creative Commons Attribution-ShareAlike 2.0 Generic (CC BY-SA 2.0) license.

Third party Objective-C libraries (/ThirdPartyClasses) are under the each author's original license. See /ThirdPartyClasses/README.md for details.

## Contributions

Your contributions are always welcome. Especially we would like to improve translations. For now, complete translations are only available for English, Japanese, and German. We would like to provide full translations for French, Spanish, Portuguese, etc.

|Language Translation|Contributor|
|:---|:---|
| German| [@aBrAEUMER](https://github.com/aBrAEUMER) |

## Questions?

Please visit [SoftUmeYa Pyonkee support site](http://softumeya.com/pyonkee/en/).

We can also customize Pyonkee for your needs. Feel free to contact us.


-----
Copyright 2014-2021 SoftUmeYa, LLC


