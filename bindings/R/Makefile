include ../common/Makefile.common

BINDING_MODULE=$(call dynlib,ufal_morphodita)
BINDING_C_FLAGS+=-w

all: $(BINDING_MODULE)

include ../common/Makefile.rules

$(BINDING_MODULE): morphodita_R.cpp $(BINDING_MORPHODITA_LIB)
	$(CXX) -I../../src/include $(DYN_C_FLAGS) $(DYN_LD_FLAGS) $(BINDING_C_FLAGS) $(BINDING_LD_FLAGS) $(call version_script,morphodita_R.map) $^ -o $@

morphodita_R.cpp: morphodita_R.i ../common/morphodita.i
	@$(call mkdir,ufal)
	swig $(SWIG_FLAGS) -r -outdir ufal -o $@ $<

.PHONY: clean
clean:
	@$(call rmdir,ufal) $(call rm,$(BINDING_MODULE) morphodita_R.cpp)
