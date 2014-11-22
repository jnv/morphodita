include ../common/Makefile.common

BINDING_MODULE=$(call dynlib,ufal_morphodita)
BINDING_C_FLAGS+=-w

PKG_CPPFLAGS=-I../../src/include $(DYN_C_FLAGS) $(BINDING_C_FLAGS)
PKG_LIBS=$(DYN_LD_FLAGS) $(BINDING_LD_FLAGS)

R_CMD=R CMD SHLIB

all: $(BINDING_MODULE)

include ../common/Makefile.rules

$(BINDING_MODULE): morphodita_R.cpp $(BINDING_MORPHODITA_LIB)
	PKG_CPPFLAGS="$(PKG_CPPFLAGS)" PKG_LIBS="$(PKG_LIBS)" $(R_CMD) -o $@ $^

morphodita_R.cpp: morphodita_R.i ../common/morphodita.i
	@$(call mkdir,ufal)
	swig $(SWIG_FLAGS) -r -outdir ufal -o $@ $<

.PHONY: clean
clean:
	@$(call rmdir,ufal) $(call rm,$(BINDING_MODULE) morphodita_R.cpp)
