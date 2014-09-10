include Makeconf

export HARDWARE
export SYSTEM

ifeq (,$(filter $(MAKECMDGOALS),clean distclean))
ifeq (,$(NO_CONTRIB))
CONTRIB := $(shell $(MAKE) -C contrib)
endif
endif

all: pack

rts:
	$(MAKE) -C $@

policy: tools
	$(MAKE) -C $@

components: policy rts
	$(MAKE) -C $@

kernel: policy rts
	$(MAKE) -C $@

pack: policy kernel components
	$(MAKE) -C $@

tools:
	$(MAKE) -C $@

tools_install:
	$(MAKE) -C tools install PREFIX=$(PREFIX)

deploy: HARDWARE=lenovo-t430s
deploy: SYSTEM=demo_system_vtd
deploy: pack
	$(MAKE) -C $@

emulate: pack
	$(MAKE) -C $@

iso: pack
	$(MAKE) -C emulate $@

tests:
	$(MAKE) -C tools $@

clean:
	$(MAKE) clean -C deploy
	$(MAKE) clean -C tools
	$(MAKE) clean -C kernel
	$(MAKE) clean -C pack
	$(MAKE) clean -C policy
	$(MAKE) clean -C components
	$(MAKE) clean -C rts
	rm -rf contrib/obj

distclean: clean
	$(MAKE) clean -C contrib

.PHONY: components deploy emulate kernel pack policy rts tools
