close("*");
setBatchMode(true);
//Stack dimensions
width = 400;
height = 400;
nFrames = 400;

//Create new image
newImage("Wave", "32-bit black", width, height, nFrames);

//Starting position of wave
xPos = 150;
yPos = 150;

//Starting diameter of the wave
diameter = -20;

//Starting velocity of wave (pixels per frame)
waveVel = 5;

//Rate of acceleration of the wave (0 = constant velocity);
waveAccel = 1;

//How much of a gaussian blur to apply to wave (higher blur = broader wave)
blur = 10;

for(a=1; a<=nFrames; a++){
	setSlice(a);
	if(diameter >= 1 && (xPos + 0.3 * diameter < width || xPos + 0.3 * diameter < height || xPos - 0.3 * diameter >= 0 || yPos - 0.3 * diameter >= 0)){
		makeOval(xPos-diameter/2, yPos-diameter/2, diameter, diameter);
		run("Draw", "slice");
		run("Select None");
	}
	waveVel += waveAccel;
	diameter += waveVel;

}
run("Select None");

//blur line
run("Gaussian Blur...", "sigma=10 stack");
run("Enhance Contrast...", "saturated=0.3 process_all use");;
run("8-bit");

//Crop to a 256x256 frame
run("Canvas Size...", "width=256 height=256 position=Center zero");

setBatchMode("exit & display");

