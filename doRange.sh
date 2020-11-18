#!/bin/bash

# send pulses, record file, process file

indir='/dev/shm'    # where to store .wav audio files for processing
wd='/home/pi/sonar'
#sf2=$wd/txdat/p24_5p5kHz.wav
#sf1=$wd/txdat/p24_5p1kHz96.wav

#sf1=$wd/txdat/p10_3kHz48.wav
#sf2=$wd/txdat/p10_3kHz48.wav
sf1=$wd/txdat/p10_3kHz48_5.wav
sf2=$wd/txdat/p10_3kHz48_5.wav

# Octave processing function name
ofn=peak1.m

SC=0  # USB sound device number

# remove any previous wav files in ramdisk
#rm /dev/shm/R_*.wav  

# set command-line alsamixer output, input volume
amixer -q -c 1 cset name='Speaker Playback Volume' 100%
amixer -q -c 1 cset name='Mic Capture Volume' 67%


if [ "$#" -lt 1 ]; then
  echo "usage: $0 <cycles> [-start]"
  exit 1
fi

# print CSV column header, if this isn't a continuation of an existing file
if [ "$#" -gt 1 ]; then
  echo "epoch pcnt d1a d1astd d2a d2astd d1b d1bstd d2b d2bstd A11 A12 B21 T1plate T2back T3cplr T4air T5CPU"
fi

dnow=$(date)
echo "# $dnow  Running $1 ranging cycles"

for ((i=0;i<$1;i++))
do
  FILES=$indir/R_*.wav

  # clean out any existing previous wav files
  for f in $FILES; do
    [ -f "$f" ] && rm $f
  done
  sleep 2           # trouble if no pause?

#  t1=$($wd/LM35-read.sh)
#  of1=$($wd/play.py -d $SC $sf1)
  of1=$($wd/play.py $sf1)
#  t2=$($wd/LM35-read.sh)
#  of2=$($wd/play.py -d $SC $sf2)
  of2=$($wd/play.py $sf2)

  # report temperature, then do Vsound process
  # echo "Calling octave with $of1"
  os1=$(/usr/bin/octave -q $wd/$ofn $of1)
  os1r=${os1//[$'\t\r\n']}  # remove any newline chars

  if [ ${#os1r} -gt 9 ]; then # skip if there was no output
    echo $os1r" "$t1
  else
    echo "# error 1"
  fi

  os2=$(/usr/bin/octave -q $wd/$ofn $of2)
  os2r=${os2//[$'\t\r\n']}  # remove any newline chars

  if [ ${#os2r} -gt 9 ]; then # skip if there was no output
    echo $os2r" "$t2
  else
    echo "# error 2"
  fi


  # /home/pi/sonar/play.py -d $dev $pulse  # send out the pulse and record return

done
