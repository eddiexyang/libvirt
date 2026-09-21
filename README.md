# KubeVirt libvirt + AppleSMC QEMU

This image keeps the official KubeVirt v1.9.0 `virt-launcher` and libvirt runtime,
and replaces its QEMU executable with Debian 13 QEMU 10.0.13
(`1:10.0.13+ds-0+deb13u1`), matching the verified NAS runtime. The build verifies
`isa-applesmc`, `vmxnet3`, and `vmware-svga` before publishing.

Image: `ghcr.io/eddiexyang/libvirt:v1.9.0-qemu-10.0.13`

The Apple OSK, OVMF, OpenCore, VM disks, and VM-specific domain XML are not in
this image. This repository contains no VM data or credentials.

The build sets QEMU's ELF interpreter and transitive library search path to
its isolated `/opt/qemu` runtime. The wrapper directly executes QEMU, so
`/proc/PID/exe` points to `qemu-system-x86_64` and the Linux process name is
`qemu-system-x86` (the kernel's 15-character limit), rather than the loader.
libvirt and virt-launcher retain their original loader and libraries.
The build checks the QEMU executable identity in addition to device support.
