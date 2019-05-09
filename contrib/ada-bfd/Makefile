REV = 72e10733f48bf1426fe62eb430895f7c7d5acf95
PKG = ada-bfd
SRC = https://github.com/jklmnn/ada-bfd.git

define CMD_CONFIGURE
	cd $(WRK) && ./configure --prefix=$(BUILDDIR)
endef

all: install_default

include ../contrib.git.mk
