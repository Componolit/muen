include ../../Makeconf

LOG = $(OBJ_DIR)/log.obj
DUMMY := $(shell mkdir -p $(OBJ_DIR) $(OBJ_DIR)/adainclude $(OBJ_DIR)/adalib)

SRC := system.ads

prepare: $(OBJ_DIR)/adalib/libgnat.a

$(OBJ_DIR)/adalib/libgnat.a:
	@$(E) spark_runtime Build 'make OBJ_DIR=$(OBJ_DIR) -C src/' $(LOG)

check:

clean:
	rm -rf $(OBJ_DIR)

$(POLICY_OBJ_DIR)/spark_runtime:
