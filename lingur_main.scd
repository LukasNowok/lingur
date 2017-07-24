//prepare fftbuffer first
(
var sf;
// path to a sound file here
p =;
// the frame size for the analysis - experiment with other sizes (powers of 2)
~fftSize = 8192*4;
// the hop size
h = 0.25;
// get some info about the file
sf = SoundFile.new( p );
sf.openRead;
sf.close;
// allocate memory to store FFT data to... SimpleNumber.calcPVRecSize(frameSize, hop) will return
// the appropriate number of samples needed for the buffer
y = Buffer.alloc(s, sf.duration.calcPVRecSize(~fftSize, h));
// allocate the soundfile you want to analyze
z = Buffer.readChannel(s, p, channels:0);

// this does the analysis and saves it to buffer 1... frees itself when done
SynthDef("pvrec", { arg bufnum=0, recBuf=1, soundBufnum=2;
	var in, chain;
	Line.kr(1, 1, BufDur.kr(soundBufnum), doneAction: 2);
	in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 0);
	bufnum = LocalBuf.new(~fftSize, 1); // uses frame size from above
	// note the window type and overlaps... this is important for resynth parameters
	chain=FFT(bufnum, in, 0.25, 1);
	chain=PV_Diffuser(chain,1);
	chain=PV_RecordBuf(chain, recBuf, 0, 1, 0, 0.25, 1);
	// no ouput ... simply save the analysis to recBuf
}).send(s);
)
a = Synth("pvrec", [\recBuf, y, \soundBufnum, z]);
// you can save your 'analysis' file to disk! I suggest using float32 for the format
// These can be read back in using Buffer.read
y.write(p++".scpv", "wav", "float32");


p=ProxySpace.push;
(
//load .scpv file (fftbuffer)
Buffer.read(s, ,bufnum:2);

(SynthDef(\fftbuf,
	{
		arg pointer=0,buf=0,out=0,pitch=1,amp=0;
		var fftbuf,chain,windowSize,sig;
		windowSize=8192*4;
		fftbuf=LocalBuf.new(windowSize);
		chain=PV_BufRd(fftbuf,buf,pointer);
		chain=PV_BinShift(chain,pitch);
		sig=IFFT(chain,0);
		sig=sig*amp;
		//outSig=outSig+DelayN.ar(outSig,windowSize/SampleRate.ir,(windowSize/SampleRate.ir)/2);
		Out.ar(out,[sig,DelayN.ar(sig,0.2,0.2)]);
	}
).add)

SynthDef(\click,
	{
		arg amp=0.5,out=6;
		var sig;
		sig=Impulse.ar(0,0,amp);
		FreeSelf.kr(sig,);
		Out.ar(out,sig);
	}
).add;
SynthDef(\sin,
	{
		arg freq=50,out=8,attack=0,sustain=5,release=0,amp=1;
		var sig,env;
		env=EnvGen.kr(Env([0,1,1,0],[attack,sustain,release]),doneAction:2);
		sig=SinOsc.ar(freq,1.57);
		sig=sig+Impulse.ar(0,0,10);
		//sig=sig+SinOsc.ar(freq*512,mul:amp*0.25);
		sig=sig*amp*env;
		Out.ar(out,sig);

		SendReply.kr(DC.kr(1), '/sin', sustain);
	}
).add;
)

(
(
Pdef(\iko,
	Pbind(
		//\instrument,\click,
		\instrument,\sin,
		\freq,15000,
		\amp,0.01,
		\out,Prand([2,3],inf),
		\dur,Pseq(Morse.word("it cannot be that when the root is neglected that what should spring from it will be well ordered").flat,inf)*2,
		\sustain,Pkey(\dur)*0.25,
	)
).play(quant:1));

(
Pdef(\ike,
	Pbind(
		\instrument,\click,
		\amp,0.2,
		\out,Prand([2,3],inf),
		\dur,Pseq(Morse.word("it cannot be that when the root is neglected that what should spring from it will be well ordered").flat,inf)*2,
	)
).play(quant:1));

(
Pdef(\sin,
	Pbind(
		\instrument,\sin,
		\freq,50,
		\amp,0.3,
		\sustain,4,
		\release,10,
		\out,4,
		\dur,Pwhite(20,50),
	)
).play(quant:1));

//drone
~sa=\fftbuf;
~sa.set(\buf,2);
~sa.set(\pitch,0.44);
~ranp=1;
~sa.map(\pointer,~see);
//~see={SinOsc.kr(0.003).range(0.1,0.2)};
~see={SinOsc.kr(0.002).range(0.1,0.9)};
//~see={Line.kr(0.1,0.6,8*60)};
~sa.map(\amp,~ranp);
~sa.play;
)
