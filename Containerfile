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

# DT_RPATH also applies to transitive dependencies; DT_RUNPATH on just the
# executable would allow them to fall back to the launcher's system libraries.
# patchelf is a build-stage tool and is not copied into the final image.
RUN apt-get install -y --no-install-recommends patchelf \
    && patchelf \
      --set-interpreter /opt/qemu/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
      --force-rpath --set-rpath /opt/qemu/usr/lib/x86_64-linux-gnu \
      /opt/qemu/usr/bin/qemu-system-x86_64 \
    && test "$(patchelf --print-interpreter /opt/qemu/usr/bin/qemu-system-x86_64)" \
      = /opt/qemu/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
    && test "$(patchelf --print-rpath /opt/qemu/usr/bin/qemu-system-x86_64)" \
      = /opt/qemu/usr/lib/x86_64-linux-gnu

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

# Exercise the wrapper's exec without KVM, and check the executable identity
# reported to process monitors. Always reap this build-only smoke-test process.
RUN set -eu; \
    /usr/libexec/qemu-kvm -machine none,accel=tcg -nodefaults -display none -S & \
    qemu_pid=$!; \
    trap 'kill "$qemu_pid" 2>/dev/null || true; wait "$qemu_pid" 2>/dev/null || true' EXIT; \
    attempts=0; \
    while [ "$(readlink /proc/"$qemu_pid"/exe)" != /opt/qemu/usr/bin/qemu-system-x86_64 ]; do \
      kill -0 "$qemu_pid"; \
      attempts=$((attempts + 1)); \
      test "$attempts" -lt 100; \
      sleep 0.1; \
    done; \
    test "$(cat /proc/"$qemu_pid"/comm)" = qemu-system-x86
