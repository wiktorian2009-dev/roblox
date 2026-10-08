"""Replace only the rejected fall cue with edited CC0 recorded air; preserve all later master samples."""
import pathlib, sys, subprocess, wave, json, shutil, zipfile, hashlib
import numpy as np
sys.path.insert(0,r'C:\Users\wikto\Documents\Codex\2026-09-29\ca\work\audio-tools')
import imageio_ffmpeg
ROOT=pathlib.Path(r'C:\Users\wikto\Desktop\Roblox Gra')
A=ROOT/'assets/audio/intro'; O=ROOT/'outputs/IntroSound20260930'; V=O/'v2'; V.mkdir(exist_ok=True)
S=A/'sources'; F=imageio_ffmpeg.get_ffmpeg_exe(); SR=48000; N=round(1.5*SR)
def run(args):return subprocess.run([F,'-hide_banner','-loglevel','error','-y']+args,check=True,capture_output=True)
def decode(p,filters=None):
    args=['-i',str(p)]
    if filters:args+=['-af',filters]
    r=run(args+['-ac','2','-ar',str(SR),'-f','f32le','-'])
    return np.frombuffer(r.stdout,'<f4').astype(float).reshape(-1,2)
def wavread(p):
    with wave.open(str(p)) as f:
        assert f.getframerate()==SR and f.getnchannels()==2 and f.getsampwidth()==2
        return np.frombuffer(f.readframes(f.getnframes()),'<i2').astype(float).reshape(-1,2)/32768
def write(p,a):
    assert np.isfinite(a).all() and np.max(np.abs(a))<.99
    with wave.open(str(p),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR)
        f.writeframes(np.rint(a*32768).astype('<i2').tobytes())
def norm(a,rms):return a*rms/max(np.sqrt(np.mean(a*a)),1e-8)
def fade(a,attack=.08,release=.07):
    a=a.copy(); k=round(attack*SR);q=round(release*SR)
    a[:k]*=np.sin(np.linspace(0,np.pi/2,k))[:,None]**2
    a[-q:]*=np.cos(np.linspace(0,np.pi/2,q))[:,None]**2
    return a
def band(a,lo,hi):
    f=np.fft.rfftfreq(len(a),1/SR)
    h=(1-np.exp(-(f/lo)**4))*np.exp(-(f/hi)**4)
    return np.fft.irfft(np.fft.rfft(a,axis=0)*h[:,None],n=len(a),axis=0)

# Preserve the previous files and the original generator before changing canonical exports.
B=O/'v1';B.mkdir(exist_ok=True)
for p in [A/'frostfall-intro.wav',A/'frostfall-intro.mp3',A/'intro-sfx-only.wav',A/'cue-timing.json',A/'README.md',A/'cues/01-falling-whoosh.wav',ROOT/'work/build-intro-sound.py']:
    dest=B/p.name
    if not dest.exists():shutil.copy2(p,dest)

# Use a real wind recording for the continuous air layer, without any synthetic whistle.
wind=decode(S/'sketchman3-wind-woosh-loop.ogg','highpass=f=85,lowpass=f=9000')
air=wind[round(1.30*SR):round(2.8*SR)]
assert len(air)==N
t=np.arange(N)/SR;u=t/1.5
low=norm(band(air,85,650),.035)
mid=norm(band(air,450,3000),.042)
high=norm(band(air,2200,8000),.011)
# Smooth spectral opening and a steady increase of speed; no short repetitive bursts.
air=(low*(.22+.8*u**1.8)[:,None]+mid*(.18+1.55*u**2)[:,None]+high*(.20+1.1*u**2.2)[:,None])

# Choose the longest recorded bamboo swish, then slow it to give the end of the fall weight.
stats=[]
for p in sorted((S/'qubodup-swoshes').glob('*.flac')):
    a=decode(p);stats.append((len(a),p))
_,chosen=max(stats,key=lambda row:row[0])
swish=decode(chosen,'asetrate=33075,aresample=48000,highpass=f=120,lowpass=f=6500')
swish=norm(fade(swish,.045,.06),.065)
start=max(0,N-len(swish)-round(.015*SR));end=min(N,start+len(swish))
air[start:end]+=swish[:end-start]
fall=fade(air,.10,.072)
# Retain comfortable headroom without hard clipping.
peak=np.max(np.abs(fall));fall*=min(1,.38/peak)
write(V/'falling-whoosh-v2.wav',fall)
run(['-i',str(V/'falling-whoosh-v2.wav'),'-c:a','libmp3lame','-b:a','256k',str(V/'falling-whoosh-v2.mp3')])

master=wavread(B/'frostfall-intro.wav')
premaster=wavread(O/'intro-mix-premaster.wav')
music=wavread(A/'intro-music-only.wav')
oldfall=wavread(B/'01-falling-whoosh.wav')
oldsfx=wavread(B/'intro-sfx-only.wav')
newsfx=oldsfx.copy();newsfx[:N]+=fall-oldfall
write(V/'intro-sfx-only-v2.wav',newsfx)

# Estimate the earlier mastering gain in 50ms windows so the retained music keeps its level.
centers=[];gains=[];block=2400
for start in range(0,N,block):
    x=premaster[start:start+block];y=master[start:start+block]
    den=float(np.sum(x*x));gain=float(np.sum(x*y)/den) if den>1e-7 else 1.4
    centers.append(start+min(block,len(x))/2);gains.append(np.clip(gain,.5,2.5))
gain=np.interp(np.arange(N),centers,gains)
newmaster=master.copy();newmaster[:N]=(fall+music[:N])*gain[:,None]
assert np.max(np.abs(newmaster))<.94
assert np.array_equal(newmaster[N:],master[N:])
write(V/'frostfall-intro-v2.wav',newmaster)
run(['-i',str(V/'frostfall-intro-v2.wav'),'-c:a','libmp3lame','-b:a','256k',str(V/'frostfall-intro-v2.mp3')])
clip=pathlib.Path(r'C:\Users\wikto\Videos\NVIDIA\Roblox Studio\Roblox Studio 2026.09.30 - 17.10.33.02.mp4')
preview=O/'frostfall-animation-with-sound-v2.mp4'
run(['-i',str(clip),'-i',str(V/'frostfall-intro-v2.wav'),'-filter_complex','[1:a]adelay=1750|1750,apad,atrim=duration=10.1[a]',
     '-map','0:v:0','-map','[a]','-c:v','copy','-c:a','aac','-b:a','256k','-t','10.1','-movflags','+faststart',str(preview)])
run(['-i',str(preview),'-f','null','-'])

credits='''# Recorded air layers for revised falling cue

qubodup / Iwan Gabovitch: Swish - bamboo stick weapon swhoshes
https://opengameart.org/content/swish-bamboo-stick-weapon-swhoshes
License: CC0. Real bamboo staff swishes. Source archive preserved in sources/.

SketchMan3: wind whoosh loop
https://opengameart.org/content/wind-whoosh-loop
License: CC0. Wind ambience edit. Source OGG preserved in sources/.

Edits: high/low-pass filtering, spectral band balance, smooth acceleration envelope, slowed bamboo pass, gain matching and short fades. No synthetic whistle in v2. No attribution legally required under CC0; credits retained for provenance.
'''
(A/'SOURCE-CREDITS.md').write_text(credits,encoding='utf-8')
manifest=json.loads((B/'cue-timing.json').read_text(encoding='utf-8'))
manifest['revision']=2
manifest['fall_revision']='Edited recorded CC0 wind and bamboo air swish; no synthetic whistle.'
manifest['source_credits']='SOURCE-CREDITS.md'
(A/'cue-timing.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for src,dst in [(V/'frostfall-intro-v2.wav',A/'frostfall-intro.wav'),(V/'frostfall-intro-v2.mp3',A/'frostfall-intro.mp3'),(V/'intro-sfx-only-v2.wav',A/'intro-sfx-only.wav'),(V/'falling-whoosh-v2.wav',A/'cues/01-falling-whoosh.wav')]:shutil.copy2(src,dst)
readme=(B/'README.md').read_text(encoding='utf-8')
readme=readme.replace('Original synthesized sound effects and a short winter-themed score. No external sound samples.',
    'Revision 2: recorded CC0 wind and bamboo swishes replace the first falling effect. Remaining effects and score are synthesized. See SOURCE-CREDITS.md.')
readme=readme.replace('frostfall-animation-with-sound.mp4','frostfall-animation-with-sound-v2.mp4')
readme+='\nV1 is preserved in outputs/IntroSound20260930/v1/. V2 retains the original master samples from cinematic time 1.5 s onward.\n'
(A/'README.md').write_text(readme,encoding='utf-8')
with zipfile.ZipFile(O/'frostfall-intro-audio-pack-v2.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(A.rglob('*')):
        if p.is_file() and 'sources' not in p.relative_to(A).parts:z.write(p,p.relative_to(A))
checks={'fall_duration':len(fall)/SR,'mix_duration':len(newmaster)/SR,'peak_dbfs':round(20*np.log10(np.max(np.abs(newmaster))),2),
        'fall_peak_dbfs':round(20*np.log10(np.max(np.abs(newmaster[:N]))),2),'unchanged_after_1_5_seconds':bool(np.array_equal(newmaster[N:],master[N:])),
        'selected_bamboo_file':chosen.name,'preview_decode_success':True,'human_listening_verified':False}
(V/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
print(json.dumps(checks,indent=2))
