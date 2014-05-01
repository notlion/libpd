UNAME = $(shell uname)
SOLIB_PREFIX = lib

ifeq ($(UNAME), Darwin)  # Mac
  SOLIB_EXT = dylib
  PDNATIVE_SOLIB_EXT = jnilib
  PDNATIVE_PLATFORM = mac
  PDNATIVE_ARCH = 
  PLATFORM_CFLAGS = -DHAVE_LIBDL -O3 -arch x86_64 -arch i386 -g \
    -I/System/Library/Frameworks/JavaVM.framework/Headers
  LDFLAGS = -arch x86_64 -arch i386 -dynamiclib -ldl
  CSHARP_LDFLAGS = $(LDFLAGS)
  JAVA_LDFLAGS = -framework JavaVM $(LDFLAGS)
else
  ifeq ($(OS), Windows_NT)  # Windows, use Mingw
    CC = gcc
    SOLIB_EXT = dll
    SOLIB_PREFIX = 
    PDNATIVE_PLATFORM = windows
    PDNATIVE_ARCH = $(shell $(CC) -dumpmachine | sed -e 's,-.*,,' -e 's,i[3456]86,x86,' -e 's,amd64,x86_64,')
    PLATFORM_CFLAGS = -DWINVER=0x502 -DWIN32 -D_WIN32 -DPD_INTERNAL -O3 \
      -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/win32"
    MINGW_LDFLAGS = -shared -lws2_32 -lkernel32
    LDFLAGS = $(MINGW_LDFLAGS) -Wl,--output-def=libs/libpd.def \
      -Wl,--out-implib=libs/libpd.lib
    CSHARP_LDFLAGS = $(MINGW_LDFLAGS) -Wl,--output-def=libs/libpdcsharp.def \
      -Wl,--out-implib=libs/libpdcsharp.lib
    JAVA_LDFLAGS = $(MINGW_LDFLAGS) -Wl,--kill-at
  else  # Assume Linux
    SOLIB_EXT = so
    PDNATIVE_PLATFORM = linux
    PDNATIVE_ARCH = $(shell $(CC) -dumpmachine | sed -e 's,-.*,,' -e 's,i[3456]86,x86,' -e 's,amd64,x86_64,')
    JAVA_HOME ?= /usr/lib/jvm/default-java
    PLATFORM_CFLAGS = -DHAVE_LIBDL -Wno-int-to-pointer-cast \
      -Wno-pointer-to-int-cast -fPIC -I"$(JAVA_HOME)/include" \
      -I"$(JAVA_HOME)/include/linux" -O3
    LDFLAGS = -shared -ldl -Wl,-Bsymbolic
    CSHARP_LDFLAGS = $(LDFLAGS)
    JAVA_LDFLAGS = $(LDFLAGS)
  endif
endif

PDNATIVE_SOLIB_EXT ?= $(SOLIB_EXT)

PD_FILES = \
	src/pure-data/src/d_arithmetic.c src/pure-data/src/d_array.c src/pure-data/src/d_ctl.c \
	src/pure-data/src/d_dac.c src/pure-data/src/d_delay.c src/pure-data/src/d_fft.c \
	src/pure-data/src/d_fft_mayer.c src/pure-data/src/d_fftroutine.c \
	src/pure-data/src/d_filter.c src/pure-data/src/d_global.c src/pure-data/src/d_math.c \
	src/pure-data/src/d_misc.c src/pure-data/src/d_osc.c src/pure-data/src/d_resample.c \
	src/pure-data/src/d_soundfile.c src/pure-data/src/d_ugen.c \
	src/pure-data/src/g_all_guis.c src/pure-data/src/g_array.c src/pure-data/src/g_bang.c \
	src/pure-data/src/g_canvas.c src/pure-data/src/g_editor.c src/pure-data/src/g_graph.c \
	src/pure-data/src/g_guiconnect.c src/pure-data/src/g_hdial.c \
	src/pure-data/src/g_hslider.c src/pure-data/src/g_io.c src/pure-data/src/g_mycanvas.c \
	src/pure-data/src/g_numbox.c src/pure-data/src/g_readwrite.c \
	src/pure-data/src/g_rtext.c src/pure-data/src/g_scalar.c src/pure-data/src/g_template.c \
	src/pure-data/src/g_text.c src/pure-data/src/g_toggle.c src/pure-data/src/g_traversal.c \
	src/pure-data/src/g_vdial.c src/pure-data/src/g_vslider.c src/pure-data/src/g_vumeter.c \
	src/pure-data/src/m_atom.c src/pure-data/src/m_binbuf.c src/pure-data/src/m_class.c \
	src/pure-data/src/m_conf.c src/pure-data/src/m_glob.c src/pure-data/src/m_memory.c \
	src/pure-data/src/m_obj.c src/pure-data/src/m_pd.c src/pure-data/src/m_sched.c \
	src/pure-data/src/s_audio.c src/pure-data/src/s_audio_dummy.c \
	src/pure-data/src/s_file.c src/pure-data/src/s_inter.c \
	src/pure-data/src/s_loader.c src/pure-data/src/s_main.c src/pure-data/src/s_path.c \
	src/pure-data/src/s_print.c src/pure-data/src/s_utf8.c src/pure-data/src/x_acoustics.c \
	src/pure-data/src/x_arithmetic.c src/pure-data/src/x_array.c src/pure-data/src/x_connective.c \
	src/pure-data/src/x_gui.c src/pure-data/src/x_interface.c src/pure-data/src/x_list.c \
	src/pure-data/src/x_midi.c src/pure-data/src/x_misc.c src/pure-data/src/x_net.c \
	src/pure-data/src/x_scalar.c src/pure-data/src/x_text.c src/pure-data/src/x_time.c \
	src/libpd_wrapper/s_libpdmidi.c src/libpd_wrapper/x_libpdreceive.c \
	src/libpd_wrapper/z_hooks.c src/libpd_wrapper/z_libpd.c 

# object files which are somehow generated but not from sources listed above,
# there is probably a better fix but this works for now
PD_EXTRA_OBJS = \
	src/pure-data/src/d_fft_fftsg.o src/pure-data/src/d_fft_fftw.o \
	src/pure-data/src/d_fftsg_h.o src/pure-data/src/x_qlist.o

PDJAVA_JAR_CLASSES = \
	java/org/puredata/core/PdBase.java \
	java/org/puredata/core/NativeLoader.java \
	java/org/puredata/core/PdListener.java \
	java/org/puredata/core/PdMidiListener.java \
	java/org/puredata/core/PdMidiReceiver.java \
	java/org/puredata/core/PdReceiver.java \
	java/org/puredata/core/utils/IoUtils.java \
	java/org/puredata/core/utils/PdDispatcher.java

JNI_FILE = libpd_wrapper/util/ringbuffer.c libpd_wrapper/util/z_queued.c \
	jni/z_jni_plain.c
JNIH_FILE = jni/z_jni.h
JAVA_BASE = java/org/puredata/core/PdBase.java
LIBPD = libs/libpd.$(SOLIB_EXT)
PDCSHARP = libs/libpdcsharp.$(SOLIB_EXT)

PDJAVA_BUILD = java-build
PDJAVA_DIR = $(PDJAVA_BUILD)/org/puredata/core/natives/$(PDNATIVE_PLATFORM)/$(PDNATIVE_ARCH)/
PDJAVA_NATIVE = $(PDJAVA_DIR)/$(SOLIB_PREFIX)pdnative.$(PDNATIVE_SOLIB_EXT)
PDJAVA_JAR = libs/libpd.jar

CFLAGS = -DPD -DHAVE_UNISTD_H -DUSEAPI_DUMMY -I./src/pure-data/src \
         -I./src/libpd_wrapper -I./src/libpd_wrapper/util $(PLATFORM_CFLAGS)

.PHONY: libpd csharplib javalib clean clobber

libpd: $(LIBPD)

$(LIBPD): ${PD_FILES:.c=.o}
	$(CC) -o $(LIBPD) $^ $(LDFLAGS) -lm -lpthread 

javalib: $(JNIH_FILE) $(PDJAVA_JAR)

$(JNIH_FILE): $(JAVA_BASE)
	javac -classpath java $^
	javah -o $@ -classpath java org.puredata.core.PdBase

$(PDJAVA_NATIVE): ${PD_FILES:.c=.o} ${JNI_FILE:.c=.o}
	mkdir -p $(PDJAVA_DIR)
	$(CC) -o $(PDJAVA_NATIVE) $^ -lm -lpthread $(JAVA_LDFLAGS) 
	cp $(PDJAVA_NATIVE) libs/

$(PDJAVA_JAR): $(PDJAVA_NATIVE) $(PDJAVA_JAR_CLASSES)
	javac -d $(PDJAVA_BUILD) $(PDJAVA_JAR_CLASSES)
	jar -cvf $(PDJAVA_JAR) -C $(PDJAVA_BUILD) org/puredata/

csharplib: $(PDCSHARP)

$(PDCSHARP): ${PD_FILES:.c=.o}
	gcc -o $(PDCSHARP) $^ $(CSHARP_LDFLAGS) -lm -lpthread

clean:
	rm -f ${PD_FILES:.c=.o} ${PD_EXTRA_OBJS} ${JNI_FILE:.c=.o}

clobber: clean
	rm -f $(LIBPD) $(PDCSHARP) $(PDJAVA_NATIVE) $(PDJAVA_JAR)
	rm -f libs/`basename $(PDJAVA_NATIVE)`
	rm -rf $(PDJAVA_BUILD)
