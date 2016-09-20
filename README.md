# novena-kernel-patches
Patchset for the Linux kernel (v4.7.2) on the Novena SBC, adapted from xobs' [novena-linux](https://github.com/xobs/novena-linux).

## Description


<img src="https://raw.githubusercontent.com/sakaki-/resources/master/kousagi/novena/Kousagi_Novena.jpg" alt="Kousagi Novena" width="250px" align="right"/>
This project contains a set of patches for the Linux kernel, enabling it to be used with the Novena single-board computer. The patches were derived from xobs' [novena-linux](https://github.com/xobs/novena-linux) project, which (at the time of writing, commit [49d5f10](https://github.com/xobs/novena-linux/commit/49d5f1070f3880b03db1a55347d28b77b221771e)) contains a patchset rebased, most recently, against Linux 4.4 (commit [400e186](https://github.com/xobs/novena-linux/commit/400e1869c6aa2af116e2ce73627e551a1ecf0e1d)).

The `git` commit list of Novena-specific edits in xobs' `novena-linux` since the 4.4 rebase may be seen [here](https://github.com/xobs/novena-linux/compare/400e186...49d5f10). I began by exporting the (non-merge) commits as a set of patch files, thus:

```console
~ $ git clone https://www.github.com/xobs/novena-linux
~ $ cd novena-linux
novena-linux $ mkdir /tmp/patches
novena-linux $ git format-patch -o /tmp/patches 400e186...49d5f10
```

I then reworked the patches to get them to apply against a Linux 4.7.2 baseline (rather than 4.4). Most of the patches needed no modification, or only small context changes. Patches that cancelled each other out (such as [these](https://github.com/sakaki-/novena-kernel-patches/commit/1d78ce714a9ccf88b4809dc329831d536752ab68)) were jointly dropped.

A few edits were less trivial / obvious:
* The `etnaviv` DRM driver code has been upstreamed (from 4.5), so I have removed (see [here](https://github.com/sakaki-/novena-kernel-patches/commit/80fb26cbd2cb824d39944cb43016223c3526ee24) and [here](https://github.com/sakaki-/novena-kernel-patches/commit/a50a8dbc63649545aa836f3590e6d23f7cd0990d)) its corresponding driver patch entirely.
* The file `arch/arm/boot/dts/imx6q-novena.dts` has been upstreamed in 4.7.2, but patch 0016 [was modified](https://github.com/sakaki-/novena-kernel-patches/commit/f71696a19dc9ef54a8900cd7c1b30f9729a70d6e) to bring the content in line with that in 4.4-novena-r9 (as that was larger). This also obviated some of the other dts-related patches (since all changes are now made via a single patch).
* Where patches created new files (and modified no pre-existing files), they were shifted from patchlevel 1 to 0 (for example, [here](https://github.com/sakaki-/novena-kernel-patches/commit/311f67e39e6cd6476cf7929c90b52f337d65140f)); Gentoo's `unipatch` fails with them otherwise.
* The `es8328` (audio codec) code has changed significantly from 4.4 to 4.7.2; I have tried to finesse the 'no MCLK set up' issue with a simple intercept of the `es8328_hw_params` function (edit [here](https://github.com/sakaki-/novena-kernel-patches/commit/4a1ab9656cee4aeee8c0d674756b0112cad5a7c8)). *Seems* to work...
* I have left the various Debian-related changes in place. Not needed for Gentoo, but they don't hurt either.
* I have added two additional small patches, to address significant issues:
  * [Patch 1001](https://github.com/sakaki-/novena-kernel-patches/commit/cbfcd8f3770a738f203f7bc5a3b073311d220ed8) turns on `CONFIG_DRM_DW_HDMI_AHB_AUDIO` by default in `novena_defconfig`. Without it, it is not possible to play audio on HDMI monitors, on 4.7.2.
  * [Patch 1101](https://github.com/sakaki-/novena-kernel-patches/commit/7de43ca917575e9ef5464fae0016e6b27a88cb1e) turns on `CONFIG_GRKERNSEC_OLD_ARM_USERLAND`; this is necessary (for hardened kernels with the Grsecurity patchset only) [to avoid segfaults](https://forums.grsecurity.net/viewtopic.php?f=3&t=4479) when running Mozilla software like Firefox.

A full list of my patch modifications may be viewed [here](https://github.com/sakaki-/novena-kernel-patches/compare/7037ff5...7de43ca).

> Please note that this patchset is provided without warranty. Use at your own risk.

> Incidentally, I have chosen to use a patchlist format (rather than another rebase) because:  
  * the set of Novena-specific edits to the kernel codebase seems quite stable now; and   
  * I wanted a format that could easily be used by Gentoo `kernel-2` ebuilds, and also by non-Gentoo users.

## Installation

You can apply these patches to a vanilla 4.7.2 kernel (and quite possibly, to later kernels, with no or only slight modification); it is not necessary to be running Gentoo. However, if you *are* using Gentoo on your Novena, I have provided two utility ebuilds to fetch and patch the kernel sources (one mirroring `sys-kernel/gentoo-sources`, and the other `sys-kernel/hardened-sources`).

Please choose the appropriate set of installation instructions from the below.

### Option 1: Non-Gentoo Users

Fetch the patches and 4.7.2 kernel source, then patch your kernel and build as usual. The only slight trickiness comes from the fact that some of the patches are at patchlevel 0, and some at patchlevel 1 (due to quirks in Gentoo's `unipatch`, as described above), but I have supplied a small script to handle that.

Here's a simple example workflow (you can of course download the kernel via `git` and other tools, but we'll just use a tarball here):

```console
~ $ git clone https://github.com/sakaki-/novena-kernel-patches
~ $ wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.7.2.tar.xz
( you can also download and check the signature file; search online for details )
~ $ tar -xJf linux-4.7.2.tar.xz
~ $ cd linux-4.7.2
linux-4.7.2 $ ../novena-kernel-patches/apply-patches.sh
( assuming that went OK, then proceed )
linux-4.7.2 $ make novena_defconfig
linux-4.7.2 $ make -j4 zImage modules dtbs
( this will take some time! )
linux-4.7.2 $ sudo make modules_install
( assuming your /boot is mounted, do: )
linux-4.7.2 $ cd /boot
boot $ sudo mv zImage{,.bak}
boot $ sudo mv novena.dtb{,.bak}
boot $ sudo cp "${HOME}/linux-4.7.2/arch/arm/boot/zImage" .
boot $ sudo cp "${HOME}/linux-4.7.2/arch/arm/boot/dts/imx6q-novena.dtb" novena.dtb
boot $ sync
```
Then simply reboot to start using your new kernel!

### Option 2: Gentoo Users

This patchset is most easily installed via one of the Gentoo ebuilds that use it, for which please see my [gentoo-novena-overlay](https://github.com/sakaki-/gentoo-novena-overlay) project (_forthcoming_).

I have provided two ebuilds. The first, [`sys-kernel/novena-sources`](https://github.com/sakaki-/gentoo-novena-overlay/tree/master/sys-kernel/novena-sources) mirrors [`sys-kernel/gentoo-sources`](https://packages.gentoo.org/packages/sys-kernel/gentoo-sources); the second, [`sys-kernel/novena_hardened-sources`](https://github.com/sakaki-/gentoo-novena-overlay/tree/master/sys-kernel/novena_hardened-sources) mirrors [`sys-kernel/hardened-sources`](https://packages.gentoo.org/packages/sys-kernel/hardened-sources) (and supports the `deblob` USE flag, allowing you to build a libre kernel; under which everything - with the exception of bluetooth - still works, amazingly ^-^).

Assuming you have my overlay installed (if not, instructions for installing it may be found [here](https://github.com/sakaki-/gentoo-novena-overlay)), you can simply do:

```console
~ # emerge -v ~sys-kernel/novena-sources-4.7.2
~ # eselect kernel list
( displays a numbered list of available kernels )
~ # eselect kernel set <n>
( substitute the linux-4.7.2-novena kernel's index from the list for <n>; e.g., "eselect kernel set 1" )
~ # cd /usr/src/linux
~ # make novena_defconfig
linux # make -j4 zImage modules dtbs
( this will take some time! if you have distcc installed, use pump make, and a higher -j value )
linux # make modules_install
( assuming your /boot is mounted, do: )
linux # cd /boot
boot # mv zImage{,.bak}
boot # mv novena.dtb{,.bak}
boot # cp "/usr/src/linux/arch/arm/boot/zImage" .
boot # cp "/usr/src/linux/arch/arm/boot/dts/imx6q-novena.dtb" novena.dtb
boot # sync
```
Then reboot to start using your new kernel!

## Feedback Welcome!

If you have any problems, questions or comments regarding this project, feel free to drop me a line! (sakaki@deciban.com)
