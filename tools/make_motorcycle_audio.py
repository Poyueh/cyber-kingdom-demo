"""Original, deterministic crystal-motor synthesis. No external recordings."""
from pathlib import Path
import math, wave, array
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/audio/motorcycle-v001'
RATE=22050
OUT.mkdir(parents=True,exist_ok=True)
for name,seconds in [('drive',2.0),('start',0.65)]:
 samples=array.array('h')
 phase=0.0
 for i in range(round(RATE*seconds)):
  t=i/RATE
  # Integer cycles make the drive bed seamless. Start is a separate short ignition.
  freq=76 if name=='drive' else 52+110*min(1,t/0.35)
  phase+=2*math.pi*freq/RATE
  engine=(.55*math.sin(phase)+.2*math.sin(phase*2)+.12*math.sin(phase*4)+.07*math.sin(phase*7))
  ripple=.85+.15*math.sin(2*math.pi*12*t)
  amplitude=.17 if name=='drive' else .24*min(1,t/.018)*min(1,(seconds-t)/.22)
  samples.append(round(32767*engine*ripple*amplitude))
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(samples.tobytes())
 print(name,len(samples)/RATE)
