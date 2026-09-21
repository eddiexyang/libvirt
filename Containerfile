ARG KUBEVIRT_IMAGE=quay.io/kubevirt/virt-launcher@sha256:f23102ca00bf12f7962021adfdfdad63c873b01a03001a6d20d5813950254b9c

FROM debian:trixie-slim AS qemu-runtime

ARG QEMU_VERSION=1:10.0.13+ds-0+deb13u1

# Resolve the complete runtime dependency set, including libraries already
# installed in the build stage, and keep it isolated from launcher/libvirt.
RUN apt-get update \
    && apt-get -y --download-only --no-install-recommends \
      -o Dir::State::status=/dev/null \
      install qemu-system-x86=${QEMU_VERSION} \
    && mkdir -p /opt/qemu \
    && for package in /var/cache/apt/archives/*.deb; do \
         dpkg-deb --extract "$package" /opt/qemu; \
       done

FROM ${KUBEVIRT_IMAGE}

COPY --from=qemu-runtime /opt/qemu /opt/qemu
COPY --chmod=0755 qemu-kvm /usr/libexec/qemu-kvm

RUN /usr/libexec/qemu-kvm --version \
    && /usr/libexec/qemu-kvm --version | grep -q 'version 10.0.13' \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "isa-applesmc"' \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "vmxnet3"' \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "vmware-svga"' \
    && printf 'quit\n' | /usr/libexec/qemu-kvm \
         -machine q35,accel=tcg -nodefaults -display none \
         -device vmware-svga -S -monitor stdio
