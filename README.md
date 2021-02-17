# AutoDVD

This is a little shell script to save your DVDs on your local hard drive. It utilizes the MakeMKV package.
<br />In case you want to digitalize bluray discs, you may need to activate MakeMKV using a key.
The beta key is free and available at <a href="https://www.makemkv.com/buy/" target="_new">https://www.makemkv.com/buy/</a>.

## Disclaimer

Copying DVDs may be illegal in your country.
Please check your legal boundaries before using AutoDVD.
I do not take responsibilty for your actions.

## Installation

In order to install AutoDVD you just need to execute the script. It will automatically install all its dependencies.

Step 1: Make the script executeable

```
chmod +x ./AutoDVD.sh
```

Step 2: Run the script

```
./AutoDVD.sh
```

## Dependencies

-   makemkv-bin
-   makemkv-oss
-   util-linux
-   coreutils

Tested on Ubuntu 20.04 LTS.

## Customization

Further configuration options can be found in the first lines of the script. Changes are applied after restarting the script.

#### unmountAfterReading

```
unmountAfterReading=true
```

This will automatically unmount the disk drive after copying its contents, so the disk swap can be performed much faster.

#### diskAutodetect

```
diskAutodetect=true
```

This will detect new inserted disks once the script copied the previous disk. If set to _false_, you need to manual confirm that another disk got inserted. This is only supported if _unmountAfterReading_ is set to _true_.

#### titleMinlength

```
titleMinlength=300
```

A DVD contains multiple titles. Usually the longest title is the actual movie, so all small titles will be skipped by default. The default minimal title length is set to 300 seconds. The lower the minimal length is set, the more titles will be copied, which will slow down the process by a lot.
