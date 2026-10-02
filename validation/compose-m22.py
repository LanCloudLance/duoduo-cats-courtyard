"""Original wooden-storybook score: tuned wood bars, plucked strings and hand percussion.

Offline modal synthesis only; no downloaded samples or borrowed melodies. The
arrangement deliberately leaves phrase endings quiet. Rendered Ogg files keep
the existing six context names and streaming playback in the game.
"""
from pathlib import Path
import json, subprocess, wave
import numpy as np

BASE = Path(__file__).resolve().parents[2]
OUT = BASE / 'outputs/duoduo-game/assets/music'
MASTERS = BASE / 'work/audio/m22'
RATE = 32000
FFMPEG = '/Users/wangyuanlong/.local/bin/ffmpeg'
PROFILES = {
    'home': (96, 3, .75), 'explore': (110, 3, .81),
    'puzzle': (84, 3, .68), 'battle': (116, 4, .83),
    'boss': (126, 4, .86), 'rest': (76, 3, .62),
}
# Original call-and-answer phrases, in C; each ends with breathing space.
PHRASES = [
    [(0,72,.45),(.65,76,.45),(1.3,79,.6),(2.1,76,.5)],
    [(.15,74,.55),(1,77,.5),(1.75,76,.7)],
    [(0,72,.6),(1,74,.35),(1.65,76,.6),(2.35,79,.3)],
    [(.1,77,.55),(.95,74,.55),(1.75,72,.85)],
    [(0,76,.45),(.6,79,.45),(1.25,81,.6),(2.15,79,.5)],
    [(.15,77,.7),(1.2,76,.45),(1.95,74,.6)],
    [(0,74,.4),(.65,76,.4),(1.3,79,.55),(2.15,77,.45)],
    [(.1,76,.5),(1,74,.45),(1.75,72,.85)],
]

def voice(kind, midi, duration, rng):
    t = np.arange(max(1, int(duration*RATE))) / RATE
    hz = 440 * 2**((midi-69)/12)
    v = np.zeros_like(t)
    if kind in ('wood', 'bell'):
        # Tuned wooden-bar modes, unlike a sustained sine/organ pad. Short upper
        # modes produce a mallet strike and leave a rounded fundamental tail.
        modes = [1, 3.97, 9.56, 15.5] if kind == 'wood' else [1, 2.72, 5.43, 8.1]
        gains = [1, .23, .075, .02] if kind == 'wood' else [1,.19,.055,.015]
        decay = .70 if kind == 'wood' else 1.05
        for k, (ratio, gain) in enumerate(zip(modes, gains)):
            frequency = hz*ratio
            if frequency > RATE*.44: continue
            gain /= 1+(frequency/4800)**2
            v += gain*np.sin(2*np.pi*frequency*t)*np.exp(-t*(1/decay+3.6*k))
        # A softly filtered mallet contact, not a sharp electronic click.
        noise = rng.normal(0,1,len(t))
        noise = np.convolve(noise, np.ones(23)/23, mode='same')
        v += noise*np.exp(-t*150)*.12
        env = np.minimum(t/.003,1)
    elif kind in ('pluck', 'bass'):
        # Plucked string partials with body warmth and faster high-mode decay.
        position = .23 if kind == 'pluck' else .31
        for k in range(1,13):
            frequency = hz*k*np.sqrt(1+.00008*k*k)
            if frequency > RATE*.44: continue
            amp = np.sin(np.pi*k*position)/k**1.25
            v += amp*np.sin(2*np.pi*frequency*t)*np.exp(-t*(.8+1.3*k))
        v += .085*np.sin(2*np.pi*hz*.998*t)*np.exp(-t*3.2)
        env = np.minimum(t/.004,1)
    elif kind == 'block':
        for hz2, amp in [(690,1),(1240,.35),(1830,.12)]:
            v += amp*np.sin(2*np.pi*hz2*t)*np.exp(-t*(35+hz2/90))
        env = np.minimum(t/.001,1)
    elif kind == 'brush':
        noise = rng.normal(0,1,len(t))
        v = np.convolve(noise,np.ones(13)/13,mode='same')*np.exp(-t*38)
        env = np.minimum(t/.009,1)
    else: # low hand drum, no electronic kick sweep
        v = (np.sin(2*np.pi*125*t)*np.exp(-t*17)
             +.22*np.sin(2*np.pi*213*t)*np.exp(-t*29))
        env = np.minimum(t/.003,1)
    # Explicit release prevents truncation clicks when notes are short.
    env *= np.minimum(np.maximum(0,duration-t)/.08,1)
    return v*np.maximum(env,0)*.26

def write_wav(path, mix):
    pcm=(np.clip(mix,-.98,.98)*32767).astype('<i2')
    with wave.open(str(path),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(pcm.tobytes())

def compose(name, settings):
    bpm, meter, gain = settings
    rng=np.random.default_rng(2200+list(PROFILES).index(name))
    beat=60/bpm; length=int(32*meter*beat*RATE)
    mix=np.zeros((length,2),np.float64); events=[]
    battle=name in ('battle','boss')
    def add(at, midi, duration, kind, amp, pan=0):
        # Longer tails than score note durations; they wrap into the loop.
        tail=.65 if kind in ('wood','pluck','bass') else .12
        duration=duration*beat+tail
        note=voice(kind,midi,duration,rng)*amp
        onset=(at+rng.uniform(-.009,.009))*beat
        ix=(int(onset*RATE)+np.arange(len(note)))%length
        np.add.at(mix[:,0],ix,note*np.sqrt((1-pan)/2))
        np.add.at(mix[:,1],ix,note*np.sqrt((1+pan)/2))
        events.append({'beat':round(at,3),'note':midi,'instrument':kind})
    progressions=[
        [(48,[0,4,7]),(53,[0,4,7]),(55,[0,4,7]),(48,[0,4,7]),
         (57,[0,3,7]),(53,[0,4,7]),(55,[0,4,7]),(48,[0,4,7])],
        [(53,[0,4,7]),(48,[0,4,7]),(50,[0,3,7]),(55,[0,4,7]),
         (53,[0,4,7]),(57,[0,3,7]),(55,[0,4,7]),(48,[0,4,7])],
    ]
    for bar in range(32):
        section=bar//8; b=bar*meter
        root,chord=progressions[1 if section==2 else 0][bar%8]
        intensity=[.72,.9,.65,1][section]
        if name in ('puzzle','rest'): intensity*=.72
        # A simple bass and sparse offbeat pluck accompaniment; no constant pad.
        add(b,root,1.4,'bass',.67*intensity,-.1)
        if battle: add(b+2,root+7,.7,'bass',.45*intensity,-.1)
        for j,tone in enumerate(chord):
            add(b+.55+j*.045,root+12+tone,.45,'pluck',.24*intensity,-.32)
        if battle or name=='explore':
            for j,tone in enumerate(reversed(chord)):
                add(b+meter-.85+j*.04,root+12+tone,.45,'pluck',.16*intensity,.22)
        phrase=PHRASES[bar%8]
        for onset,midi,duration in phrase:
            if section==2:
                midi-=12
                if bar%2 and onset<.2: continue
            if name in ('puzzle','rest') and bar%4==3 and onset>1.2: continue
            at=b+onset*(1.18 if battle else 1)
            add(at,midi,duration,'wood',.73*intensity,.08)
        # Plucked-string answers enter only in the second/final sections.
        if section in (1,3) and bar%2==1:
            for j,tone in enumerate([chord[2],chord[1]]):
                add(b+meter-1.1+j*.48,root+24+tone,.3,'pluck',.27*intensity,.33)
        # A light wooden groove carries combat. Exploration has half the hits;
        # puzzle/rest remain mostly quiet so the physical bell can be heard.
        if battle:
            for at in [0,2]: add(b+at,0,.2,'drum',.23*intensity)
            for at in [1,3]: add(b+at,0,.1,'block',.075*intensity,.25)
            for at in [.5,1.5,2.5,3.5]: add(b+at,0,.12,'brush',.12*intensity,-.25)
            if section==3 and bar%4==2:
                for at in [3.25,3.5,3.75]: add(b+at,0,.1,'block',.04,.2)
        elif name in ('home','explore') and section!=2:
            add(b,0,.2,'drum',.06)
            if bar%2==0: add(b+1.5,0,.1,'block',.04,.3)
        # A tiny ceramic sparkle is a phrase punctuation, never a lead ostinato.
        if name=='puzzle' and bar in (3,11,23,31):
            add(b+2.3,79,.55,'bell',.14,.34)
    dry=mix.copy()
    for delay,amount in [(.033,.085),(.061,.06),(.109,.035)]:
        mix+=np.roll(dry,int(delay*RATE),axis=0)[:,::-1]*amount
    mix-=mix.mean(axis=0)
    peak=float(np.abs(mix).max())
    mix*=min(1,.62/max(peak,.001))*gain
    wav=MASTERS/(name+'.wav'); write_wav(wav,mix)
    subprocess.run([FFMPEG,'-y','-hide_banner','-loglevel','error','-i',str(wav),
                    '-c:a','libvorbis','-q:a','3',str(OUT/(name+'.ogg'))],check=True)
    if name in ('explore','battle'):
        subprocess.run([FFMPEG,'-y','-hide_banner','-loglevel','error','-i',str(wav),
                        '-t','22','-af','afade=t=out:st=20:d=2',
                        '-c:a','libmp3lame','-q:a','2',str(MASTERS/(name+'-preview.mp3'))],check=True)
    return {'name':name,'seconds':len(mix)/RATE,'bpm':bpm,'meter':meter,'sections':4,
            'events':len(events),'peak':float(np.abs(mix).max()),
            'rms':float(np.sqrt(np.mean(mix**2))),
            'loop_edge_delta':float(np.abs(mix[-1]-mix[0]).max()),
            'instruments':sorted(set(e['instrument'] for e in events))}

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True); MASTERS.mkdir(parents=True,exist_ok=True)
    rows=[compose(name,settings) for name,settings in PROFILES.items()]
    assert all(r['peak']<.8 and r['loop_edge_delta']<.025 for r in rows)
    (MASTERS/'metrics.json').write_text(json.dumps(rows,indent=2)+'\n')
    # Two original ceramic bell effects, keyed to the actual left/right receivers.
    for i,midi in enumerate([79,84]):
        rng=np.random.default_rng(2220+i)
        v=voice('bell',midi,1.1,rng)*.65
        stereo=np.column_stack([v,v])
        write_wav(OUT/('chime-'+str(i)+'.wav'),stereo)
    print(json.dumps(rows,indent=2))
