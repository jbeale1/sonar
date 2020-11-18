# GNU Octave code to create a set of pulses for Sonar ranging
# J.Beale 18-NOV-2020

pkg load signal                  # for butter() filter()


# =======================================================
# generate sinewave at given frequency, length, samplerate
function [xt yt] = mkPulse(freq, tdur, fs)
  xt=linspace(0,tdur,fs*tdur);  # time vector
  yt=sin(xt .* (2*pi*freq));
endfunction

# filter data
function filt = doFilter(freq,fs,data)
   # create Butterworth filter with bandpass response
 [b,a] = butter(1,[0.5*double(freq)/fs, 2*double(freq)/fs], "bandpass");
 filt = filter(b,a, data);
endfunction

# ============================================================
# writeTx() : write out set of single-cycle pulses into audio file
#  f = pulse carrier frequency
#  pulses = how many separate groups or frames
#  pRep = seconds between groups (length of 1 frame)
#  fout = filename to write WAV data

function writeTx(f,pulses,pRep,pOff,fs,fout)
  cycles = 1.5;          # how many cycles at frequency f
  [xt yt] = mkPulse(f,cycles/f,fs);  # single pulse
  wt = int16(32767*(yt)); # 16-bit signed int words

  pSamp = int32(fs*pRep);
  F0 = zeros (pSamp, 1, "int16"); # all-zero frame
  F = F0;  # frame to insert a pulse in
  pOffi = pOff*fs;
  F(pOffi:pOffi+length(wt)-1) = wt;  # insert pulse into frame
  set=F;  # create first pulse in output waveform
  for i = 2:pulses
    set=[set; F];   # add in this many pulse frames
  endfor
  # set=[set; F0]; # zero frame at end to allow time for echo
  fset = doFilter(f,fs,fliplr(set));  # filter reversed pulse
  set = doFilter(f,fs,fliplr(fset));  # filter & reverse again
  fset = doFilter(f,fs,fliplr(set));  # filter & reverse again
  set = fliplr(fset);                 # just reverse
  
  fset = set ./ max(abs(set));   # normalize amplitude to 1.0
  audiowrite (fout, fset, fs, 'Comment', '10 pulses at 4 kHz');
endfunction
# ==============================================

f = 4000;        # Tx pulse frequency in Hz
fs=48000;        # Tx sample rate in Hz
pCount = 10;     # Tx total pulse count
pRep = 1.0;      # seconds between groups
pOff = 0.44;     # seconds offset from start of frame
writeTx(f,pCount,pRep, pOff,fs,"p10_4kHz48.wav");
