"""Original synthesized Foley and a short winter-themed musical cue. No external audio samples."""
import sys, pathlib, subprocess, json, wave, zipfile
import numpy as np
sys.path.insert(0,r'C:\Users\wikto\Documents\Codex\2026-09-29\ca\work\audio-tools')
import imageio_ffmpeg

SR=48000
DURATION=7.9
OFFSET=1.75
OUT=pathlib.Path(r'C:\Users\wikto\Desktop\Roblox Gra\outputs\IntroSound20260930')
ASSETS=pathlib.Path(r'C:\Users\wikto\Desktop\Roblox Gra\assets\audio\intro')
OUT.mkdir(parents=True,exist_ok=True); ASSETS.mkdir(parents=True,exist_ok=True)
STEMS=ASSETS/'cues'; STEMS.mkdir(exist_ok=True)
RNG=np.random.default_rng(9302026)
N=round(SR*DURATION)
sfx=np.zeros((N,2)); music=np.zeros((N,2)); cues=[]

def time(d): return np.arange(round(d*SR))/SR
def fades(a,attack=.012,release=.06):
    a=a.copy(); na=min(len(a),max(2,round(attack*SR))); nr=min(len(a),max(2,round(release*SR)))
    a[:na]*=np.sin(np.linspace(0,np.pi/2,na))**2
    a[-nr:]*=np.cos(np.linspace(0,np.pi/2,nr))**2
    return a
def colored(d,lo=100,hi=6000,slope=0):
    n=round(d*SR); w=RNG.normal(size=n); f=np.fft.rfftfreq(n,1/SR)
    shape=(1-np.exp(-(f/max(lo,1))**4))*np.exp(-(f/hi)**4)
    shape*=np.maximum(f,80)**(-slope)
    a=np.fft.irfft(np.fft.rfft(w)*shape,n=n)
    return a/max(float(np.std(a)),1e-9)
def phase(freq): return 2*np.pi*np.cumsum(freq)/SR
def pitch(midi): return 440*2**((midi-69)/12)
def stereo(a,pan=0):
    if a.ndim==2:return a
    angle=(np.clip(pan,-1,1)+1)*np.pi/4
    return np.column_stack((a*np.cos(angle),a*np.sin(angle)))
def place(dest,a,start):
    i=round(start*SR); end=min(len(dest),i+len(a));
    if end>i:dest[i:end]+=a[:end-i]
def echo(a,delays=(.13,.22,.37),gains=(.20,.12,.07)):
    a=stereo(a); out=np.zeros((len(a)+round(max(delays)*SR),2)); out[:len(a)]+=a
    for j,(delay,gain) in enumerate(zip(delays,gains)):
        k=round(delay*SR); wet=a[:,::-1] if j%2==0 else a
        out[k:k+len(a)]+=wet*gain
    return out
def bell(midi,d=1.0,level=.12,pan=0):
    t=time(d); f=pitch(midi); a=np.zeros(len(t))
    for ratio,gain,decay in [(1,1,.65),(2.003,.30,.32),(2.76,.16,.18),(4.08,.075,.11)]:
        a+=gain*np.sin(2*np.pi*f*ratio*t)*np.exp(-t/decay)
    return echo(stereo(fades(a,attack=.004,release=.09)*level,pan))
def pluck(midi,d=.6,level=.08,pan=0):
    t=time(d); f=pitch(midi); a=np.zeros(len(t))
    for k,g in [(1,1),(2,.28),(3,.12),(4,.045)]:
        a+=g*np.sin(2*np.pi*f*k*t)*np.exp(-t/(.27/k**.38))
    return echo(stereo(fades(a,attack=.004,release=.07)*level,pan),(.073,.147),(.10,.055))
def swoosh(d,level=.1,rising=True):
    t=time(d); u=t/d; a=colored(d,180,7500,.45)
    bright=colored(d,1500,12000,.0)
    shape=np.sin(np.pi*u)**1.6
    a=(a*(.8-.4*u)+bright*(.1+.20*u))*shape
    f=140+600*(u if rising else 1-u)**1.9
    a+=.10*np.sin(phase(f))*shape
    # A slight pan movement creates space without exaggerated motion.
    p=np.linspace(-.28,.28,len(t)); l=np.sqrt((1-p)/2); r=np.sqrt((1+p)/2)
    return np.column_stack((a*l,a*r))*level
def powder(d,level=.15):
    t=time(d); noise=colored(d,160,5300,.5)
    air=colored(d,1800,10500,.1)
    a=(noise*np.exp(-t/.19)+air*.22*np.exp(-t/.32))
    a*=np.minimum(t/.014,1)
    return fades(a,release=.12)*level
def foot(level=.12):
    d=.22;t=time(d)
    crunch=colored(d,430,6500,.25)*np.exp(-t/.052)
    body=np.sin(2*np.pi*(105*t-40*t*t))*np.exp(-t/.035)
    return fades((crunch*.68+body*.32)*level,.003,.045)
def event(name,start,a,pan=0):
    a=stereo(a,pan); place(sfx,a,start)
    cues.append({'name':name,'start':start,'length':round(len(a)/SR,4),'file':f'cues/{name}.wav'})
    write(STEMS/f'{name}.wav',a)
def write(path,a):
    a=stereo(a); peak=float(np.max(np.abs(a))) if len(a) else 0
    if peak> .98:a=a*(.98/peak)
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR)
        f.writeframes(np.rint(np.clip(a,-1,1)*32767).astype('<i2').tobytes())

# Airborne fall: airy accelerating wind plus a quiet sliding cartoon whistle.
t=time(1.5);u=t/1.5
fall=colored(1.5,150,5600,.55)*(.035+.14*u**2)*np.sin(np.pi*np.minimum(u/.98,1))**.6
whistle=np.sin(phase(1050-790*u**1.3))*.035*np.sin(np.pi*u)**2
event('01-falling-whoosh',0,fades(fall+whistle,.10,.025))

# A padded impact, powder dispersion and individual falling grains.
t=time(.65); impact=powder(.65,.24)
impact+=np.sin(phase(130*np.exp(-t*12)+48))*.33*np.exp(-t/.065)
event('02-snow-landing',1.5,fades(impact,.002,.12))
settle=np.zeros(round(.7*SR))
for start,gain in [(0,.055),(.11,.034),(.25,.026),(.41,.017)]:
    a=powder(.19,gain);i=round(start*SR);settle[i:i+len(a)]+=a
event('03-snow-settle',1.78,settle,-.12)

# Head rises: small round plop, no vocal sample or sharp squeak.
t=time(.23); head=np.sin(phase(280+430*np.sin(np.pi*t/.23)))*np.exp(-t/.083)*.105
head+=colored(.23,700,2900,.3)*.018*np.exp(-t/.04)
event('04-head-pop',2.25,fades(head,.006,.055),-.15)

# Discovery sparkle accents match the three shovel glints in the controller.
for i,(start,note,pan) in enumerate([(3.10,86,.17),(3.30,91,-.15),(3.50,96,.12)]):
    event(f'05-discovery-chime-{i+1}',start,bell(note,.85,.115,pan))
for i,start in enumerate([4.24,4.40,4.55,4.70]):
    event(f'06-snow-step-{i+1}',start,foot(.088+(.009 if i%2 else 0)), -.15 if i%2==0 else .12)

# Wooden handle strain and the release from the snow.
t=time(.35); rough=colored(.35,160,1400,.65)
creak=(np.sin(phase(190+38*np.sin(2*np.pi*5*t)))+rough*.25)*np.sin(np.pi*t/.35)**2*.047
event('07-handle-creak',4.99,creak,.05)
t=time(.4); pop=np.sin(phase(510*np.exp(-t*15)+95))*.17*np.exp(-t/.060)+powder(.4,.13)
event('08-shovel-pull-pop',5.22,fades(pop,.002,.06))
event('09-shovel-lift-whoosh',5.36,swoosh(.52,.09))

# Snow shaken off the blade, soft and stereo.
sprinkle=np.zeros((round(.74*SR),2))
for start,gain,pan in [(0,.032,-.3),(.09,.028,.25),(.20,.021,-.1),(.33,.014,.3),(.48,.009,-.2)]:
    a=stereo(powder(.16,gain),pan);i=round(start*SR);sprinkle[i:i+len(a)]+=a
event('10-blade-snow-sprinkle',5.28,sprinkle)

# The victory flourish uses a clear C major pentatonic fanfare and restrained sparkle.
hero=np.zeros((round(1.42*SR),2))
for start,note,gain,pan in [(0,72,.13,-.25),(.075,76,.115,.15),(.15,79,.12,-.1),(.24,84,.15,.2)]:
    place(hero,bell(note,.75,gain,pan),start)
event('11-victory-flourish',5.86,hero)
for i,(start,note,pan) in enumerate([(6.62,96,-.25),(6.74,100,.22),(6.86,103,.03)]):
    event(f'12-closeup-glint-{i+1}',start,bell(note,.65,.083,pan))
event('13-camera-handoff',7.16,swoosh(.52,.038,False))

# Musical underscore: quiet felt mallet motif, warm low pad, suspended discovery.
# Leave a small comic gap around the landing; resolve as the shovel is lifted.
def pad(start,duration,notes,level):
    t=time(duration); env=np.sin(np.pi*t/duration)**1.1
    arr=np.zeros((len(t),2))
    for j,n in enumerate(notes):
        f=pitch(n); a=(np.sin(2*np.pi*f*t)+.12*np.sin(2*np.pi*2*f*t))
        a+=.3*np.sin(2*np.pi*(f*1.0025)*t)
        arr+=stereo(a*env*level/len(notes),(-.35,.35)[j%2])
    place(music,arr,start)
pad(.0,1.42,[48,55,64,74],.065)
pad(2.48,2.52,[53,60,67,74],.078)
pad(5.27,2.59,[48,55,64,69,74],.10)
for start,note,lev,pan in [(.10,84,.053,-.3),(.40,81,.045,.2),(.7,79,.047,-.15),(.99,76,.042,.25),
                         (2.76,72,.055,-.2),(3.02,76,.05,.15),(3.26,79,.042,-.15),
                         (3.77,74,.044,.1),(4.04,79,.052,-.2),(4.32,81,.05,.23),
                         (5.32,67,.059,-.25),(5.48,72,.065,.2),(5.64,76,.064,-.15),
                         (5.83,79,.074,.25),(6.08,84,.056,-.2),
                         (6.38,79,.045,.2),(6.64,81,.043,-.1),(6.92,84,.05,.1),
                         (7.27,76,.04,-.2),(7.40,79,.038,.1)]:
    place(music,pluck(note,.54,lev,pan),start)

# Fade gracefully before the existing post-intro gameplay music takes over.
tail=round(.28*SR); endfade=np.cos(np.linspace(0,np.pi/2,tail))**2
sfx[-tail:]*=endfade[:,None];music[-tail:]*=endfade[:,None]
write(ASSETS/'intro-sfx-only.wav',sfx)
write(ASSETS/'intro-music-only.wav',music)
raw=sfx+music
write(OUT/'intro-mix-premaster.wav',raw)
ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
def run(args):return subprocess.run([ffmpeg,'-hide_banner','-y']+args,check=True,capture_output=True,text=True)
master=run(['-i',str(OUT/'intro-mix-premaster.wav'),'-af','loudnorm=I=-18:TP=-1.5:LRA=9:print_format=json','-ar','48000','-c:a','pcm_s16le',str(ASSETS/'frostfall-intro.wav')])
(OUT/'mastering-report.txt').write_text(master.stderr,encoding='utf-8')
run(['-i',str(ASSETS/'frostfall-intro.wav'),'-c:a','libmp3lame','-b:a','256k',str(ASSETS/'frostfall-intro.mp3')])

# Video retains the untouched original video stream; replace its near-silent audio.
clip=pathlib.Path(r'C:\Users\wikto\Videos\NVIDIA\Roblox Studio\Roblox Studio 2026.09.30 - 17.10.33.02.mp4')
preview=OUT/'frostfall-animation-with-sound.mp4'
run(['-i',str(clip),'-i',str(ASSETS/'frostfall-intro.wav'),'-filter_complex',
     f'[1:a]adelay={round(OFFSET*1000)}|{round(OFFSET*1000)},apad,atrim=duration=10.1[a]',
     '-map','0:v:0','-map','[a]','-c:v','copy','-c:a','aac','-b:a','256k','-t','10.1','-movflags','+faststart',str(preview)])
manifest={'duration_seconds':DURATION,'sample_rate':SR,'channels':2,'video_offset_seconds':OFFSET,
          'impact':1.5,'shovel_pull':5.22,'victory':5.86,'closeup':6.62,'cues':cues,
          'notes':'Start the full mix at cinematic time zero, not at loading screen creation. Stop on Skip/abort. Not uploaded or installed in Roblox.'}
(ASSETS/'cue-timing.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
readme='''# Frostfall intro audio

Original synthesized sound effects and a short winter-themed score. No external sound samples.

- frostfall-intro.wav: finished 7.9-second stereo mix, 48 kHz / 16-bit PCM.
- frostfall-intro.mp3: compressed listening copy.
- intro-sfx-only.wav and intro-music-only.wav: separate stems for adjustment.
- cues/: individual effect files. cue-timing.json uses cinematic-relative seconds.
- Preview video is in outputs/IntroSound20260930/frostfall-animation-with-sound.mp4.

Preview timing: cinematic begins approximately 1.75 seconds into the supplied screen recording. Snow impact lands at 3.25 seconds; shovel release at 6.97 seconds. The original video stream is retained, audio replaced, original recording unchanged.

Roblox integration pending: upload the WAV under the experience owner and grant the experience audio access. Assign its usable Roblox audio ID; preload it with the intro assets. Play locally at the actual cinematic time origin, not when the loading screen appears, and stop/destroy on completion, Skip, respawn or failure. Do not change the existing music-after-intro gate. Never use this recording's 1.75-second offset inside the game.

Verification: decoded source clip frames used for synchronization; source audio essentially silent. Files are synthesized and digitally checked for finite samples, peak/headroom, durations and successful video remux. Human listening and in-game speaker playback remain to be checked. Nothing uploaded, changed in Studio, saved or published.
'''
(ASSETS/'README.md').write_text(readme,encoding='utf-8')
with zipfile.ZipFile(OUT/'frostfall-intro-audio-pack.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(ASSETS.rglob('*')):
        if p.is_file():z.write(p,p.relative_to(ASSETS))
checks=[]
for name in ['frostfall-intro.wav','intro-sfx-only.wav','intro-music-only.wav']:
    with wave.open(str(ASSETS/name)) as f:
        a=np.frombuffer(f.readframes(f.getnframes()),'<i2').astype(float)/32768
        check={'file':name,'seconds':len(a)/f.getnchannels()/f.getframerate(),'peak_dbfs':round(20*np.log10(max(np.max(np.abs(a)),1e-12)),2),'rms_dbfs':round(20*np.log10(max(np.sqrt(np.mean(a*a)),1e-12)),2)}
        assert len(a)>0 and np.isfinite(a).all() and np.max(np.abs(a))<.99
        assert abs(check['seconds']-DURATION)<1/SR
        checks.append(check)
verification=run(['-i',str(preview),'-f','null','-'])
(OUT/'verification.json').write_text(json.dumps({'audio':checks,'preview_decodes':True,'preview_duration':10.1,'original_video_unchanged':True,'human_listening_verified':False},indent=2),encoding='utf-8')
print(json.dumps({'assets':str(ASSETS),'preview':str(preview),'pack':str(OUT/'frostfall-intro-audio-pack.zip'),'checks':checks,'cues':len(cues)},indent=2))

