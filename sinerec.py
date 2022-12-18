#!/usr/bin/env python3

"""Generate a sine, send it out, and also record input to a file.
   Based on code examples at github.com/spatialaudio/python-sounddevice/
   in particular play_sine.py, wire.py, and rec_unlimited.py

   Loopback test with 1 kHz tone for Pi Codec Zero (ok except for clicks and glitches)
   sinerec.py loop1k.wav 1000 --blocksize 22000 --samplerate 44100 --amplitude 0.40

   J.Beale 2022-12-18
"""
import argparse
import tempfile
import queue
import sys

import sounddevice as sd
import soundfile as sf
import numpy  # Make sure NumPy is loaded before it is used in the callback
assert numpy  # avoid "imported but unused" message (W0611)


def int_or_str(text):
    """Helper function for argument parsing."""
    try:
        return int(text)
    except ValueError:
        return text


parser = argparse.ArgumentParser(add_help=False)
parser.add_argument(
    '-l', '--list-devices', action='store_true',
    help='show list of audio devices and exit')
args, remaining = parser.parse_known_args()
if args.list_devices:
    print(sd.query_devices())
    parser.exit(0)
parser = argparse.ArgumentParser(
    description=__doc__,
    formatter_class=argparse.RawDescriptionHelpFormatter,
    parents=[parser])
parser.add_argument(
    'filename', nargs='?', metavar='FILENAME',
    help='audio file to store recording to')
parser.add_argument(
    '-i', '--input-device', type=int_or_str,
    help='input device (numeric ID or substring)')
parser.add_argument(
    '-o', '--output-device', type=int_or_str,
    help='output device (numeric ID or substring)')
parser.add_argument(
    '-r', '--samplerate', type=int, help='sampling rate')
parser.add_argument('--dtype', help='audio data type')
parser.add_argument('--blocksize', type=int, help='block size')
parser.add_argument(
    '-c', '--channels', type=int, default=1, help='number of input channels')
parser.add_argument(
    '-t', '--subtype', type=str, help='sound file subtype (e.g. "PCM_24")')
parser.add_argument('--latency', type=float, help='latency in seconds')
parser.add_argument(
    '-a', '--amplitude', type=float, default=0.2,
    help='amplitude (default: %(default)s)')
parser.add_argument(
    'frequency', nargs='?', metavar='FREQUENCY', type=float, default=500,
    help='frequency in Hz (default: %(default)s)')
args = parser.parse_args(remaining)

q = queue.Queue()


def callback(indata, outdata, frames, time, status):
    global start_idx
    if status:
        print(status)
    # outdata[:] = indata
    q.put(indata.copy())

    t = (start_idx + numpy.arange(frames)) / samplerate
    t = t.reshape(-1, 1)
    outdata[:] = args.amplitude * numpy.sin(2 * numpy.pi * args.frequency * t)
    start_idx += frames


start_idx = 0

try:
    samplerate = int(sd.query_devices(args.input_device, 'output')['default_samplerate'])
    if args.samplerate is None:
        device_info = sd.query_devices(args.input_device, 'input')
        # soundfile expects an int, sounddevice provides a float:
        args.samplerate = int(device_info['default_samplerate'])
    if args.filename is None:
        args.filename = tempfile.mktemp(prefix='delme_rec_unlimited_',
                                        suffix='.wav', dir='')

    # Make sure the file is opened before recording anything:
    with sf.SoundFile(args.filename, mode='x', samplerate=args.samplerate,
                      channels=args.channels, subtype=args.subtype) as file:

        with sd.Stream(device=(args.input_device, args.output_device),
                   samplerate=args.samplerate, blocksize=args.blocksize,
                   dtype=args.dtype, latency=args.latency,
                   channels=args.channels, callback=callback):

            print('#' * 80)
            print('press Ctrl+C to stop the recording')
            print('#' * 80)
            while True:
                file.write(q.get())
except KeyboardInterrupt:
    print('\nRecording finished: ' + repr(args.filename))
    parser.exit(0)
except Exception as e:
    parser.exit(type(e).__name__ + ': ' + str(e))
