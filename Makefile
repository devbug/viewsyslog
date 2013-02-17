include theos/makefiles/common.mk

TOOL_NAME = viewsyslog
viewsyslog_FILES = main.mm
viewsyslog_INSTALL_PATH = /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
