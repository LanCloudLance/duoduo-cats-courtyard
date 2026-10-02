"""Original Duoduo chamber-game score. All oscillators and note arrangements here.

No samples or melodies from reference games. WAV masters stay outside the export;
loopable Vorbis copies enter the game. NumPy is only an offline build dependency.
"""
from pathlib import Path
import json, subprocess, wave
import numpy as np

BASE = Path(__file__).resolve().parents[2]
OUT = BASE/'outputs/duoduo-game/assets/music'
MASTERS = BASE/'work/audio/m21'
RATE = 32000
MOTIFS = [
    [(0,74,0.75),(1,78,0.5),(1.75,81,0.75),(3,78,0.7)],
    [(0,76,0.75),(1,73,0.65),(2,71,0.6),(3,69,0.8)],
    [(0.5,71,0.6),(1.5,74,0.6),(2.5,78,1.0)],
    [(0,76,0.75),(1,78,0.6),(2,73,0.6),(3,69,0.65)],
]
PROFILES = {
    'home': {'bpm':88,'lead':'wood','root':50,'key':[0,4,7],'gain':0.67},
    'explore': {'bpm':104,'lead':'pluck','root':50,'key':[0,4,7],'gain':0.77},
    'puzzle': {'bpm':86,'lead':'bell','root':47,'key':[0,3,7],'gain':0.62},
    'battle': {'bpm':120,'lead':'wood','root':47,'key':[0,3,7],'gain':0.84},
    'boss': {'bpm':128,'lead':'strings','root':47,'key':[0,3,7],'gain':0.87},
    'rest': {'bpm':76,'lead':'wood','root':50,'key':[0,4,7],'gain':0.59},
}

def instrument(kind, midi, seconds, rng):
    n=int(seconds*RATE); t=np.arange(n,dtype=np.float64)/RATE
    hz=440*2**((midi-69)/12)
    phase=2*np.pi*hz*t + 0.045*np.sin(2*np.pi*5.2*t)
    if kind == 'pluck':
        v=sum(np.sin(phase*k)*np.exp(-t*(2.5+k*0.8))/k**1.25 for k in range(1,10))
        env=np.minimum(t/0.004,1)*np.minimum((seconds-t)/0.09,1)
    elif kind == 'bell':
        v=(np.sin(phase)*np.exp(-t*2.5)+0.38*np.sin(phase*2.76)*np.exp(-t*5)+0.17*np.sin(phase*5.4)*np.exp(-t*7))
        env=np.minimum(t/0.006,1)*np.minimum((seconds-t)/0.12,1)
    elif kind == 'strings':
        v=sum(np.sin(phase*k+0.007*k*np.sin(2*np.pi*0.7*t))/k**1.65 for k in range(1,9))
        env=np.minimum(t/0.14,1)*np.minimum((seconds-t)/0.24,1)
    elif kind == 'bass':
        v=np.sin(phase)+0.24*np.sin(phase*2)+0.08*np.sin(phase*3)
        env=np.minimum(t/0.012,1)*np.exp(-t*1.4)*np.minimum((seconds-t)/0.10,1)
    else:
        breath=rng.normal(0,1,n)
        breath=np.convolve(breath,np.ones(13)/13,mode='same')
        v=np.sin(phase)+0.20*np.sin(phase*2)+0.09*np.sin(phase*3)+0.022*breath
        env=np.minimum(t/0.042,1)*np.minimum((seconds-t)/0.16,1)*(0.92+0.08*np.sin(2*np.pi*4*t))
    return v*np.maximum(0,env)*0.25

def compose(name, profile):
    rng=np.random.default_rng(2100+list(PROFILES).index(name))
    beat=60/profile['bpm']; length=int(64*beat*RATE)
    mix=np.zeros((length,2),np.float64)
    events=[]
    def add(start, duration, midi, timbre, amp, pan=0):
        voice=instrument(timbre,midi,max(0.20,duration*beat),rng)*amp
        begin=int(start*beat*RATE); ix=(begin+np.arange(len(voice)))%length
        left=np.sqrt((1-pan)/2); right=np.sqrt((1+pan)/2)
        np.add.at(mix[:,0],ix,voice*left); np.add.at(mix[:,1],ix,voice*right)
        events.append({'beat':start,'note':midi,'duration':duration,'instrument':timbre})
    root=profile['root']; major=profile['key']==[0,4,7]
    progression=[(0,[0,4 if major else 3,7]),(9 if major else 5,[0,3 if major else 4,7]),
                 (5 if major else 8,[0,4,7]),(7,[0,4,7])]
    for bar in range(16):
        b=bar*4; section=bar//4; shift,chord=progression[bar%4]
        bass=root+shift
        add(b,2.0,bass,'bass',0.68)
        add(b+2,1.8,bass+7,'bass',0.48)
        # A stable harmony bed contrasts the moving melody, with a contrasting B.
        for j,tone in enumerate(chord): add(b+0.03*j,3.85,bass+12+tone,'strings',0.25 if name in ['battle','boss'] else 0.19,(-0.4,0,0.4)[j])
        for k in range(8 if name in ['explore','battle','boss'] else 4):
            step=0.5 if name in ['explore','battle','boss'] else 1.0
            note=bass+24+chord[k%3]
            add(b+k*step,0.65,note,'pluck',0.16 if name in ['puzzle','rest'] else 0.28,(-0.28 if k%2 else 0.28))
        melody=MOTIFS[bar%4]
        for onset,midi,duration in melody:
            if name in ['puzzle','rest'] and section==1 and onset<1: continue
            transformed=midi if major else midi-3
            if section==1: transformed-=12
            elif section==3 and bar%4 in [0,2]: transformed+=2
            add(b+onset,duration+0.22,transformed,profile['lead'],0.85 if section!=1 else 0.60,-0.10)
        # Answering phrases and a sparse bridge prevent one motif filling every bar.
        if section==2 and bar%2:
            for k,tone in enumerate(reversed(chord)):
                add(b+1+k,0.72,bass+24+tone,'bell' if name!='puzzle' else 'wood',0.38,0.30)
        if name in ['battle','boss','explore']:
            for k in range(8):
                start=b+k*0.5; n=int(0.15*RATE); t=np.arange(n)/RATE
                noise=rng.normal(0,1,n)
                hat=np.diff(noise,prepend=0)*np.exp(-t*55)*0.008
                if k in [0,4]: hat+=np.sin(2*np.pi*(78*t-85*t*t))*np.exp(-t*27)*0.15
                if k in [2,6]: hat+=noise*np.exp(-t*32)*0.025
                if name=='explore': hat*=0.42
                ix=(int(start*beat*RATE)+np.arange(n))%length
                np.add.at(mix[:,0],ix,hat*0.67); np.add.at(mix[:,1],ix,hat*0.72)
    dry=mix.copy()
    for delay,gain in [(0.071,0.12),(0.143,0.085),(0.227,0.055)]:
        mix+=np.roll(dry,int(delay*RATE),axis=0)[:,::-1]*gain
    mix=np.tanh(mix*1.25)*profile['gain']
    # Remove tiny DC offset. Notes decay across loop boundaries via circular mixing.
    mix-=mix.mean(axis=0)
    pcm=(np.clip(mix,-0.98,0.98)*32767).astype('<i2')
    wav=MASTERS/(name+'.wav')
    with wave.open(str(wav),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(pcm.tobytes())
    subprocess.run(['/Users/wangyuanlong/.local/bin/ffmpeg','-y','-hide_banner','-loglevel','error','-i',str(wav),'-c:a','libvorbis','-q:a','3',str(OUT/(name+'.ogg'))],check=True)
    return {'name':name,'seconds':len(mix)/RATE,'bpm':profile['bpm'],'sections':4,'events':len(events),'peak':float(np.abs(mix).max()),'rms':float(np.sqrt(np.mean(mix**2))),'loop_edge_delta':float(np.abs(mix[-1]-mix[0]).max()),'ogg_bytes':(OUT/(name+'.ogg')).stat().st_size}

if __name__ == '__main__':
    OUT.mkdir(parents=True,exist_ok=True); MASTERS.mkdir(parents=True,exist_ok=True)
    rows=[compose(name,profile) for name,profile in PROFILES.items()]
    assert all(row['peak']<0.98 and row['loop_edge_delta']<0.04 and row['seconds']>=24 for row in rows)
    (MASTERS/'metrics.json').write_text(json.dumps(rows,indent=2)+'\n')
    print(json.dumps(rows,indent=2))
