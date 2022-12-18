# GNU Octave code to create a set of pulses for Sonar ranging
# can create frequency sweep (pulse frequency changes in steps)
# J.Beale 25-NOV-2020
#
# sudo apt install octave liboctave-dev
#  ...and then from the Octave command line: 
#     pkg install control -forge
#     pkg install signal -forge

pkg load signal                  # for butter() filter()

# =======================================================
# generate sinewave at given frequency, length, sample rate
function [xt yt] = mkPulse(freq, tdur, fs)
  xt=linspace(0,tdur,fs*tdur);  # time vector
  yt=sin(xt .* (2*pi*freq));
endfunction

# filter data: Butterworth filter with bandpass response
# center frequency, sample rate, input data
function filt = doFilter(freq,fs,data)
 [b,a] = butter(1,[0.5*double(freq)/fs, 2*double(freq)/fs], "bandpass");
 filt = filter(b,a, data);
endfunction

# ============================================================
# writeTx() : write out set of single-cycle pulses into audio file
#  f = pulse carrier frequency
#  pulses = how many separate groups or frames
#  pRep = seconds between groups (length of 1 frame)
#  fout = filename to write WAV data

function writeTx(fStart,fInc,pulses,pRep,tStart,tEnd,fs,fout)
 pSamp = int32(fs*tStart);     # how many initial zero samples
 F = zeros (pSamp, 1, "int16"); # create an all-zero frame
 fset=F;  # create first frame of output waveform
 iMax = 32767;  # maximum int16 amplitude

 for i = 1:pulses
  f = fStart + (i-1) * fInc;  # find frequency of this pulse
  printf("%d , %5.0f\n",i,f);  # DEBUG monitor frequency this pulse
  cycles = 1.5;          # how many cycles at frequency f
  [xt yt] = mkPulse(f,cycles/f,fs);  # single pulse
  wt = int16(iMax*(yt)); # 16-bit signed int words

  pSamp = int32(fs*pRep);
  F = zeros (pSamp, 1, "int16"); # create an all-zero frame
  pOffi = 1;  # starting sample offset within frame
  F(pOffi:pOffi+length(wt)-1) = wt;  # insert pulse into frame

  F1 = doFilter(f,fs,fliplr(F));  # filter reversed pulse
  F = doFilter(f,fs,fliplr(F1));  # filter & reverse again
  F1 = doFilter(f,fs,fliplr(F));  # filter & reverse again
  F = int32(iMax * fliplr(F1) ./ max(abs(F1))); # reverse & normalize to 1.0

  fset=[fset; F];   # add in next pulse frames
 endfor

 pSamp = int32(fs*tEnd);     # how many final zero samples
 F = zeros (pSamp, 1, "int16"); # create an all-zero frame
 fset=[fset;F];  # add final frame

 audiowrite (fout, fset, fs, 'Comment', 'Pulses from makeSweep.m 25-NOV-2020');
endfunction

# ==============================================

fStart = 5000;   # start frequency in Hz
fInc = 100;      # frequency increment per-pulse
fs=48000;        # Tx sample rate in Hz
pulses = 30;     # Tx total pulse count
pRep = 0.15;     # repeat time (seconds between pulses)
# tStart = 0.44 * pRep;  # pulse offset from start of frame
tStart = 0.15;  # delay before first pulse
tEnd = 0.1;     # silence after last pulse frame
fout = "p10_swp5k.wav";  # output filename

writeTx(fStart,fInc,pulses,pRep,tStart,tEnd,fs,fout);  # save WAV file
