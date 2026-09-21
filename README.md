# KubeVirt libvirt + AppleSMC QEMU

This image keeps the official KubeVirt v1.9.0 `virt-launcher` and libvirt runtime,
and replaces its QEMU executable with Fedora 42 QEMU 9.2.4. The build verifies
`isa-applesmc`, `vmxnet3`, and `vmware-svga` before publishing.

Image: `ghcr.io/eddiexyang/qemu:v1.9.0-qemu-9.2.4`

The Apple OSK, OVMF, OpenCore, VM disks, and VM-specific domain XML are not in
this image. This repository contains no VM data or credentials.
