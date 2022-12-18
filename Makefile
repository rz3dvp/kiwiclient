#
# Example uses of kiwirecorder.py and kiwifax.py
#

#PY = python
#PY = python2
PY = python3

# set global environment variables KIWI_HOST and KIWI_PORT to the Kiwi you want to work with
ifeq ($(KIWI_HOST)x,x)
    HOST = kiwisdr.local
else
    HOST = $(KIWI_HOST)
endif

ifeq ($(KIWI_PORT)x,x)
    PORT = 8073
else
    PORT = $(KIWI_PORT)
endif

ifeq ($(KIWI_FREQ)x,x)
    FREQ = 10000
else
    FREQ = $(KIWI_FREQ)
endif

KREC = $(PY) kiwirecorder.py

HP = -s $(HOST) -p $(PORT)
H2 = -s $(HOST),$(HOST) -p $(PORT)
H8 = -s $(HOST),$(HOST),$(HOST),$(HOST),$(HOST),$(HOST),$(HOST),$(HOST) -p $(PORT)

F = -f $(FREQ)
F_PB = $F -L -5000 -H 5000


# process control help
UNAME = $(shell uname)
ifeq ($(UNAME),Darwin)
# on OS X (Darwin) there is no "interactive mode" for killall command, so use 'kp' BEFORE 'kill' to check
kp:
	killall -d -KILL Python
kill:
#	killall -v -KILL Python
	killall -v Python
else
kp kill:
	killall -r -i -s KILL Python
endif

ps:
	ps ax | grep -i kiwirecorder


# record WSPR audio to file
#
# "-f" frequency is dial frequency, i.e. WSPR center frequency minus passband center (BFO)
# e.g. 40m: cf = 7040.1, so if pb center = 750 then dial = 7040.1 - 0.750 = 7039.35
# NB: most WSPR programs use a pb center of 1500 Hz, not 750 which we use because we think it's easier to listen to

wspr:
	$(KREC) $(HP) --filename=wspr_40m -f 7039.35 --user=WSPR_40m -m iq -L 600 -H 900 --tlimit=110 --log_level=debug

# multiple connections
wspr2:
	$(KREC) $(HP2) --filename=wspr_40m,wspr_30m -f 7039.35,10139.45 --user=WSPR_40m,WSPR_30m -m iq -L 600 -H 900 --tlimit=110


# DRM
# With the "--ext=DRM" argument kiwirecorder requests the Kiwi to start the DRM extension and send
# decoded DRM audio instead of normal analog audio.
#
# 15785 Funklust
# 3965 Telediffusion de France
# "--ext-test" uses test file built-in to DRM extension

HP_DRM = $(HP)
#HP_DRM = -s websdr.uk -p 8079

F_DRM = $(F_PB)
#F_DRM = -f 15785
#F_DRM = -f 3965
#F_DRM = -f 5555 --ext-test

DRM_COMMON = --mode=drm -L -5000 -H 5000 --user=DRM-test --log-level=info
#DRM_COMMON = --mode=drm -L -5000 -H 5000 --user=DRM-test --log-level=debug
DRM = $(HP_DRM) $(F_DRM) $(DRM_COMMON) --tlimit=15

drm-info:
	@echo HP_DRM = $(HP_DRM)
	@echo F_DRM = $(F_DRM)

# write decoded DRM audio to a file
drm-snd: drm-info
	$(KREC) $(DRM) --tlimit=30 --snd --ext=DRM

snd-wf: drm-info
	$(KREC) $(DRM) --tlimit=15 --snd --wf --z 9 --speed 4 --quiet --wf-png --wf-auto

# show DRM stats (--stats) without writing audio file (--test-mode --quiet)
drm-stats: drm-info
	$(KREC) $(DRM) --tlimit=30 --snd --test-mode --quiet --ext=DRM --stats --log-level=warn

# show DRM stats (--stats) with writing audio file
drm-snd-stats: drm-info
	$(KREC) $(DRM) --tlimit=30 --snd --ext=DRM --stats --log-level=warn

# record Kiwi waterfall to a .png file, manual setup of WF min/max (no DRM decoding involved here)
drm-wf: drm-info
	$(KREC) $(DRM) --tlimit=15 --mode=am --wf --z 9 --speed 4 --quiet --wf-png --mindb -130 --maxdb -60 --wf-auto

# record Kiwi waterfall to a .png file, auto setup of WF min/max (no DRM decoding involved here)
drm-wf-auto: drm-info
	$(KREC) $(DRM) --tlimit=15 --mode=am --wf --z 9 --speed 4 --quiet --wf-png --wf-auto

# record Kiwi audio, waterfall and stats
drm-snd-wf: drm-info
	$(KREC) $(DRM) --tlimit=30 --snd --quiet --wf --z 9 --speed 4 --wf-png --wf-auto --ext=DRM  --stats --log-level=warn


# DRM testing

drm-828:
	$(KREC) $(DRM) -s newdelhi.twrmon.net -f 828 --filename=Delhi.828.12k.iq
drm-1368:
	$(KREC) $(DRM) -s newdelhi.twrmon.net -f 1368 --filename=Delhi.1368.12k.iq
drm-621:
	$(KREC) $(DRM) -s bengaluru.twrmon.net -f 621 --filename=Bengaluru.621.12k.iq
drm-1044:
	$(KREC) $(DRM) -s 182.237.12.150.twrmon.net -f 1044 --filename=Bdq.1044.12k.iq
drm-9620:
#	$(KREC) $(DRM) -s emeraldsdr.ddns.net -f 9620 --filename=AIR.9620.12k.iq --mode=iq --tlimit=10 --log-level=info
#	$(KREC) $(DRM) -s emeraldsdr.ddns.net -f 9620 --filename=AIR.9620.12k.drm --ext=DRM --snd --s-meter=0 --sdt-sec=1 --tlimit=30 --log-level=info --ts
	python3 kiwirecorder.py -s emeraldsdr.ddns.net  -p 8073 -f 9620 -L -5000 -H 5000 --mode=drm --ext=DRM --snd --user=DRM-test --filename=AIR.9620.12k.drm --s-meter=0 --sdt-sec=1 --tlimit=30 --timestamp --log-level=info
drm-5910:
	python3 kiwirecorder.py -s df0twn.dnsuser.de  -p 8073 -f 5910 -L -5000 -H 5000 --mode=drm --ext=DRM --snd --user=DRM-test --filename=RRI.5910.12k.drm --s-meter=0 --sdt-sec=1 --tlimit=30 --timestamp --log-level=info

drm-bug:
#	$(KREC) $(DRM) --tlimit=40 --test-mode --snd --wf --z 5
#	$(KREC) $(DRM) --tlimit=4 --test-mode
#	$(KREC) $(DRM) --tlimit=10 --test-mode --wf --z 5
#	$(KREC) $(DRM) --tlimit=10 --test-mode --ext=DRM --wf --z 5
#	$(KREC) $(DRM) --tlimit=10 --test-mode --ext=DRM
	$(KREC) $(DRM) --tlimit=60 --test-mode --quiet --snd --ext=DRM
#	$(KREC) $(DRM) --tlimit=10 --test-mode --ext=DRM --nolocal


# see if Dream works using a real-mode stream (it does)
# requires a Kiwi in 3-channel mode (20.25 kHz) to accomodate a 10 kHz wide USB passband
dream_real:
	$(KREC) $(HP) -f $(FREQ) -m usb -L 0 -H 10000 --ncomp


# FAX
# has both real and IQ mode decoding

fax:
	$(PY) kiwifax.py $(HP) -f $(FREQ) -F
faxiq:
	$(PY) kiwifax.py $(HP) -f $(FREQ) -F --iq-stream


# Two separate IQ files recording in parallel
HOST_IQ1 = fenu-radio.ddns.net
HOST_IQ2 = southwest.ddns.net

two:
	$(KREC) -s $(HOST_IQ1),$(HOST_IQ2) -p ($PORT) -f 77.5,60 --station=DCF77,MSF -m iq -L -5000 -H 5000


# real mode (non-IQ) file
# Should playback using standard .wav file player

real:
	$(KREC) $(HP) $(F_PB) --tlimit=60
lsb:
	$(KREC) $(HP) -f 7200 -m lsb --tlimit=10 --log-level=debug
resample:
	$(KREC) $(HP) $(F_PB) -r 6000 --tlimit=10
resample_iq:
	$(KREC) $(HP) $(F_PB) -r 6000 -m iq --tlimit=10
ncomp:
	$(KREC) $(HP) $(F_PB) --ncomp
rx8:
#	$(KREC) $(H8) $(F_PB) --launch-delay=15 --socket-timeout=120 -u krec-RX8
	$(KREC) $(H8) $(F_PB) -u krec-RX8
nb:
	$(KREC) $(HP) $F -m usb --tlimit=10 --nb --nb-gate=200 --nb-th=40
2sec:
	$(KREC) $(HP) $(F_PB) -q --log-level=info --dt-sec=2 
debug:
	$(KREC) $(HP) $(F_PB) --tlimit=10 --test-mode --log_level=debug
#	$(KREC) -s ai,kiwi -p 8073,8074 --filename=wwv1,wwv2 -f 10000 --user=wwv1,wwv2 -m am --tlimit=60 --log-level=info
#	$(KREC) -s ai -p 8073 -f 10000 --user=wwv1 -m am --tlimit=60 --log-level=debug
modes:
	$(KREC) $(HP) -m iq  --tlimit=4 --log_level debug
	$(KREC) $(HP) -m sal --tlimit=4 --log_level debug
	$(KREC) $(HP) -m sas --tlimit=4 --log_level debug
	$(KREC) $(HP) -m qam --tlimit=4 --log_level debug
info:
	sox --info *.wav


# frequency offset
#FOFF = -L 470 -H 530 -m cwn --snd --wf --z 14 --speed 2 --quiet --wf-png --wf-auto
FOFF = -L 470 -H 530 -m cwn
#FOFF = -L -100 -H 100 -m iq --snd --wf --z 14 --speed 2 --quiet --wf-png --wf-auto

foff:
#	$(KREC) $(HP) --tlimit=10 --log_level=debug -f 24000.14 $(FOFF)
	$(KREC) $(HP) --tlimit=10 -f 124000.14 $(FOFF)
#	$(KREC) $(HP) --tlimit=10  -f 124000.64 -o 100000 $(FOFF)


# S-meter

s_meter:
sm:
	$(KREC) $(HP) $(F_PB) --s-meter=10
	$(KREC) $(HP) $(F_PB) --s-meter=10 -m iq
s_meter_timed:
smt:
	$(KREC) $(HP) $(F_PB) --s-meter=10 --stats
	$(KREC) $(HP) $(F_PB) --s-meter=10 --ncomp --stats
	$(KREC) $(HP) $(F_PB) --s-meter=10 -m iq --stats

s_meter_stream:
sms:
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=3
#	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=3 --stats --tstamp
#	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=3 --stats --tstamp --sdt-sec=1
s_meter_stream_timed:
smst:
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=5 --stats
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=5 --ncomp --stats
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=5 -m iq --stats

s_meter_stream_timestamps:
smts:
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tlimit=5 --stats --tstamp

s_meter_stream_interval:
smsi:
	$(KREC) $(HP) $(F_PB) --s-meter=0 --tstamp --sdt-sec=1 --stats --log-level=info --dt-sec=4 --snd


# TDoA debugging

tdoa:
	$(PY) -u kiwirecorder.py $(HP) $(F_PB) -m iq --kiwi-wav --kiwi-tdoa --tlimit=10 -u krec-TDoA --log-level=warn


# test reported problem situations

T_MODE = -m usb --ncomp     # "no compression" mode used by wsprdaemon.sh
#T_MODE = -m iq
T_PARAMS = -q --log-level=info $(HP) -u test -f 28124.6 $M -L 1200 -H 1700 --test-mode $(T_MODE)

slots1:
	$(KREC) --station=1 $(T_PARAMS) &
slots2:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
slots4:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
	$(KREC) --station=3 $(T_PARAMS) &
	$(KREC) --station=4 $(T_PARAMS) &
slots6:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
	$(KREC) --station=3 $(T_PARAMS) &
	$(KREC) --station=4 $(T_PARAMS) &
	$(KREC) --station=5 $(T_PARAMS) &
	$(KREC) --station=6 $(T_PARAMS) &
slots8:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
	$(KREC) --station=3 $(T_PARAMS) &
	$(KREC) --station=4 $(T_PARAMS) &
	$(KREC) --station=5 $(T_PARAMS) &
	$(KREC) --station=6 $(T_PARAMS) &
	$(KREC) --station=7 $(T_PARAMS) &
	$(KREC) --station=8 $(T_PARAMS) &
slots12:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
	$(KREC) --station=3 $(T_PARAMS) &
	$(KREC) --station=4 $(T_PARAMS) &
	$(KREC) --station=5 $(T_PARAMS) &
	$(KREC) --station=6 $(T_PARAMS) &
	$(KREC) --station=7 $(T_PARAMS) &
	$(KREC) --station=8 $(T_PARAMS) &
	$(KREC) --station=9 $(T_PARAMS) &
	$(KREC) --station=10 $(T_PARAMS) &
	$(KREC) --station=11 $(T_PARAMS) &
	$(KREC) --station=12 $(T_PARAMS) &
slots14:
	$(KREC) --station=1 $(T_PARAMS) &
	$(KREC) --station=2 $(T_PARAMS) &
	$(KREC) --station=3 $(T_PARAMS) &
	$(KREC) --station=4 $(T_PARAMS) &
	$(KREC) --station=5 $(T_PARAMS) &
	$(KREC) --station=6 $(T_PARAMS) &
	$(KREC) --station=7 $(T_PARAMS) &
	$(KREC) --station=8 $(T_PARAMS) &
	$(KREC) --station=9 $(T_PARAMS) &
	$(KREC) --station=10 $(T_PARAMS) &
	$(KREC) --station=11 $(T_PARAMS) &
	$(KREC) --station=12 $(T_PARAMS) &
	$(KREC) --station=13 $(T_PARAMS) &
	$(KREC) --station=14 $(T_PARAMS) &

no_api_snd:
	$(KREC) $(HP) --no-api $(F_PB) --test-mode --log_level debug --nolocal
no_api_snd_wf:
	$(KREC) $(HP) --snd --wf --no-api --test-mode --log_level debug --nolocal
no_api_wf:
	$(KREC) $(HP) --wf --no-api --user=spaces --log_level debug --nolocal
no_api_user:
	$(KREC) $(HP) --no-api --user=no_api_test --log_level debug --nolocal


# IQ file with GPS timestamps

gps:
	$(KREC) $(HP) -f 77.5  -L -5000 -H 5000 -m iq --station=DCF77 --kiwi-wav --log_level info
gps2:
	$(KREC) $(HP) $F -m iq -L -5000 -H 5000 --kiwi-wav


# IQ file without GPS timestamps
# Should playback using standard .wav file player

iq:
	$(KREC) $(HP) $(F_PB) -m iq --tlimit=10 --log_level info


# ALE 2G testing
P_ALE = -f 2784 -m usb -L 300 -H 2700 --station=ALE --resample 8000 

ale:
	$(KREC) $(HP) $(P_ALE) --log_level debug --tlimit=5
#	$(KREC) $(HP) $(P_ALE) --log_level=debug --tlimit=5 --test-mode --ext ale_2g --snd --wf --z 5


# kiwiclientd
kcd:
#	$(PY) kiwiclientd.py --help
#	$(PY) kiwiclientd.py $(HP) -f 24000 -m usb --snddev="Display Audio" --rigctl-port=6400
#	$(PY) kiwiclientd.py $(HP) -f 24000 -m usb --rigctl-port=6400 --log_level info --tlimit=5
#	$(PY) kiwiclientd.py $(HP) -f 24000 -m iq --rigctl-port=6400 --log_level info --tlimit=5 --if=200
#	$(PY) kiwiclientd.py $(HP) -f 24001.16 -m cwn --rigctl-port=6400 --log_level debug --tlimit=5 
	$(PY) kiwiclientd.py $(HP) -f 24001.66 --pbc -m cwn --enable-rigctl --rigctl-port=6400 --log_level debug --tlimit=5 
#	$(PY) kiwiclientd.py $(HP) -f 24000.7 --pbc -m am -L -500 -H 500 --log_level debug --tlimit=5 
#	$(PY) kiwiclientd.py $(HP) -f 24001.7 -m am -L -500 -H 500 --log_level debug --tlimit=5 


# time stations

BPC_HOST = -s railgun.proxy.kiwisdr.com -p 8073
bpc:
#	$(KREC) $(BPC_HOST) -f 68 -m iq -L 470 -H 530 --fn=BPC_cwn60_iq --tlimit=665 --log_level info
	$(KREC) $(BPC_HOST) -f 68 -m iq -L 470 -H 530 --fn=BPC_cwn60_iq --tlimit=195 --log_level info

#JJY_HOST = -s railgun.proxy.kiwisdr.com -p 8073
JJY_HOST = -s 202.127.177.27 -p 8074
jjy:
	$(KREC) $(JJY_HOST) -f 39.5 -m iq -L 470 -H 530 --fn=JJY_cwn60_iq --tlimit=195 --log_level info

RTZ_HOST = -s irk.proxy.kiwisdr.com -p 8073
rtz:
	$(KREC) $(RTZ_HOST) -f 49.6 -m iq -L 485 -H 515 --fn=RTZ_cwn30_iq --tlimit=195 --log_level info

MSF_HOST = -s stucapon.plus.com -p 8073
msf:
	$(KREC) $(MSF_HOST) -f 59.5 -m iq -L 470 -H 530 --fn=MSF_cwn60_iq --tlimit=15 --log_level info

WWVB_HOST = -s lounix.net -p 8073
wwvb:
	$(KREC) $(WWVB_HOST) -f 59.5 -m iq -L 497 -H 503 --fn=WWVB_cwn6_iq --tlimit=195 --log_level info


# simulate SuperSDR connection
ss:
	$(KREC) $(HP) -f 15000 -m usb --user=SuperSDR-sim --log_level=debug --tlimit=10 --test-mode --wf --z 5 --snd
ssn:
	$(KREC) $(HP) -f 15000 -m usb --user=SuperSDR-sim --log_level=debug --tlimit=10 --test-mode --wf --z 5 --snd --nolocal --pw=up &
	$(KREC) $(HP) -f 15000 -m usb --user=SuperSDR-sim --log_level=debug --tlimit=10 --test-mode --wf --z 5 --snd --nolocal --pw=up &
	$(KREC) $(HP) -f 15000 -m usb --user=SuperSDR-sim --log_level=debug --tlimit=10 --test-mode --wf --z 5 --snd --nolocal --pw=up &


# process waterfall data

wf:
#	$(KREC) --wf $(HP) -f 15000 -z 0 --log_level info -u krec-WF --tlimit=5
	$(KREC) --wf $(HP) -f 5600 -z 10 --log_level info --tlimit=20  --nolocal
#	$(KREC) --wf $(HP) -f 9650 -z 4 --log_level debug -u krec-WF --tlimit=60

wf2:
	$(PY) kiwiwfrecorder.py $(HP) -f $(FREQ) -z 4 --log_level debug -u krec-WF

micro:
#	$(PY) microkiwi_waterfall.py --help
#	$(PY) microkiwi_waterfall.py $(HP)
	$(PY) microkiwi_waterfall.py $(HP) -z 0 -o 0
#	$(PY) microkiwi_waterfall.py $(HP) -z 1 -o 7500
#	$(PY) microkiwi_waterfall.py $(HP) -z 14 -o 7500
#	$(PY) microkiwi_waterfall.py $(HP) -z 0 -o 28000


# stream a Kiwi connection in a "netcat" style fashion

nc:
#	$(PY) kiwi_nc.py $(HP) $(F_PB) -m am --progress --log_level info --tlimit=3
#	$(PY) kiwi_nc.py -s www -m iq -f $(HFDL_FREQ) --agc-yaml fast_agc.yaml --progress --tlimit=3 --log=debug
	$(PY) kiwi_nc.py -s www -m iq -f $(HFDL_FREQ) --agc-decay 100 --progress --tlimit=3 --log=debug

# Use of an HFDL-optimized passband (e.g. "-L 300 -H 2600") is not necessary here
# since dumphfdl does its own filtering. However the Kiwi HFDL extension does have it so you
# don't have to listen to noise and interference from the opposite sideband.
HFDL_HOST = -s stucapon.plus.com -p 8073
HFDL_FREQ = 5720

dumphfdl:
	$(PY) kiwi_nc.py $(HFDL_HOST) -m iq -f $(HFDL_FREQ) --user kiwi_nc:dumphfdl --agc-decay 100 | \
	dumphfdl --iq-file - --sample-rate 12000 --sample-format CS16 --read-buffer-size 9600 \
	--centerfreq $(HFDL_FREQ) $(HFDL_FREQ)

dumphfdl_agc_yaml:
	$(PY) kiwi_nc.py $(HFDL_HOST) -m iq -f $(HFDL_FREQ) --user kiwi_nc:dumphfdl --agc-yaml fast_agc.yaml | \
	dumphfdl --iq-file - --sample-rate 12000 --sample-format CS16 --read-buffer-size 9600 \
	--centerfreq $(HFDL_FREQ) $(HFDL_FREQ)

tun:
	mkfifo /tmp/si /tmp/so
	nc -l localhost 1234 >/tmp/si </tmp/so &
	ssh -f -4 -p 1234 -L 2345:localhost:8073 root@$(HOST) sleep 600 &
	$(PY) kiwi_nc.py $(HP) --log debug --admin </tmp/si >/tmp/so


help h:
	@echo HOST = $(HOST)
	@echo PORT = $(PORT)
	@echo FREQ = $(FREQ)
	@echo
	$(KREC) --help

clean:
	-rm -f *.log *.wav *.png *.npy

clean_dist: clean
	-rm -f *.pyc */*.pyc
