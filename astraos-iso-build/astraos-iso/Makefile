# AstraOS ISO Build - Makefile
# Fedora base + GNOME + AstraOS extensions

DOCKER_IMAGE = astraos-iso-builder
VERSION = 0.3.0
ISO_NAME = AstraOS-$(VERSION)-x86_64.iso

.PHONY: build-iso build-image clean test-qemu dev shell help

## Build the Docker builder image
build-image:
	docker build -t $(DOCKER_IMAGE) -f docker/Dockerfile.build .

## Build the AstraOS Live ISO
build-iso: build-image
	docker run --rm --privileged \
		-v $(PWD)/kickstart:/kickstart:ro \
		-v $(PWD)/out:/results \
		-v $(PWD)/work:/tmp/lmc \
		$(DOCKER_IMAGE)
	@echo ""
	@echo "ISO built: out/$(ISO_NAME)"
	@ls -lh out/*.iso 2>/dev/null || echo "Check out/ directory"

## Test ISO in QEMU with VNC (port 5900)
test-qemu: build-iso
	@echo "Starting QEMU with VNC on port 5900..."
	@echo "Connect with: vncviewer localhost:5900"
	qemu-system-x86_64 \
		-m 4096 \
		-smp 2 \
		-cdrom out/$(ISO_NAME) \
		-boot d \
		-vnc :0 \
		-serial stdio \
		-device virtio-vga-gl \
		-display none

## Test ISO in QEMU with noVNC (port 6080) - for Codespaces
test-novnc: build-iso
	@echo "Starting QEMU + noVNC on port 6080..."
	$(MAKE) _run-qemu-vnc &
	sleep 2
	websockify --web=/usr/share/novnc 6080 localhost:5900

_run-qemu-vnc:
	qemu-system-x86_64 \
		-m 4096 \
		-smp 2 \
		-cdrom out/$(ISO_NAME) \
		-boot d \
		-vnc :0 \
		-serial stdio \
		-device virtio-vga-gl \
		-display none

## Open a shell in the builder container (debug)
shell dev:
	docker run -it --rm --privileged \
		-v $(PWD):/astraos \
		-v $(PWD)/kickstart:/kickstart:ro \
		-v $(PWD)/out:/results \
		-v $(PWD)/work:/tmp/lmc \
		$(DOCKER_IMAGE) bash

## Clean build artifacts
clean:
	rm -rf work/* out/*.iso
	docker system prune -f --filter label=astraos-build 2>/dev/null || true

## Show help
help:
	@echo "AstraOS ISO Build (Fedora base)"
	@echo ""
	@echo "Targets:"
	@echo "  build-iso   - Build AstraOS Live ISO"
	@echo "  build-image - Build Docker builder image only"
	@echo "  test-qemu   - Test ISO in QEMU (VNC port 5900)"
	@echo "  test-novnc  - Test ISO in QEMU + noVNC (port 6080)"
	@echo "  shell       - Open shell in builder container"
	@echo "  clean       - Clean work/ and out/"
	@echo "  help        - Show this help"
	@echo ""
	@echo "Output: out/AstraOS-$(VERSION)-x86_64.iso"
