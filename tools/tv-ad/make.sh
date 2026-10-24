#!/bin/zsh
# Make the Power-Choice TV spot (docs/tv-ad/powerchoice-ad.mp4).
# usage: tools/tv-ad/make.sh <font.bin> <out.mp4>
# Needs macOS (say, voices "Reed" and "Fred"), ffmpeg, python3 with numpy
# and Pillow. font.bin is the VGA font dumped by tools/scrdump.asm.
set -e
D=${0:A:h}
REPO=${D:h:h}
W=$(mktemp -d)
trap 'rm -rf $W' EXIT
mkdir $W/voice
while IFS='|' read -r name voice text; do
  say -v "$voice" -o $W/voice/$name.aiff "$text"
  ffmpeg -loglevel error -y -i $W/voice/$name.aiff -ar 44100 -ac 1 $W/voice/$name.wav
done <<'LINES'
l1|Reed (English (US))|Are you tired of dealing with DOS commands?
l2|Fred|Bad command, or file name.
l3|Reed (English (US))|Tired of the menu you have now?
l4|Reed (English (US))|Then get with the program... FAST!
l5|Reed (English (US))|Power-Choice! The ultimate menu system for PCs.
l6|Reed (English (US))|All your PC programs, just one keystroke away.
l7|Reed (English (US))|Easy installation. Password protection. A clock, and a screen saver.
l8|Reed (English (US))|Only twenty-nine ninety-five!
l9|Reed (English (US))|Order now, from Softwhere Associates. The bottom line, in quality software!
LINES
python3 $D/audio.py $W/voice $W/soundtrack.wav
python3 $D/ad.py $REPO ${1:A} $W/soundtrack.wav ${2:A}
