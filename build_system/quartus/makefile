TOPLEVEL ?= toplevel
QUARTUS_BUILD_PATH ?= $(CURDIR)/build_system/quartus
VARS_TCL_PATH ?= $(CURDIR)/.cache/quartus
VARS_TCL ?= $(VARS_TCL_PATH)/vars.tcl
RTL_PATH ?= ../../../rtl
FILES_RTL_PATH ?= $(RTL_PATH)/lists/files_rtl.lst
INCDIRS_PATH ?= $(RTL_PATH)/lists/incdirs.lst
CUSTOM_ASSIGNMENTS_PATH ?= $(QUARTUS_BUILD_PATH)/custom_assignments.tcl

RELEASE_DIR 	?= $(CURDIR)/release
RELEASE_DIRS 	?= $(wildcard $(RELEASE_DIR)/*/) 
RELEASE_FILES	?= $(foreach directory,$(RELEASE_DIRS), $(directory)$(shell basename $(directory)).qpf)

.PHONY: all compile fmax create_releases

all: compile

compile: $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf

$(QUARTUS_BUILD_PATH)/$(TOPLEVEL)/NoC.qpf: $(shell find $(CURDIR)/rtl -type f | tr '\n' ' ')
	@mkdir -p $(QUARTUS_BUILD_PATH)/$(TOPLEVEL) $(VARS_TCL_PATH)

	@echo set TOPLEVEL $(TOPLEVEL) > $(VARS_TCL)
	@echo set RTL_PATH $(RTL_PATH)/.. >> $(VARS_TCL)
	@echo set CUSTOM_ASSIGNMENTS_PATH $(CUSTOM_ASSIGNMENTS_PATH) >> $(VARS_TCL)
	@echo set FILES_RTL_PATH $(FILES_RTL_PATH) >> $(VARS_TCL)
	@echo set INCDIRS_PATH $(INCDIRS_PATH) >> $(VARS_TCL)

	@cd $(QUARTUS_BUILD_PATH)/$(TOPLEVEL);\
	quartus_sh -t $(QUARTUS_BUILD_PATH)/Setup_sh.tcl

create_releases: $(RELEASE_FILES)

$(RELEASE_FILES): $(foreach file,$(shell cat $(dir $@)sources.lst),$(CURDIR)/$(file)) $(foreach file,$(shell cat $(dir $@)incfiles.lst),$(CURDIR)/$(file))
	@touch $(dir $@)src $(dir $@)inc
	@rm -r $(dir $@)src $(dir $@)inc
	@mkdir $(dir $@)src $(dir $@)inc
	$(foreach file,$(shell cat $(dir $@)sources.lst), cp $(CURDIR)/$(file) $(dir $@)src;)
	$(foreach file,$(shell cat $(dir $@)incfiles.lst), cp $(CURDIR)/$(file) $(dir $@)inc;)

clean:
	rm -rf $(QUARTUS_BUILD_PATH)/$(TOPLEVEL)
