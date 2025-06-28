#Build artifact type, possible values shared, static and exe
ARTIFACT_TYPE = exe
PROJECT_NAME = cockpit

LDFLAGS_shared = -shared -o
ARTIFACT_NAME_shared = lib$(PROJECT_NAME).so

LDFLAGS_static = -static -a
ARTIFACT_NAME_static = lib$(PROJECT_NAME).a

LDFLAGS_exe = -o
ARTIFACT_NAME_exe = $(PROJECT_NAME)

ARTIFACT = $(ARTIFACT_NAME_$(ARTIFACT_TYPE))

#Build architecture/variant string, possible values: x86, armv7le, etc...
PLATFORM ?= x86_64

OUTPUT_DIR = build/$(PLATFORM)
TARGET = $(OUTPUT_DIR)/$(ARTIFACT)

#Compiler definitions

ifeq ($(PLATFORM),linux)
    CC = gcc
    CXX = g++
    LD = $(CXX)
else
    CC = qcc -Vgcc_nto$(PLATFORM)
    CXX = q++ -Vgcc_nto$(PLATFORM)_cxx
    LD = $(CXX)
endif

#User defined include/preprocessor flags and libraries

#INCLUDES += -I/path/to/my/lib/include
#INCLUDES += -I../mylib/public

#LIBS += -L/path/to/my/lib/$(PLATFORM)/usr/lib -lmylib
#LIBS += -L../mylib/$(OUTPUT_DIR) -lmylib

#Compiler flags
CCFLAGS_all += -Wall -fmessage-length=0 -g -O0
DEPS = -Wp,-MMD,$(@:%.o=%.d),-MT,$@

#Macro to expand files recursively: parameters $1 -  directory, $2 - extension, i.e. cpp
rwildcard = $(wildcard $(addprefix $1/*.,$2)) $(foreach d,$(wildcard $1/*),$(call rwildcard,$d,$2))

#Source list
SRCS = cockpit.cpp

#Object files list
OBJS = $(addprefix $(OUTPUT_DIR)/,$(addsuffix .o, $(basename $(SRCS))))

#Compiling rule for c
$(OUTPUT_DIR)/%.o: %.c
	-@mkdir -p $(OUTPUT_DIR)
	$(CC) -c $(DEPS) -o $@ $(INCLUDES) $(CCFLAGS_all) $(CCFLAGS) $<

#Compiling rule for c++
$(OUTPUT_DIR)/%.o: %.cpp
	-@mkdir -p $(OUTPUT_DIR)
	$(CXX) -c $(DEPS) -o $@ $(INCLUDES) $(CCFLAGS_all) $(CCFLAGS) $<

#Linking rule
$(TARGET):$(OBJS)
	$(LD) $(LDFLAGS_$(ARTIFACT_TYPE)) $(TARGET) $(LDFLAGS_all) $(LDFLAGS) $(OBJS) $(LIBS_all) $(LIBS)

#Default target - show usage
.DEFAULT_GOAL := help

help:
	@echo "Simple QNX Cockpit - Cross-platform vehicle dashboard"
	@echo ""
	@echo "Usage:"
	@echo "  make linux      - Build and run on Linux"
	@echo "  make qnx        - Build, deploy and run on QNX target"
	@echo "  make qnx-deploy - Deploy only to QNX target"
	@echo "  make clean      - Clean all builds"
	@echo ""
	@echo "Configuration (QNX):"
	@echo "  TARGET_IP=$(TARGET_IP)"
	@echo "  TARGET_USER=$(TARGET_USER)"
	@echo "  TARGET_PATH=$(TARGET_PATH)"

#Rules section for default compilation and linking
all: $(TARGET)

CLEAN_DIRS := $(shell find build -type d 2>/dev/null || true)
CLEAN_PATTERNS := *.o *.d $(ARTIFACT_NAME_exe) $(ARTIFACT_NAME_shared) $(ARTIFACT_NAME_static)
CLEAN_FILES := $(foreach DIR,$(CLEAN_DIRS),$(addprefix $(DIR)/,$(CLEAN_PATTERNS)))

clean:
	rm -rf build

rebuild: clean all

#QNX target deployment and execution
TARGET_IP ?= 10.1.10.107
TARGET_USER ?= root
TARGET_PATH ?= /tmp

qnx-deploy:
	@which q++ > /dev/null 2>&1 || (echo "Error: QNX compiler not found. Please install QNX Software Development Platform." && exit 1)
	$(MAKE) all PLATFORM=aarch64le
	scp build/aarch64le/cockpit $(TARGET_USER)@$(TARGET_IP):$(TARGET_PATH)/

qnx:
	@which q++ > /dev/null 2>&1 || (echo "Error: QNX compiler not found. Please install QNX Software Development Platform." && exit 1)
	$(MAKE) qnx-deploy PLATFORM=aarch64le
	ssh $(TARGET_USER)@$(TARGET_IP) "cd $(TARGET_PATH) && ./$(ARTIFACT)"

#Linux local execution
linux:
	$(MAKE) all PLATFORM=linux
	./build/linux/cockpit

#Legacy target names for compatibility
deploy: qnx-deploy
run-target: qnx
run-local: linux

#Inclusion of dependencies (object files to source and includes)
-include $(OBJS:%.o=%.d)