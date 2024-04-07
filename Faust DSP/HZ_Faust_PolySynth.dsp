declare name "Hanzhi's synth instrument";
declare author "Hanzhi Zhang";
declare copyright "Hanzhi Zhang";
declare date "Oct 22 2021";
declare version "1.0";
declare option "[nvoices:64]";

import("stdfaust.lib");

/*
This program is a subtractive synthsizer instrument made by Hanzhi in Oct 2021. 

It has three blocks of sounds that a user can generate, just like the virtual synthesizer software "serum." It includes two waveforms of basic shapes (sine, square, triangle, sawtooth) and a block of noise generator. Users could choose the sounds they want by doing a combination of the three blocks. 

There are two ways to generate the sounds in the synthesizer: (1) the first one is to choose a freq on the top and hit "gate" button to generate a single note (2) the second one is to use a midi keyboard to play polyphonic notes (to use a midi keyboard on the online complier, such as faustide.grame.fr, users need to check the "MIDI input" on the top right corner, and change the "Poly Voices" on the left bar to make sure it's not mono)

Below are several post effects of the synth sound. The highpass and the lowpass filters are connected linearly with the synth, while the rest of the plugins are connected in parallel. This is for the purpose of making the best use of all the effects applied in the program. 

The presets of the faders are supposed to be at the initial state, where synth is turned on and effects are turned off. If users turned the output faders of the effects up, then they will hear the presets (made by me) of the effects. I hope the presets will give them a general feeling of these plugins and they could then play around with them. 

Users should open the Faust IDE and the DSP file in Google Chrome. 

Note that users could also hold their mouse cursor onto each fader to get more information.


*/

//define general parameters
freq = hslider("[0]freq[unit:_Hz] 
[tooltip: 2 ways to generate sounds: 
(1) choose frequency of freq fader and press gate button; 
(2) use midi input to play polyphonic notes (no need to trigger freq and gate in this way)]", 261, 0, 4186, 1) : si.polySmooth(1, 0.999, 0) ; //frequency range from 0 to the note C8, support midi control
bend = ba.semi2ratio(hslider("[1]Pitchwheel[midi:pitchwheel] 
[tooltip: (1) use the pitch wheel by change the slider or (20 play with the pitch bend on your midi keyboard]",0,-3,3,0.1)) : si.smoo;

gain = hslider("[2]gain 
    [tooltip: gain: 0 is minimum, 1 is maximum. ***important: you have to turn all sliders named 'gain' (not 'output gain') in order to hear sound ]", 0.5, 0, 1, 0.01) : si.polySmooth(1, 0.999, 0); //gain from 0 to 1
switch = checkbox("[0]on/off 
    [tooltip: switch: turn the synth on/off]"); //a switch used to control if the synth instrument is turned on/off
gate = button("[2]gate 
[tooltip: 2 ways to generate sounds: 
(1) choose frequency of freq fader and press gate button; 
(2) use midi input to play polyphonic notes (no need to trigger freq and gate in this way)]"); //gate used to trigger the synth

//this part is the envelope generator, including attack, decay, sustain and release
attack = nentry("[0]attack[style:knob][unit:_ms]
[tooltip: attack: the envelope attack of synth, from 0 ms to 1500 ms]", 50, 0, 1500, 1) / 1000; //attack range from 0 ms to 1500 ms/1.5 s
decay = nentry("[1]decay[style:knob][unit:_ms]
[tooltip: decay: the envelope decay of synth, from 0 ms to 1500 ms]", 200, 0, 1500, 1) / 1000; // decay range from 0 ms to 1500 ms/1.5 s
sustain = nentry("[2]sustain[style:knob]
[tooltip: sustain: the envelope sustain of synth, 0 is minimum, 1 is maximum]", 0.5, 0.0, 1.0, 0.01) ; // sustain range from 0-1 linear
release = nentry("[3]release[style:knob][unit:_ms]
[tooltip: release: the envelope release of synth, from 0 ms to 1500 ms]", 200, 0, 1500, 1) / 1000; // release range from 0 ms to 1500 ms/1.5 s
env = en.adsr(attack,decay,sustain,release); // *****

// the first synth generator, using the default library functions
sin1(freq) = os.oscsin(freq);        //sine wave
sqr1(freq) = os.lf_squarewave(freq);     //square wave
tri1(freq) = os.triangle(freq);   //triangle wave
saw1(freq) = os.sawtooth(freq);   //sawtooth wave
select_1(f) = sin1(f),sqr1(f),tri1(f),saw1(f) : ba.selectn(4, nentry("[1]waveform
[tooltip: waveform: select the basic waveform shape you want to generate: 0 is sine, 1 is square, 2 is triangle, 3 is sawtooth. Designed with library functions.]
",0,0,3,1)) : _;


// the second synth generator, using rdtable to generate

//sine wave
tablesize = 1000; //define a table size for os.sinwaveform
sin2(f) = tablesize, os.sinwaveform(tablesize), int(os.phasor(tablesize,f)) : rdtable; //sin wave
//square wave
sqr_waveform = waveform{1,1,1,1,1, 1,1,1,1,1, -1,-1,-1,-1,-1, -1,-1,-1,-1,-1};
sqr2(f) = sqr_waveform, int(os.phasor(20,f)) : rdtable; //cos wave
//triangle wave
tri_waveform = waveform{0,0.25,0.5,0.75,1.0,  0.75,0.5,0.25,  0,-0.25,-0.5,-0.75,-1.0, -0.75,-0.5,-0.25};
tri2(f) = tri_waveform, int(os.phasor(16,f)) : rdtable; //triangle wave
//sawtooth wave
saw_waveform = waveform{1,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1, 0, -0.1,-0.2,-0.3,-0.4,-0.5,-0.6,-0.7,-0.8,-0.9,-1}; 
saw2(f) = saw_waveform, int(os.phasor(21,f)) : rdtable; //sawtooth wave

select_2(f) = sin2(f),sqr2(f),tri2(f),saw2(f) : ba.selectn(4, nentry("[1]waveform2 
[tooltip: waveform2: select the basic waveform shape you want to generate: 0 is sine, 1 is square, 2 is triangle, 3 is sawtooth. Designed by the author with rdtable functions.]",0,0,3,1)) : _;


//noise generator
noise1 = no.noise /4 ; //white noise
noise2 = no.pink_noise; //pink noise
select_3 = noise1, noise2 : ba.selectn(2, nentry("[1]noise
[tooltip: noise: select the noise shape you want to generate: 0 is white noise, 1 is pink noise]",1,0,1,1)) : _;



//the final statement of instruments
inst = freq*bend <: hgroup("[2]Waveform", ( vgroup("[0]Wave 1", select_1 * gain * switch) + vgroup("[1]Wave 2", select_2 * (gain/2) * switch) + vgroup("[2]Noise", select_3 * gain * switch)) ) * ( gate : hgroup("[3]Envelope[tooltip: Envelope: design the envelope shape (ADSR) of your sound] ", env) ) <: _,_ ;


//effects
//compressor
cpr =  _,_ :> co.compressor_lad_mono(lad_c,ratio_c,thresh_c,att_c,rel_c) <: out_gain_c
with{
    lad_c = 0; //look ahead delay in seconds
    ratio_c = vslider("[4]ratio 
    [tooltip: compression ratio: 1 is no compression, >1 means compression, 4 is moderate compression, 8 is strong compression] ", 9.5, 1, 10, 0.01) : si.smoo;
    thresh_c = vslider("[3]thresh[unit:_dB] 
    [tooltip: thresh: dB level threshold above which compression kicks in (0 dB = max level)]", -18, -20, 0, 0.01) : si.smoo ;
    att_c = vslider("[1]attack[unit:_ms] 
    [tooltip: attack time: time constant when level & compression are going up]", 0, 0, 200, 1)/1000 ;
    rel_c = vslider("[2]release[unit:_ms] 
    [tooltip: release time: time constant coming out of compression]", 0, 0, 200, 1)/1000;
    out_gain_c = _,_ :> *(vslider("Output Gain 
    [tooltip: output gain: gain after compression, 0 is minimum, 1 is maximum ]", 0, 0, 1, 0.01))  <: _,_;
} ;
compressor = hgroup("[4]Compressor", cpr);

//compressor 2 (a backup plan if my compressor doesn't work)
compressor2 = dm.compressor_demo;


//reverb 1 (I use reverb2 because reverb 1 takes too much processing power of google chrome, delete the "/*" and change "reverb2" to "reverb" in "process = if you need the reverb)
rvb = re.jpverb( t60_r, damp_r, size_r, early_diff_r, mod_depth_r, modFreq_r, low_r, mid_r, high_r, lowcut_r, highcut_r)
with{
    t60_r = vslider("[2]Time[unit:_sec] 
    [tooltip: T60: approximate reverberation time in seconds. T60 means the time for the reverb to decay by 60dB] ", 0, 0, 10, 0.01);
    damp_r = vslider("[3]Damp 
    [tooltip: Damp: damping of high freq as the reverb decays. 0 is no damping, 1 is very strong damping]", 0.6, 0, 1, 0.01); 
    size_r = vslider("[4]Size 
    [tooltip: Size: size of the simulated space. space becomes larger when value is bigger. (values below 1 can sound metallic)]", 3, 0.5, 5, 0.01);
    early_diff_r = 0.707;
    mod_depth_r = 0;
    modFreq_r = 0;
    low_r = vslider("[5]Low 
    [tooltip: Low Band: multiplier for the reverberation time within the low band]", 0, 0, 1, 0.01);
    mid_r = vslider("[6]Mid 
    [tooltip: Mid Band: multiplier for the reverberation time within the mid band]", 0, 0, 1, 0.01);
    high_r = vslider("[7]High 
    [tooltip: High Band: multiplier for the reverberation time within the high band]", 0, 0, 1, 0.01);
    lowcut_r = vslider("[8]Lowcut[unit:_Hz] 
    [tooltip: Lowcut: freq at which the crossover between the low and mid bands of the reverb occurs]", 100, 100, 6000, 1);
    highcut_r = vslider("[9]Highcut[unit:_Hz] 
    [tooltip: Highcut: freq at which the crossover between the mid and high bands of the reverb occurs]", 10000, 1000, 10000, 1);
};
wet_dry(x,y) = (*(wet) + dry*x) , (*(wet) + dry*y) : _,_
with{
    drywet = vslider("[1]Dry/Wet Mix 
    [tooltip: Dry/Wet Mix: the ratio of signal with/without reverb. -1 is wet(full reverb), 1 is dry (no reverb)]", -1.0, -1.0, 1.0, 0.01);
    wet = 0.5* (drywet+1);
    dry = 1 - wet;
};
out_gain_r = _,_ :> *(vslider("[0]Output Gain 
[tooltip: output gain: gain after reverb, 0 is minimum, 1 is maximum]", 0, 0, 1, 0.01) : si.smoo ) <: _,_;
reverb = hgroup("[5]Reverb 
[tooltip: Reverb: an algorithmic reverb]", ( _,_ <: rvb, _,_ : wet_dry : out_gain_r) );

//reverb 2 (a backup plan if my reverb doesn't work)
reverb2 = hgroup("[5]Reverb", dm.zita_rev1);

//delay (It takes too much memory and the online compiler cannot run it. Thus I put it into comments.)
/*
del = _,_ :> de.delay(n,d) <: out_gain_d 
with{
    n = 5*ma.SR;
    d = 5* ma.SR;
    out_gain_d = _,_ :> *(vslider("Output Gain", 0, 0, 1, 0.01)) <: _,_;
};
delay = hgroup("delay", delay);
*/

//low pass filter
lpf = _,_ :> fi.lowpass6e(fc) <: out_gain_lpf 
with {
    fc = vslider("[1]cutoff freq[unit:_Hz] 
    [tooltip: cutoff freq: -3dB freq in Hz]", 12000, 20, 12000, 1) : si.polySmooth(1, 0.999, 0);
    out_gain_lpf = _,_ :> *(vslider("[0]gain 
    [tooltip: output gain: gain after low pass filter, 0 is minimum, 1 is maximum. ***important: you have to turn all sliders named 'gain' (not 'output gain') in order to hear sound]", 0.3, 0, 1, 0.01) : si.smoo ) <: _,_;
};
lp_filter = hgroup("[6]Low Pass Filter 
    [tooltip: Low Pass Filter: a 6th-order lowpass filter]", lpf);

//high pass filter
hpf = _,_ :> fi.highpass6e(fc) <: out_gain_hpf 
with {
    fc = vslider("[1]cutoff freq[unit:_Hz] 
    [tooltip: cutoff freq: -3dB freq in Hz]", 20, 20, 12000, 1) : si.polySmooth(1, 0.999, 0); 
    out_gain_hpf = _,_ :> *(vslider("[0]gain 
    [tooltip: output gain: gain after low pass filter, 0 is minimum, 1 is maximum. ***important: you have to turn all sliders named 'gain' (not 'output gain') in order to hear sound]", 0.3, 0, 1, 0.01) : si.smoo ) <: _,_;
};
hp_filter = hgroup("[7]High Pass Filter 
    [tooltip: High Pass Filter: a 6th-order highpass filter]", hpf); 


//phaser
phs = _,_ : pf.phaser2_stereo(Notches,width,frqmin,fratio,frqmax,speed,depth,fb,invert) : out_gain_phs 
with {
    Notches = 1;
    width = 10; 
    //vslider("[2]Notch width[unit:_Hz] 
    //[tooltip: Notch width: approximate width of spectral notches in Hz]", 10, 10, 50, 0.1);
    frqmin = vslider("[3]Min Notch freq[unit:_Hz] 
    [tooltip: Min Notch freq: approximate minimum freq of first spectral notch in Hz. When Min Notch freq is turned up, Max Notch freq should be turned down (important!!)]", 20, 20, 9500, 1) : si.smoo ;
    frqmax = vslider("[4]Max Notch freq[unit:_Hz] 
    [tooltip: Max Notch freq: approximate maximum freq of first spectral notch in Hz. When Max Notch freq is turned up, Min Notch freq should be turned down(important!!)]", 9500, 20, 9500, 1) : si.smoo ;
    fratio = vslider("[5]Notch freq ratio 
    [tooltip: Notch freq ratio: ratio of adjacent notch freq]", 1, 1, 4, 0.01) : si.smoo ;
    speed = vslider("[1]Speed[unit:_Hz] 
    [tooltip: Speed: LFO freq in Hz (rate of periodic notch sweep cycles)]", 7.7, 0, 10, 0.1) : si.smoo ;
    depth = vslider("[6]Depth 
    [tooltip: Depth: effect strength between 0 and 1", 0.65, 0, 1, 0.01);
    fb = vslider("[7]Feedback Gain 
    [tooltip: Feedback Gain: feedback gain between -1 and 1 (0 typical)]", 0, -1, 1, 0.01) : si.smoo ;
    invert = 0;
    //vslider("[8]Invert 
    //[tooltip: Invert: 0 for normal, 1 to invert sign of phasing sum]", 0, 0, 1, 1);
    out_gain_phs = _,_ :> *(vslider("[0]Output Gain 
    [tooltip: output gain: gain after low pass filter, 0 is minimum, 1 is maximum]", 0, 0, 1, 0.01) : si.smoo ) <: _,_;
};
phaser = hgroup("[10]Phaser", phs);

//phaser 2 (a backup plan)
phaser2 = dm.phaser2_demo;

//flanger
flg = _,_ : pf.flanger_stereo(dmax,curdel,curdel,depth,fb,invert) : out_gain_flg 
with{
    dmax = 1000;
    curdel = vslider("[3]Flange Delay [unit:_ms]", 0, 0, 1000, 0.01) : si.smoo ;
    //curdel2 = vslider("[4]Flange Delay 2", 0, 0, 1000, 0.01);
    depth = vslider("[1]Depth 
    [tooltip: Depth: effect strength between 0 and 1]", 0.6, 0, 1, 0.01);
    fb = vslider("[2]Feedback Gain 
    [tooltip: Feedback Gain: feedback gain between -1 and 1 (0 typical)]", 0.9, 0, 1, 0.01) : si.smoo ;
    invert = 0;
    //vslider("[3]Invert 
    //[tooltip: Invert: 0 for normal, 1 to invert sign of flanging sum]", 0, 0, 1, 1);
    out_gain_flg = _,_ :> *(vslider("[0]Output Gain 
    [tooltip: output gain: gain after low pass filter, 0 is minimum, 1 is maximum]", 0, 0, 1, 0.01) : si.smoo ) <: _,_;
} ;
flanger = hgroup("[9]Flanger", flg);

//flanger 2 (a backup plan)
flanger2 = dm.flanger_demo;


//wah 
wwa = _,_ :> ve.wah4(fr) <: out_gain_wwa 
with{
    fr = vslider("[1]Resonance Freq[unit:_Hz] 
    [tooltip: Resonance Freq: resonance freq in Hz]", 261, 0, 3000, 1) : si.smoo ;
    out_gain_wwa = _,_ :> *(vslider("[0]Output Gain 
    [tooltip: output gain: gain after low pass filter, 0 is minimum, 1 is maximum]", 0, 0, 1, 0.01) : si.smoo ) <: _,_;
};
wah = hgroup("[8]Wah 
    [tooltip: wah effect, 4th order]", wwa);

//wah 2
wah2 = dm.wah4_demo;

//final statement of effect

effects1 =  vgroup("[5]effect 2 [tooltip: plugins parallel connected to the synth]", compressor, reverb) , vgroup("[6]effect 3 [tooltip: plugins parallel connected to the synth]", phaser, hgroup("Wah and Flanger", flanger, wah ) ) ; 
effects2 = _,_ : vgroup("[4]effect 1 [tooltip: plugins linearly connected to the synth]", lp_filter : hp_filter) : _,_ ; 
effects = hgroup("[4]effect", effects2 <: effects1 , _,_ );


process = inst : effects :> _,_ ;


