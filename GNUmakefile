#
# GNUmakefile - Generated by ProjectCenter
#
ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif
ifeq ($(GNUSTEP_MAKEFILES),)
 $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

include $(GNUSTEP_MAKEFILES)/common.make

#
# Framework
#
VERSION = 0.1
PACKAGE_NAME = SPIDisplayKit
FRAMEWORK_NAME = SPIDisplayKit
SPIDisplayKit_CURRENT_VERSION_NAME = 0.1
SPIDisplayKit_DEPLOY_WITH_CURRENT_VERSION = yes


#
# Libraries
#
SPIDisplayKit_LIBRARIES_DEPEND_UPON += -lwiringPi 

#
# Public headers (will be installed)
#
SPIDisplayKit_HEADER_FILES = \
SPIDisplayKit.h \
PCD8544Display.h \
font.h \
pilogo.h 

#
# Objective-C Class files
#
SPIDisplayKit_OBJC_FILES = \
PCD8544Display.m
#
# AutoGSDoc
#
DOCUMENT_NAME = SPIDisplayKit

SPIDisplayKit_AGSDOC_FILES = SPIDisplayKit.gsdoc \
	$(SPIDisplayKit_HEADER_FILES) \
	$(SPIDisplayKit_OBJC_FILES) \


SPIDisplayKit_AGSDOC_FLAGS += -MakeFrames YES


#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble


#Only build documentation if doc=yes was passed on the command line
#
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif
