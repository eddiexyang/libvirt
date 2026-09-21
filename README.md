# KubeVirt libvirt + AppleSMC QEMU

This image keeps the official KubeVirt v1.9.0 `virt-launcher` and libvirt runtime,
and replaces its QEMU executable with Debian 13 QEMU 10.0.13
(`1:10.0.13+ds-0+deb13u1`), matching the verified NAS runtime. The build verifies
`isa-applesmc`, `vmxnet3`, and `vmware-svga` before publishing.

Image: `ghcr.io/eddiexyang/libvirt:v1.9.0-qemu-10.0.13`

The Apple OSK, OVMF, OpenCore, VM disks, and VM-specific domain XML are not in
this image. This repository contains no VM data or credentials.
