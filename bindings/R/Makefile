include ../common/Makefile.common

BINDING_MODULE=$(call dynlib,morphodita)
BINDING_C_FLAGS+=-w

PKG_CPPFLAGS=-I../../src/include $(DYN_C_FLAGS) $(BINDING_C_FLAGS)
PKG_LIBS=$(DYN_LD_FLAGS) $(BINDING_LD_FLAGS)

R_CMD=R CMD SHLIB

all: $(BINDING_MODULE)

include ../common/Makefile.rules

$(BINDING_MODULE): morphodita_R.cpp $(BINDING_MORPHODITA_LIB)
	PKG_CPPFLAGS="$(PKG_CPPFLAGS)" PKG_LIBS="$(PKG_LIBS)" $(R_CMD) -o $@ $^

morphodita_R.cpp: morphodita_R.i ../common/morphodita.i
	swig $(SWIG_FLAGS) -r -o $@ $<

.PHONY: clean
clean:
	$(call rm,$(BINDING_MODULE) morphodita_R.cpp)
