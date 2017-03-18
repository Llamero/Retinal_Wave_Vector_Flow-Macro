close("*");
setBatchMode(true);
open(File.openDialog("Choose a 16x stage II wave file."));
image = getTitle();
getDimensions(width, height, channels, slices, frames);

//Variable for size of grid as nxn grid to measure velocity (ideally power of 2)
grid = 8;

//Width divisor step size for translating grid square (ideally power of 2)
step = 128;

//8-bit intensity threshold for finding a wave in dt stack.
waveThreshold = 20;

//Variable for how many frames a wave can stall in a single grid box
waveGap = 2;

//SLices to add to either side of detected wave (increase window size)
waveAddSlice = 3;

//Calculate final variables and double check validity
if(step < grid){
	exit("stepDvisor needs to be >= grid in order for no gaps between grid squares");
}
 

if(!matches(image, "color.tif")){
//Process the filter to remove noise and isolate waves
//Generate dF/F stack
run("Z Project...", "projection=[Average Intensity]");
imageCalculator("Divide create 32-bit stack", image,"AVG_" + image);
close(image);
close("AVG_" + image);
selectWindow("Result of " + image);
rename("dF Stack");

//Remove noise and enrich for wave signal
//remove pixel noise
run("Median 3D...", "x=2 y=2 z=2");
//solidify waves
run("Mean...", "radius=10 stack");
//enrich for spatial frequencies containing waves
//run("Gaussian Blur...", "sigma=15 stack");

//Calculate dF/dt stack
//Create a duplicate stack offset forward one frame in time
run("Duplicate...", "title=offset duplicate");
selectWindow("offset");
run("Reverse");
setSlice(nSlices);
run("Add Slice");
run("Reverse");

//Add a corresponding blank frame to the end of the original stack
selectWindow("dF Stack");
setSlice(nSlices);
run("Add Slice");

//Calculate the dT stack
imageCalculator("Subtract create 32-bit stack", "dF Stack","offset");
close("offset");
close("dF Stack");
selectWindow("Result of dF Stack");

//Convert stack to 8-bit
setSlice(1);
run("Delete Slice");
run("Duplicate...", "duplicate title=color");
selectWindow("color");
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");
close("Result of dF Stack");
}
else{
	rename("color");
}

//Find each wave and color code them
Stack.getStatistics(dummy, stackMean);
startFound = false;
endFound = false;
longestWave = 0;
waveCount = 1;

for(a=1; a<=nSlices; a++){
		selectWindow("color");
		setSlice(a);
		getStatistics(dummy, mean);

		//If slice mean > stack mean, then wave start has been found
		if(!startFound && mean > stackMean){
			startFound = !startFound;
			waveStart = a - waveAddSlice;
			if(waveStart<1) waveStart = 1;

			//If a start slice is found too close to the end, ignore start slice
			if(waveStart > nSlices-2) startFound = !startFound;				
		}
		
		//If slice mean < stack mean, then wave end has been found
		if(startFound && mean < stackMean){
			endFound = !endFound;

			//A -1 offset is needed to 
			waveEnd = a + waveAddSlice;
			if(waveEnd > nSlices) waveEnd = nSlices;

			//If the end is too close or too far to the start, not a real wave
			if(waveEnd-waveStart < 3 || waveEnd-waveStart > 50){
				startFound = !startFound;
				endFound = !endFound;
			}
		}

		//If a full wave is found, remove it from the stack and analyze it
		if(startFound && endFound){
			startFound = !startFound;
			endFound = !endFound;

			waveFrontStack(waveStart, waveEnd, longestWave, grid, waveCount, waveGap, step, waveThreshold);
			
			waveCount += 1;
			a = waveEnd;
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

//Expand the velocity grid to original size
selectWindow("color");
getDimensions(width, height, channels, slices, frames);
selectWindow("Wave Velocity ("+ grid + "x" + grid +"array)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
setBatchMode("exit & display");

function waveFrontStack(startSlice, endSlice, stackLength, grid, waveCount, waveGap, step, waveThreshold){
	//Remove the preceding substack so that it can be concatenated back on later
	selectWindow("color");
	rename("3-post");
	//If the start slice is at the beginning of hte movie, do not remove a pre stack
	if(startSlice > 2){
		run("Make Substack...", "delete slices=1-" + startSlice - 1);
		selectWindow("Substack (1-" + startSlice-1 + ")");
		rename("1-pre");
	}

	//Remove the substack containing the wave
	selectWindow("3-post");
	run("Make Substack...", "delete slices=1-" + endSlice - startSlice);
	selectWindow("Substack (1-" + endSlice-startSlice + ")");
	rename("2-wave");

	//Create new window to measure wave velocity
	getDimensions(width, height, channels, slices, frames);
	if(waveCount == 1){
		newImage("Wave Velocity ("+ grid + "x" + grid +"array)", "32-bit black", step, step, 1);
		setMetadata("Label", "Wave " + waveCount);
	}
	else{
		selectWindow("Wave Velocity ("+ grid + "x" + grid +"array)");
		setSlice(nSlices);
		run("Add Slice");	
		setSlice(nSlices);
		setMetadata("Label", "Wave " + waveCount);
	}

	//Measure the transit time of the wave through each grid point
	selectWindow("2-wave");
	velocityArray = newArray(step*step);
	for(xGrid = 0; xGrid < step; xGrid++){
		showProgress(xGrid/step);
		for(yGrid = 0; yGrid < step; yGrid++){
			makeRectangle(((xGrid + 0.5)*width/step-0.5*width/grid), ((yGrid + 0.5)*height/step-0.5*height/grid), width/grid, height/grid);
//			wait(100);
			waveEnter = nSlices + 1;
			waveLeave = 0;
			waveMean = 0;

			//Find wave passing through grid box
			for(a=1; a<=nSlices; a++){
				setSlice(a);
				getStatistics(area, mean);

				//If the mean in the selection is > 0, wave has entered the box
				if(mean > waveThreshold && waveEnter == nSlices + 1) waveEnter = a;

				//If wave has entered box, and mean drops below threshold, wave has exited the box
				else if(mean < waveThreshold && waveEnter <= nSlices) waveLeave = a;
				
				//If wave has not left the box at the end of the stack, it left the next frame
				else if(waveEnter <= nSlices && waveLeave == 0 && a == nSlices) waveLeave = a;

				waveMean = mean;
				
			}
			//Store the wave velocity for that grid
			velocityArray[xGrid*step + yGrid] = grid/(waveLeave - waveEnter);
		}
	}

	//output the array onto the Velocity image
	selectWindow("Wave Velocity ("+ grid + "x" + grid +"array)");
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, velocityArray[a*step + b]);
		}
	}

	//Remove Velocity outliers
	run("Median...", "radius=2 slice");

	//Create a mask of the wave
	selectWindow("2-wave");
	run("Select None");
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
	for(a=1; a<nSlices; a++){
		setSlice(a);
		run("Create Selection");

		if(selectionType() == 9){
			run("Make Inverse");
			setSlice(a+1);
			setForegroundColor(255, 255, 255);
			run("Fill", "slice");
		}
	}
	close("2-wave");

	//Rebuild the stack
	selectWindow("Result of 2-wave");
	rename("2-wave");
	
	if(nImages == 4) run("Concatenate...", "  title=color image1=1-pre image2=2-wave image3=3-post image4=[-- None --]");
	if(nImages == 3) run("Concatenate...", "  title=color image1=2-wave image2=3-post image3=[-- None --] image4=[-- None --]");

}
