include ../../Makeconf

LOG = $(OBJ_DIR)/log.obj
DUMMY := $(shell mkdir -p $(OBJ_DIR) $(OBJ_DIR)/adainclude $(OBJ_DIR)/adalib)

SRC = a-except.adb \
      a-unccon.ads \
      ada.ads \
      i-c.adb \
      i-cexten.ads \
      interfac.ads \
      runtime_lib.ads \
      runtime_lib-secondary_stack.adb \
      runtime_lib-strings.adb \
      runtime_lib-debug.adb \
      runtime_lib-platform.adb \
      runtime_lib-exceptions.ads \
      s-exctab.adb \
      s-init.adb \
      s-parame.adb \
      s-unstyp.ads \
      s-secsta.adb \
      s-soflin.adb \
      s-stalib.adb \
      s-stoele.adb \
      s-arit64.adb \
      s-maccod.ads \
      system.ads \
      argv.c \
      exit.c \
      init.c \
      muen.adb \
      sk.ads \
      sk-cpu.adb \
      x86_64.adb \
      memcmp.S \
      memcpy.S \
      memset.S

SRC := $(sort $(SRC) $(patsubst %.adb, %.ads, $(filter %.adb, $(SRC))))

prepare: runtime

runtime: $(OBJ_DIR)/adalib/libgnat.a

$(OBJ_DIR)/adalib/libgnat.a: $(addprefix $(OBJ_DIR)/adainclude/,$(SRC))
	@$(E) spark_runtime Build 'gprbuild --RTS=$(OBJ_DIR) -P rts.gpr -XOBJECT_DIR=$(OBJ_DIR) -p' $(LOG)

$(OBJ_DIR)/adainclude/%: src/src/minimal/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%: src/src/common/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%: src/src/lib/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%: src/contrib/gcc-8.3.0/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%: src/platform/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%.S: src/platform/%.S src/platform/bcopy.S src/platform/asm.h
	$(CC) -E $< -Isrc/platform/ -o $@

$(OBJ_DIR)/adainclude/%: $(TOP_DIR)/common/src/%
	cp -a $< $@

$(OBJ_DIR)/adainclude/%: $(TOP_DIR)/rts/src/asm/%
	cp -a $< $@

check:

clean:
	rm -rf $(OBJ_DIR)

$(POLICY_OBJ_DIR)/spark_runtime:
