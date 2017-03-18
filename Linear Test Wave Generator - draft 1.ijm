close("*");

//Stack dimensions
width = 400;
height = 400;
nFrames = 100;

//Create new image
newImage("Wave", "32-bit black", width, height, nFrames);

//Starting position of wave
xPos = 0

//Starting velocity of wave (pixels per frame)
waveVel = 5

//Rate of acceleration of the wave (0 = constant velocity);
waveAccel = 0;

//How much of a gaussian blur to apply to wave (higher blur = broader wave)
blur = 10;

for(a=1; a<=nFrames; a++){
	setSlice(a);
	makeLine(xPos, 0, xPos, height);
	run("Draw", "slice");
	waveVel += waveAccel;
	xPos += waveVel;

	//blur line
	run("Gaussian Blur...", "sigma=10 slice");

	//Scale to 8-bit (max = 255)
	getStatistics(dummy, dummy, dummy, max);
	run("Multiply...", "value="+255/max+" slice");
}
run("Select None");

//Convert to 8-bit
setMinAndMax(0,255);
run("8-bit");

//Crop to a 256x256 frame
run("Canvas Size...", "width=256 height=256 position=Center zero");



