#
# SPIM S20 MIPS Simulator.
# Makefile for SPIM.
#
# SPIM is covered by a BSD license.
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

.SUFFIXES:
.SUFFIXES: .cpp .o

#
# The following parameters must be set for the target machine:
#
#

# Path for directory that contains the source of the CPU code:
CPU_DIR = CPU
VPATH = src:$(CPU_DIR)

# Full path for the parent directory of all installed files:
PREFIX = /usr

# Full path for the directory that will hold the exception handler:
EXCEPTION_DIR = $(PREFIX)/share/spim



# SPIM needs flex's -I flag since the scanner is used interactively.
# You can set the -8 flag so that funny characters do not hang the scanner.
MYLEX = flex
LEXFLAGS += -I -8 -o lex.yy.cpp

YACC=bison
YFLAGS += -d --defines=parser_yacc.h --output=parser_yacc.cpp -p yy


# Size of the segments when spim starts up (data segment must be >= 64K).
# (These sizes are fine for most users since SPIM dynamically expands
# the memory as necessary.)
MEM_SIZES = -DTEXT_SIZE=65536 -DDATA_SIZE=131072 -DK_TEXT_SIZE=65536


#
# End of parameters
#


DEFINES = $(MEM_SIZES) -DDEFAULT_EXCEPTION_HANDLER="\"$(EXCEPTION_DIR)/exceptions.s\""
CXX = em++
CXXFLAGS += -I. -I$(CPU_DIR) $(DEFINES) -O2 -Wall -pedantic -Wextra -Wunused -Wno-write-strings -x c++ -std=c++11
LDFLAGS += -lm -O2 --bind\
			--preload-file $(CPU_DIR)/exceptions.s@/usr/share/spim/exceptions.s\
			-s ENVIRONMENT=web \
			-s EXTRA_EXPORTED_RUNTIME_METHODS="['ccall', 'cwrap']"

# lex.yy.cpp is usually compiled with -O to speed it up.

LEXCFLAGS += -O $(CXXFLAGS)


OBJS = spim.o spim-utils.o run.o mem.o inst.o data.o sym-tbl.o parser_yacc.o lex.yy.o \
       syscall.o display-utils.o string-stream.o


spim:   $(OBJS)
	$(CXX) $(OBJS) $(LDFLAGS) -o wasm.js
	sed -i '' 's/throw"getitimer() is not implemented yet"//g' wasm.js
	sed -i '' 's/throw"setitimer() is not implemented yet"//g' wasm.js
	mv wasm.* ../

#

TAGS:	*.cpp *.h *.l *.y
	etags *.l *.y *.cpp *.h


clean:
	rm -f *.o TAGS test.out lex.yy.cpp parser_yacc.cpp parser_yacc.h y.output ../wasm.*


.PHONY: clean

#
# Dependences not handled well by makedepend:
#


parser_yacc.h: parser_yacc.cpp

parser_yacc.cpp: $(CPU_DIR)/parser.y
	$(YACC) $(YFLAGS) $(CPU_DIR)/parser.y

parser_yacc.o: parser_yacc.cpp
	$(CXX) $(CXXFLAGS) $(YCFLAGS) -c parser_yacc.cpp


lex.yy.cpp: $(CPU_DIR)/scanner.l
	$(MYLEX) $(LEXFLAGS) $(CPU_DIR)/scanner.l

lex.yy.o: lex.yy.cpp
	$(CXX) $(LEXCFLAGS) -c lex.yy.cpp


#
# DO NOT DELETE THIS LINE -- make depend depends on it.

data.o: $(CPU_DIR)/spim.h
data.o: $(CPU_DIR)/string-stream.h
data.o: $(CPU_DIR)/spim-utils.h
data.o: $(CPU_DIR)/inst.h
data.o: $(CPU_DIR)/reg.h
data.o: $(CPU_DIR)/mem.h
data.o: $(CPU_DIR)/sym-tbl.h
data.o: $(CPU_DIR)/parser.h
data.o: $(CPU_DIR)/run.h
data.o: $(CPU_DIR)/data.h
display-utils.o: $(CPU_DIR)/spim.h
display-utils.o: $(CPU_DIR)/string-stream.h
display-utils.o: $(CPU_DIR)/spim-utils.h
display-utils.o: $(CPU_DIR)/inst.h
display-utils.o: $(CPU_DIR)/data.h
display-utils.o: $(CPU_DIR)/reg.h
display-utils.o: $(CPU_DIR)/mem.h
display-utils.o: $(CPU_DIR)/run.h
display-utils.o: $(CPU_DIR)/sym-tbl.h
dump_ops.o: $(CPU_DIR)/op.h
inst.o: $(CPU_DIR)/spim.h
inst.o: $(CPU_DIR)/string-stream.h
inst.o: $(CPU_DIR)/spim-utils.h
inst.o: $(CPU_DIR)/inst.h
inst.o: $(CPU_DIR)/reg.h
inst.o: $(CPU_DIR)/mem.h
inst.o: $(CPU_DIR)/sym-tbl.h
inst.o: $(CPU_DIR)/parser.h
inst.o: $(CPU_DIR)/scanner.h
inst.o: parser_yacc.h
inst.o: $(CPU_DIR)/data.h
inst.o: $(CPU_DIR)/op.h
mem.o: $(CPU_DIR)/spim.h
mem.o: $(CPU_DIR)/string-stream.h
mem.o: $(CPU_DIR)/spim-utils.h
mem.o: $(CPU_DIR)/inst.h
mem.o: $(CPU_DIR)/reg.h
mem.o: $(CPU_DIR)/mem.h
run.o: $(CPU_DIR)/spim.h
run.o: $(CPU_DIR)/string-stream.h
run.o: $(CPU_DIR)/spim-utils.h
run.o: $(CPU_DIR)/inst.h
run.o: $(CPU_DIR)/reg.h
run.o: $(CPU_DIR)/mem.h
run.o: $(CPU_DIR)/sym-tbl.h
run.o: parser_yacc.h
run.o: $(CPU_DIR)/syscall.h
run.o: $(CPU_DIR)/run.h
spim-utils.o: $(CPU_DIR)/spim.h
spim-utils.o: $(CPU_DIR)/string-stream.h
spim-utils.o: $(CPU_DIR)/spim-utils.h
spim-utils.o: $(CPU_DIR)/inst.h
spim-utils.o: $(CPU_DIR)/data.h
spim-utils.o: $(CPU_DIR)/reg.h
spim-utils.o: $(CPU_DIR)/mem.h
spim-utils.o: $(CPU_DIR)/scanner.h
spim-utils.o: $(CPU_DIR)/parser.h
spim-utils.o: parser_yacc.h
spim-utils.o: $(CPU_DIR)/run.h
spim-utils.o: $(CPU_DIR)/sym-tbl.h
string-stream.o: $(CPU_DIR)/spim.h
string-stream.o: $(CPU_DIR)/string-stream.h
sym-tbl.o: $(CPU_DIR)/spim.h
sym-tbl.o: $(CPU_DIR)/string-stream.h
sym-tbl.o: $(CPU_DIR)/spim-utils.h
sym-tbl.o: $(CPU_DIR)/inst.h
sym-tbl.o: $(CPU_DIR)/reg.h
sym-tbl.o: $(CPU_DIR)/mem.h
sym-tbl.o: $(CPU_DIR)/data.h
sym-tbl.o: $(CPU_DIR)/parser.h
sym-tbl.o: $(CPU_DIR)/sym-tbl.h
sym-tbl.o: parser_yacc.h
syscall.o: $(CPU_DIR)/spim.h
syscall.o: $(CPU_DIR)/string-stream.h
syscall.o: $(CPU_DIR)/inst.h
syscall.o: $(CPU_DIR)/reg.h
syscall.o: $(CPU_DIR)/mem.h
syscall.o: $(CPU_DIR)/sym-tbl.h
syscall.o: $(CPU_DIR)/syscall.h
lex.yy.o: $(CPU_DIR)/spim.h
lex.yy.o: $(CPU_DIR)/string-stream.h
lex.yy.o: $(CPU_DIR)/spim-utils.h
lex.yy.o: $(CPU_DIR)/inst.h
lex.yy.o: $(CPU_DIR)/reg.h
lex.yy.o: $(CPU_DIR)/sym-tbl.h
lex.yy.o: $(CPU_DIR)/parser.h
lex.yy.o: $(CPU_DIR)/scanner.h
lex.yy.o: parser_yacc.h
lex.yy.o: $(CPU_DIR)/op.h
spim.o: $(CPU_DIR)/spim.h
spim.o: $(CPU_DIR)/string-stream.h
spim.o: $(CPU_DIR)/spim-utils.h
spim.o: $(CPU_DIR)/inst.h
spim.o: $(CPU_DIR)/reg.h
spim.o: $(CPU_DIR)/mem.h
spim.o: $(CPU_DIR)/parser.h
spim.o: $(CPU_DIR)/sym-tbl.h
spim.o: $(CPU_DIR)/scanner.h
spim.o: parser_yacc.h
parser_yacc.o: $(CPU_DIR)/spim.h
parser_yacc.o: $(CPU_DIR)/string-stream.h
parser_yacc.o: $(CPU_DIR)/spim-utils.h
parser_yacc.o: $(CPU_DIR)/inst.h
parser_yacc.o: $(CPU_DIR)/reg.h
parser_yacc.o: $(CPU_DIR)/mem.h
parser_yacc.o: $(CPU_DIR)/sym-tbl.h
parser_yacc.o: $(CPU_DIR)/data.h
parser_yacc.o: $(CPU_DIR)/scanner.h
parser_yacc.o: $(CPU_DIR)/parser.h
