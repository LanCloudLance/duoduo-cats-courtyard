"""Original combat-only rewrite: minor-key drive, accented drums and short motifs.

Keeps the wooden storybook palette but does not reuse the exploration melody.
All instrument waveforms are generated locally. Non-combat tracks are untouched.
"""
from pathlib import Path
import hashlib, json, subprocess, wave
import numpy as np

BASE=Path(__file__).resolve().parents[2]
OUT=BASE/'outputs/duoduo-game/assets/music'
MASTERS=BASE/'work/audio/m23'
RATE=32000
FFMPEG='/Users/wangyuanlong/.local/bin/ffmpeg'
# Deliberately original short A-minor attack/answer cells, rather than M22's
# smiling C-major nursery-like phrase with a busier accompaniment.
CELLS=[
    [(0,69,.22),(.5,69,.18),(.75,72,.28),(1.5,71,.22),(2,69,.2),(2.75,76,.45)],
    [(0,72,.28),(.75,71,.2),(1.5,69,.25),(2.5,68,.22),(3,71,.3)],
    [(0,69,.18),(.5,72,.2),(1.25,74,.23),(2,76,.3),(3,74,.22),(3.5,72,.2)],
    [(0,71,.25),(.75,68,.25),(1.5,64,.35),(2.5,68,.2),(3,71,.45)],
    [(0,76,.3),(.75,74,.2),(1.5,72,.3),(2.5,74,.2),(3,76,.32)],
    [(0,77,.25),(.75,76,.25),(1.5,74,.25),(2.5,72,.22),(3.25,71,.25)],
    [(0,72,.22),(.5,71,.2),(1.5,69,.3),(2.5,72,.2),(3,74,.3)],
    [(0,71,.25),(.75,68,.2),(1.5,71,.25),(2.5,76,.22),(3.25,68,.3)],
]
PROGRESSION=[(45,[0,3,7]),(45,[0,3,7]),(50,[0,3,7]),(53,[0,4,7]),
             (45,[0,3,7]),(50,[0,3,7]),(52,[0,4,7,10]),(52,[0,4,7,10])]

def sound(kind,midi,seconds,rng):
    t=np.arange(int(seconds*RATE))/RATE
    hz=440*2**((midi-69)/12)
    v=np.zeros_like(t)
    if kind in ('mallet','bass','chug'):
        if kind=='mallet':
            for j,(ratio,amp) in enumerate([(1,1),(3.97,.30),(9.56,.085),(15.5,.018)]):
                f=hz*ratio
                if f<RATE*.43:
                    v+=amp*np.sin(2*np.pi*f*t)*np.exp(-t*(5+6*j))/(1+(f/5500)**2)
        else:
            for k in range(1,13):
                f=hz*k*np.sqrt(1+.00006*k*k)
                if f>RATE*.43: continue
                amp=np.sin(np.pi*k*.28)/k**(1.15 if kind=='chug' else 1.5)
                v+=amp*np.sin(2*np.pi*f*t)*np.exp(-t*(4+1.35*k))
            if kind=='bass':
                v+=.27*np.sin(2*np.pi*hz*t)*np.exp(-t*5)
        attack=.0025
    elif kind in ('low_drum','tom','rim'):
        modes={'low_drum':[(90,1),(144,.38),(212,.16)],
               'tom':[(164,1),(267,.42),(381,.19)],
               'rim':[(930,.75),(1430,.40),(2010,.15)]}[kind]
        for j,(f,amp) in enumerate(modes):
            pitchbend=2.5*(1-np.exp(-t*65)) if kind!='rim' else 0
            v+=amp*np.sin(2*np.pi*(f*t+pitchbend))*np.exp(-t*((13 if kind=='low_drum' else 19)+8*j))
        noise=rng.normal(0,1,len(t))
        contact=np.convolve(noise,np.ones(7)/7,mode='same')
        v+=contact*np.exp(-t*95)*(.4 if kind!='rim' else .24)
        attack=.0015
    elif kind=='backbeat':
        noise=rng.normal(0,1,len(t))
        warm=np.convolve(noise,np.ones(5)/5,mode='same')
        v=warm*np.exp(-t*23)*1.2
        v+=np.sin(2*np.pi*188*t)*np.exp(-t*24)*.43
        v+=np.sin(2*np.pi*337*t)*np.exp(-t*39)*.13
        attack=.0018
    else: # short, quiet seed-pod shaker
        noise=rng.normal(0,1,len(t))
        v=np.diff(noise,prepend=0)*np.exp(-t*52)*.24
        attack=.004
    env=np.minimum(t/attack,1)*np.minimum(np.maximum(0,seconds-t)/.045,1)
    return v*env*.32

def wav(path,mix):
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes((np.clip(mix,-.98,.98)*32767).astype('<i2').tobytes())

def compose(name,bpm):
    rng=np.random.default_rng(2301 if name=='battle' else 2302)
    beat=60/bpm; n=int(128*beat*RATE)
    mix=np.zeros((n,2)); events=[]
    def add(at,note,duration,kind,gain,pan=0):
        tail=.12 if kind in ('mallet','bass','chug') else .08
        samples=sound(kind,note,max(.075,duration*beat+tail),rng)*gain
        onset=(at+rng.uniform(-.004,.004))*beat
        ix=(int(onset*RATE)+np.arange(len(samples)))%n
        np.add.at(mix[:,0],ix,samples*np.sqrt((1-pan)/2))
        np.add.at(mix[:,1],ix,samples*np.sqrt((1+pan)/2))
        events.append({'beat':round(at,3),'note':note,'kind':kind})
    for bar in range(32):
        b=bar*4; section=bar//8; root,chord=PROGRESSION[bar%8]
        # The B section tightens the rhythm; the third section briefly clears
        # its upper line, then the last eight bars bring the full attack back.
        drive=[.88,1,.82,1.08][section]
        if section==2: root,chord=[(50,[0,3,7]),(53,[0,4,7]),(45,[0,3,7]),(52,[0,4,7,10])][bar%4]
        accents=[0,1.5,3]
        bass_notes=[root,root,root+7,root,root,root+7,root,root+7]
        for k,note in enumerate(bass_notes):
            at=k*.5
            add(b+at,note,.21,'bass',(.73 if at in accents else .47)*drive,-.06)
            if k in [0,3,6] or (name=='boss' and section!=2):
                for j,tone in enumerate(chord[:3]):
                    add(b+at+j*.008,root+12+tone,.15,'chug',.22*drive,[-.3,.05,.3][j])
        # Low drum and audible backbeat establish combat immediately; subdued
        # shaker gives subdivisions without smearing the short hit effects.
        for at,gain in [(0,.72),(1.5,.53),(2,.66),(3.5,.37)]:
            add(b+at,0,.24,'low_drum',gain*drive)
        for at in [1,3]: add(b+at,0,.18,'backbeat',.38*drive,.07)
        for k in range(8):
            add(b+k*.5,0,.09,'shaker',(.09 if k%2 else .06)*drive,-.35 if k%2 else .35)
        if section!=2:
            for at in [0,1.5,3]: add(b+at+.04,0,.09,'rim',.07*drive,.3)
        cell=CELLS[bar%8]
        for onset,note,duration in cell:
            if section==2:
                if onset in [.5,.75]: continue
                note-=12
            elif section==1 and bar%2: note+=12
            if name=='boss' and bar%8 in [3,7]: note+=1 if note==71 else 0
            add(b+onset,note,duration,'mallet',.39*drive,-.12)
        # Phrase-end tom turns and a final E7 pickup create actual structural
        # tension rather than playing the exploration melody at a faster BPM.
        if bar%4==3:
            for j,at in enumerate([2.75,3.25,3.5,3.75]):
                add(b+at,0,.15,'tom',(.19+.025*j)*drive,-.35+.23*j)
        if name=='boss' and section in [1,3] and bar%4==2:
            for at in [2.25,2.75,3.25,3.75]:
                add(b+at,root+19,.13,'chug',.22,.28)
    dry=mix.copy()
    for delay,amount in [(.029,.065),(.053,.045),(.091,.025)]:
        mix+=np.roll(dry,int(delay*RATE),axis=0)[:,::-1]*amount
    mix-=mix.mean(axis=0)
    rms=float(np.sqrt(np.mean(mix**2))); peak=float(np.max(np.abs(mix)))
    mix*=min((.125 if name=='battle' else .132)/rms,.72/peak)
    master=MASTERS/(name+'.wav'); wav(master,mix)
    subprocess.run([FFMPEG,'-y','-hide_banner','-loglevel','error','-i',str(master),
                    '-c:a','libvorbis','-q:a','2',str(OUT/(name+'.ogg'))],check=True)
    # Loudness-aligned short samples make the changed composition reviewable;
    # preview normalization is not applied to the in-game loop.
    preview=MASTERS/(name+'-preview.mp3')
    subprocess.run([FFMPEG,'-y','-hide_banner','-loglevel','error','-i',str(master),'-t','30',
                    '-af','loudnorm=I=-20:TP=-2:LRA=7,afade=t=out:st=28:d=2',
                    '-c:a','libmp3lame','-q:a','2',str(preview)],check=True)
    return {'name':name,'bpm':bpm,'seconds':n/RATE,'meter':4,'key':'A minor with E7 tension',
            'sections':4,'events':len(events),'peak':float(np.max(np.abs(mix))),
            'rms':float(np.sqrt(np.mean(mix**2))),
            'loop_edge_delta':float(np.max(np.abs(mix[-1]-mix[0]))),
            'ogg_bytes':(OUT/(name+'.ogg')).stat().st_size,'preview_seconds':30}

if __name__=='__main__':
    MASTERS.mkdir(parents=True,exist_ok=True)
    preserved=['home.ogg','explore.ogg','puzzle.ogg','rest.ogg','chime-0.wav','chime-1.wav']
    before={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in preserved}
    rows=[compose('battle',136),compose('boss',144)]
    assert all(r['peak']<=.73 and r['loop_edge_delta']<.035 for r in rows)
    assert before=={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in preserved}
    evidence={'tracks':rows,'preserved_audio_sha256':before,'subjective_listening_verified':False}
    (MASTERS/'metrics.json').write_text(json.dumps(evidence,indent=2)+'\n')
    # A matching-loudness excerpt of rejected M22 is retained only for comparison.
    subprocess.run([FFMPEG,'-y','-hide_banner','-loglevel','error',
                    '-i',str(BASE/'work/audio/m22/battle.wav'),'-t','30',
                    '-af','loudnorm=I=-20:TP=-2:LRA=7,afade=t=out:st=28:d=2',
                    '-c:a','libmp3lame','-q:a','2',str(MASTERS/'m22-battle-comparison.mp3')],check=True)
    print(json.dumps(evidence,indent=2))
