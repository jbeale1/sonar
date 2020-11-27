# testing sonar ranging using cross-correlation algorithm
# J.Beale 26-Nov-2020

# length(R) = length(yraw)*2 -1
# length(yraw): 213600

pkg load signal

#infile='R_1606435555_good.wav';
#infile='R_1606435132_good.wav';
#infile='R_1606456374.wav';
#infile='R_1606456140.wav';
#infile='R_1606459045.wav';

arg_list = argv ();              # command-line inputs to this function
infile = arg_list{1};  # read input filename from cmd line

# ======================================================
[yraw1, fs1] = audioread(infile);
printf("File: %s  ",infile);
# plot(yraw);
# axis("tight");

pulses = 21;  # how many pulses in entire data set
gLen = 0.0623; # length of 1 full return, in seconds
pRep = 0.200;  # seconds between Tx pulses
tLead = 0.000125;  # lead time included before Tx threshold point
txWin = 0.000875;  # tight window on 1 Tx pulse
#txWin = 0.000875*0.7;  # tight window on 1 Tx pulse
txWin2 = 0.004167; # larger window around Tx pulse
rOff2 = 0.03125;  # seconds offset for 2nd reflection (1500 @ 48k)
iTxTh = 0.1;  # initial Tx search threshold amplitude
p.p=8;  # resampling parameters
p.q=1;

# -----------------------

rfac = int32(p.p/p.q);          # integer resample factor
fs = fs1 * (p.p/p.q);           # sample rate of resampled waveform
yraw2 = resample(yraw1,p.p,p.q);       # upsample input waveform

fhp =  6200;     # prefilter: highpass frequency shoulder in Hz
[b,a] = butter(2,double(fhp)/fs, "high");  # highpass Btwth filter
yraw = filter(b,a, yraw2);  # do the filter process

# -----------------------------------------------------
ilen = int32(txWin * fs); # samples in one Tx pulse (42 @ 48k)

iRep = int32(pRep * fs);  # samples between Tx pulses

[pkV idxV] = max(max(yraw,0));  # find highest (Tx) peak
printf("Peak = %5.4f TxWin=%d OV=%dx , ",pkV,ilen,p.p); # DEBUG check values

# find next Tx pulse: first element above iTxTh threshold
tStart = find(yraw > iTxTh,1); # first elem above threshold

if isempty(tStart)  # have we run out of Tx peaks in input data?
   printf("Error: Tx signal not found.\n");
#     break
endif

i0 = tStart - int32(tLead*fs); # now back off tLead seconds from thr.
# i0 =  10581;   # MAGIC: offset to start of Tx pulse #1

f1 = yraw(i0:i0+ilen);  # tight window on one Tx pulse
#plot(f1);  # show one Tx pulse alone

[R,lag] = xcorr(yraw, f1);  # cross-correlation finds best match

# plot(R);  # show x-corr across entire raw return
b1 = length(yraw) + i0;
boff = gLen * fs;  # (2993 samples, maybe too big?)

for setNum = 1:pulses
  r1 = R(b1:b1+boff);  # show a single Tx,R1,R2,R3 group
  #plot(r1);  # show just one tx & echo pulse

  iWin2 = int32(txWin2 * fs); # 200 @ 48k
  r2 = R(b1:b1+iWin2);  # just the Tx pulse
  [xpk, xipk] = max(r2);  # Tx peak +correlation position
  txWidth = iWin2;            # samples containing full Tx pulse
  r2r = r1(txWidth-1:end);  # one return, but without Tx pulse
  [rpk, ripk] = max(r2r);   # Rx peak +correlation
  sDelta = (ripk + txWidth) - xipk;  # off-by-one error?

  rcOff = int32(rOff2 * fs); # sample offset to leave just 2nd reflection
  # rcOff = 1500;        # sample offset to leave just 2nd reflection
  r1c = r1(rcOff:end);  # just the 2nd reflection
  #plot(r1c);  # show just 2nd refl.
  [rcpk, rcipk] = max(r1c);
  sDeltaC = (rcipk + rcOff-1) - xipk; # offset to 2nd refl.

  dat11(setNum) = sDelta;
  dat12(setNum) = sDeltaC;
  printf("%d, %d, %d , %d\n",setNum, b1, sDelta, sDeltaC); # DEBUG

     # Start of next group
  b1 += iRep; # 233727 start of 2nd group in R() xcorr data
endfor

R1avg = mean(dat11); # avg counts between Tx & Rx(1)
R1std = std(dat11);
R2avg = mean(dat12); # avg counts between Tx & Rx(2)
R2std = std(dat12);
# printf("---------\n");
# printf("R1 avg, R1 std, R2 avg, R2 std\n");
# printf("%5.1f , %5.2f , %5.1f, %5.2f\n",R1avg,R1std,R2avg,R2std);
Vs = 340.08;  # assumed speed of sound, m/s
r1a=(R1avg / (2*fs))*Vs;
r1s=1E3*(R1std / (2*fs))*Vs;
r2a=(R2avg / (4*fs))*Vs;
r2s=1E3*(R2std / (4*fs))*Vs;
printf("%7.6f m , %5.3f mm, %7.6f m, %5.3f mm\n",r1a,r1s,r2a,r2s);
# ============================================================

#{
File: R_1606459045.wav  Peak = 0.7000 TxWin=336 OV=8x
1, 1792715, 6925 , 13858
2, 1869515, 6925 , 13858
3, 1946315, 6926 , 13858
4, 2023115, 6925 , 13856
5, 2099915, 6925 , 13857
6, 2176715, 6925 , 13857
7, 2253515, 6925 , 13857
8, 2330315, 6925 , 13856
9, 2407115, 6925 , 13857
10, 2483915, 6924 , 13856
11, 2560715, 6925 , 13856
12, 2637515, 6925 , 13856
13, 2714315, 6924 , 13855
14, 2791115, 6924 , 13855
15, 2867915, 6924 , 13855
16, 2944715, 6925 , 13856
17, 3021515, 6925 , 13856
18, 3098315, 6925 , 13857
19, 3175115, 6925 , 13857
20, 3251915, 6925 , 13857
21, 3328715, 6924 , 13856
3.066392 m , 0.227 mm, 3.067910 m, 0.206 mm

File: R_1606460658.wav  Peak = 0.7024 TxWin=336 OV=8x
1, 1791177, 6924 , 13856
2, 1867977, 6925 , 13857
3, 1944777, 6924 , 13856
4, 2021577, 6925 , 13856
5, 2098377, 6925 , 13856
6, 2175177, 6924 , 13855
7, 2251977, 6924 , 13855
8, 2328777, 6924 , 13855
9, 2405577, 6924 , 13855
10, 2482377, 6924 , 13855
11, 2559177, 6924 , 13855
12, 2635977, 6924 , 13855
13, 2712777, 6924 , 13855
14, 2789577, 6924 , 13855
15, 2866377, 6924 , 13855
16, 2943177, 6924 , 13855
17, 3019977, 6924 , 13855
18, 3096777, 6924 , 13855
19, 3173577, 6924 , 13855
20, 3250377, 6924 , 13855
21, 3327177, 6924 , 13855
3.066097 m , 0.159 mm, 3.067647 m, 0.124 mm
#}
