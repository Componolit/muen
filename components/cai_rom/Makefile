COMPONENT = cai_rom
COMPONENT_TARGETS = cspecs
include ../common.mk

$(POLICY_OBJ_DIR)/$(COMPONENT): $(COMP_BIN) $(INSTALL_TARGETS) $(POLICY_OBJ_DIR)/cai_rom_test_file
	 @$(E) $(COMPONENT) Install "$(TO_RAW_CMD) $< $@"

$(POLICY_OBJ_DIR)/cai_rom_test_file:
	dd if=/dev/zero of=$@ bs=4k count=1
	echo "Rom\n" | dd of=$@ conv=notrunc

clean:
	@rm -rf $(OBJ_DIR) $(GEN_DIR)
