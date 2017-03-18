close("*");
open(File.openDialog("Choose a 16x stage II wave file."));
image = getTitle();

//Variable for nxn grid to measure velocity (ideally power of 2)
grid = 8;

//Variable for how many frames a wave can stall in a single grid box
waveGap = 2;

//Grid overlap (overlap ratio between neighboring grid squares) - 0 = raw grid, 1 = perfect overlap (infinite loop);
overlapRatio = 0.8

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
			waveStart = a;

			//If a start slice is found too close to the end, ignore start slice
			if(waveStart > nSlices-2) startFound = !startFound;				
		}
		
		//If slice mean < stack mean, then wave end has been found
		if(startFound && mean < stackMean){
			endFound = !endFound;

			//A -1 offset is needed to 
			waveEnd = a;

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
			
			waveFrontStack(waveStart, waveEnd, longestWave, grid, waveCount, waveGap);
			waveCount += 1;
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

function waveFrontStack(startSlice, endSlice, stackLength, grid, waveCount, waveGap){
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
	for(a=1; a<nSlices; a++){
		setSlice(a);
		run("Create Selection");
		run("Make Inverse");
		setSlice(a+1);
		setForegroundColor(255, 255, 255);
		run("Fill", "slice");
	}
	close("2-wave");

	//Rebuild the stack
	selectWindow("Result of 2-wave");
	rename("2-wave");

	//Create new window to measure wave velocity
	if(waveCount == 1){
		newImage("Wave Velocity ("+ grid + "x" + grid +"array)", "32-bit black", grid, grid, 1);
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
	getDimensions(width, height, channels, slices, frames);
	velocityArray = newArray(grid*grid);
	for(xGrid = 0; xGrid < grid; xGrid++){
		for(yGrid = 0; yGrid < grid; yGrid++){
			makeRectangle(xGrid*(width/grid), yGrid*(height/grid), width/grid, height/grid);
			waveEnter = nSlices + 1;
			waveLeave = 0;
			waveMean = 0;
			for(a=1; a<=nSlices; a++){
				setSlice(a);
				getStatistics(area, mean);

				//If the mean in the selection is > 0, wave has entered the box
				if(mean > 0 && waveEnter == nSlices + 1) waveEnter = a;

				//If wave has entered box, and mean stops changing, wave has exited the box
				else if(mean == waveMean && waveEnter <= nSlices) waveLeave = a;
				
				//If wave has not left the box at the end of the stack, it left the next frame
				else if(waveEnter <= nSlices && waveLeave == 0 && a == nSlices) waveLeave = a;

				//If the box mean changes by more than gap # of frames after a wave has left, count it as the new leave time (stalled wave)
				else if(mean > waveMean && a < waveLeave + waveGap) waveLeave = a;

				waveMean = mean;
				
			}
			//Store the wave velocity for that grid
			velocityArray[xGrid*grid + yGrid] = grid/(waveLeave - waveEnter);
		}
	}

	//output the array onto the Velocity image
	selectWindow("Wave Velocity ("+ grid + "x" + grid +"array)");
	for(a=0; a<grid; a++){
		for(b=0; b<grid; b++){
			setPixel(a, b, velocityArray[a*grid + b]);
		}
	}

	//Remove Velocity outliers
	run("Median...", "radius=2 slice");
	
	if(nImages == 4) run("Concatenate...", "  title=color image1=1-pre image2=2-wave image3=3-post image4=[-- None --]");
	if(nImages == 3) run("Concatenate...", "  title=color image1=2-wave image2=3-post image3=[-- None --] image4=[-- None --]");
	
}
