close("*");
open("C:\\Users\\Christian\\Documents\\ImageJ Macros\\Feller Lab\\Alex Retina Wave data\\Result of Result of 16x_sII_160818002 - div by avg - 2x2x2 med - 10x10 mean - 15x15 blur - dT.tif");
image = getTitle();

//Convert stack to 8-bit
setSlice(1);
run("Delete Slice");
run("Duplicate...", "duplicate title=color");
selectWindow("color");
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");
close(image);

//Find each wave and color code them
Stack.getStatistics(dummy, stackMean);
startFound = false;
endFound = false;
longestWave = 0;

for(a=1; a<=nSlices; a++){
		setSlice(a);
		getStatistics(dummy, mean);

		//If slice mean > stack mean, then wave start has been found
		if(!startFound && mean > stackMean){
			startFound = !startFound;
			waveStart = a;

			//If a start slice is found too close to the end, ignore start slice
			if(waveStart > nSlices-2) startFound = !startFound;				
		}
		
		//If slice mean < stack mean, then wave end has been found
		if(startFound && mean < stackMean){
			endFound = !endFound;

			//A -1 offset is needed to 
			waveEnd = a;
		}

		//If a full wave is found, remove it from the stack and analyze it
		if(startFound && endFound){
			startFound = !startFound;
			endFound = !endFound;
			
			temporalColorCode(image, waveStart, waveEnd, longestWave);
		}
		
		//Otherwise, data is not a wave, so clear slice
		if (!startFound && !endFound){
			setSlice(a);
			run("Select All");
			setBackgroundColor(0, 0, 0);
			run("Clear", "slice");
			run("Select None");
		}		
}

//Color the stack using a modified physics LUT
run("physics");
getLut(reds, greens, blues);
reds[0] = 0;
greens[0] = 0;
blues[0] = 0;
setLut(reds, greens, blues);
run("RGB Color");
run("Volume Viewer");

function temporalColorCode(image, startSlice, endSlice, stackLength){
	//Remove the preceding substack so that it can be concatenated back on later
	selectWindow("color");
	rename("3-post");
	run("Make Substack...", "delete slices=1-" + startSlice - 1);
	selectWindow("Substack (1-" + startSlice-1 + ")");
	rename("1-pre");

	//Remove the substack containing the wave
	selectWindow("3-post");
	run("Make Substack...", "delete slices=1-" + endSlice - startSlice);
	selectWindow("Substack (1-" + endSlice-startSlice + ")");
	rename("2-wave");

	//Create a mask of the wave
	run("Duplicate...", "duplicate title=mask");
	setAutoThreshold("Huang dark stack");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Huang background=Dark black");
	run("Divide...", "value=255 stack");

	//Clear background signal from stack
	imageCalculator("Multiply stack", "2-wave","mask");	
	close("mask");

	//find where each pixel peaks in intensity
	selectWindow("2-wave");
	run("Z Project...", "projection=[Max Intensity]");
	imageCalculator("Divide create 32-bit stack", "2-wave","MAX_2-wave");
	selectWindow("Result of 2-wave");
	setMinAndMax(0.9990, 1.0000);
	run("8-bit");
	close("MAX_2-wave");

	//Code the time of the wave via intensity
	selectWindow("Result of 2-wave");
	for(a=1; a<=nSlices; a++){
		setSlice(nSlices - a + 1);
		dIntensity = (a/nSlices)*254;
		run("Subtract...", "value=" + dIntensity + " slice");
	}
	close("2-wave");

	//Rebuild the stack
	selectWindow("Result of 2-wave");
	rename("2-wave");
	run("Concatenate...", "  title=color image1=1-pre image2=2-wave image3=3-post image4=[-- None --]");
}
