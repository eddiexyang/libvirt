ARG KUBEVIRT_IMAGE=quay.io/kubevirt/virt-launcher@sha256:f23102ca00bf12f7962021adfdfdad63c873b01a03001a6d20d5813950254b9c

FROM fedora:42 AS qemu-runtime

RUN dnf -y \
      --installroot=/opt/qemu \
      --releasever=42 \
      --setopt=install_weak_deps=False \
      install qemu-system-x86-core-2:9.2.4-2.fc42 \
    && dnf -y --installroot=/opt/qemu clean all \
    && rm -rf /opt/qemu/var/cache/dnf

FROM ${KUBEVIRT_IMAGE}

COPY --from=qemu-runtime /opt/qemu /opt/qemu
COPY --chmod=0755 qemu-kvm /usr/libexec/qemu-kvm

RUN /usr/libexec/qemu-kvm --version \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "isa-applesmc"' \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "vmxnet3"' \
    && /usr/libexec/qemu-kvm -device help | grep -q 'name "vmware-svga"'
