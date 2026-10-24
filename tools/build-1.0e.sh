#!/bin/zsh
# Rebuild the Power-Choice 1.0e distribution disk (v1/disk) from v1/src at
# tag v1.0e with the original Turbo Pascal 5.5.
#
# usage: tools/build-1.0e.sh <tp55.zip> <jwasm> <outdir>
#
#   tp55.zip  Borland's free "antique software" release of Turbo Pascal 5.5
#             (http://altd.embarcadero.com/download/museum/tp55.zip)
#   jwasm     JWasm, an open-source MASM clone, stands in for MASM 5.1
#   outdir    receives the distribution disk: PCHINST.EXE and PCHOICE.DAT
#             (which holds PCHOICE.EXE and PCH_LL.COM)
#
# Needs git, iconv, unzip, unar, python3 and dosbox-x on the PATH.
set -e
TPZIP=${1:A}; JWASM=${2:A}; OUT=${3:A}
REPO=${0:A:h:h}
W=$(mktemp -d)
trap 'rm -rf $W' EXIT

# Sources at v1.0e, converted back to code page 437 for DOS
mkdir -p $W/SRC $W/TP $W/git
git -C $REPO archive v1.0e v1/src | tar -x -C $W/git
for f in $W/git/v1/src/*; do iconv -f UTF-8 -t CP437 $f > $W/SRC/${f:t}; done

# Turbo Pascal 5.5: compiler, runtime library, Graph unit
unzip -q $TPZIP -d $W/tp55
cp $W/tp55/Disk1/{TPC.EXE,TURBO.TPL} $W/TP/
unar -q -D -o $W/arc $W/tp55/Disk2/BGI.ARC
cp $W/arc/GRAPH.TPU $W/TP/

# Resident driver: MASM 5.1 accepted REPZ on STOSW/MOVSW, JWasm wants REP
# (same opcode F3, so the machine code is identical)
LC_ALL=C sed 's/REPZ STOSW/REP  STOSW/; s/REPZ MOVSW/REP  MOVSW/' $W/SRC/PCH_LL.ASM > $W/SRC/PCH_LLB.ASM
$JWASM -q -Zm -bin -Fo$W/SRC/PCH_LL.COM $W/SRC/PCH_LLB.ASM

# Pascal programs, compiled inside DOSBox-X
printf 'cd \\src\r\n' > $W/BUILD.BAT
for p in PCHOICE PCHINST; do
  printf 'c:\\tp\\tpc /M /Uc:\\tp %s.pas >> c:\\build.log\r\n' $p >> $W/BUILD.BAT
done
dosbox-x -silent -nogui -set "sdl output=surface" -set "cpu cycles=max" \
  -c "mount c $W" -c "c:" -c "build.bat" -time-limit 60 >/dev/null 2>&1
tr -d '\r' < $W/BUILD.LOG

# PCHOICE.DAT as written by PREINST.PAS: a file count, then per file a
# 22-byte header (String[4] 'NexT', String[12] name, LongInt length) and
# the data. INFO is a global record reused for every file, so a shorter
# name leaves the tail of the previous one in the header, as in 1990.
python3 -I - $W/SRC $W/PCHOICE.DAT PCHOICE.EXE PCH_LL.COM <<'EOF'
import os, struct, sys
src, dest, *files = sys.argv[1:]
info = bytearray(22)
out = bytearray([len(files)])
for name in files:
    data = open(os.path.join(src, name), 'rb').read()
    info[0:5] = bytes([4]) + b'NexT'
    info[5] = len(name)
    info[6:6 + len(name)] = name.encode()
    info[18:22] = struct.pack('<i', len(data))
    out += info + data
open(dest, 'wb').write(out)
EOF

mkdir -p $OUT
cp $W/SRC/PCHINST.EXE $W/PCHOICE.DAT $OUT/
shasum -a 256 $OUT/*
