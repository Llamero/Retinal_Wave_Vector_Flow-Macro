close("*");
setBatchMode(true);
fileOpen = File.openDialog("Choose a 16x stage II wave file.");
open(fileOpen);
image = getTitle();
getDimensions(width, height, channels, slices, frames);

//Variable for size of grid as nxn grid to measure velocity (ideally power of 2)
grid = 8;

//Width divisor step size for translating grid square (ideally power of 2)
step = 16;

//8-bit intensity threshold for finding a wave in dt stack.
waveThreshold = 1;

//Variable for how many frames a wave can stall in a single grid box
waveGap = 2;

//SLices to add to either side of detected wave (increase window size)
waveAddSlice = 3;

//Calculate final variables and double check validity
if(step < grid){
	exit("stepDvisor needs to be >= grid in order for no gaps between grid squares");
}
 

if(!matches(image, "Objects map of dF Stack.tif")){
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

//Create a mask of just the stage III waves
run("Duplicate...", "duplicate title=mask");
setAutoThreshold("Triangle dark stack");
setOption("BlackBackground", false);
run("Convert to Mask", "method=Triangle background=Dark black");	
run("Divide...", "value=255 stack");

//Clear background signal from stack
imageCalculator("Multiply stack", "dF Stack", "mask");	
close("mask");

//Convert to 8-bit and create an object map sementing each wave
selectWindow("dF Stack");
run("Duplicate...", "title=[1.tif] duplicate");
selectWindow("1.tif");
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 redirect_to=none");run("3D Objects Counter", "threshold=1 slice=900 min.=1000 max.=29491200 objects statistics"); //1000 min size cutoff to remove non-wave phenomena
selectWindow("Objects map of 1.tif");
rename("Objects map of dF Stack");
close("1.tif");

//Calculate dF/dt stack
//Create a duplicate stack offset forward one frame in time
selectWindow("dF Stack");
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
run("Duplicate...", "duplicate title=[dF Stack]");
selectWindow("dF Stack");
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");
close("Result of dF Stack");

//Create random lUT and apply to objects map
selectWindow("Objects map of dF Stack");
reds = newArray(0, 231, 25, 27, 112, 89, 53, 77, 155, 153, 91, 19, 25, 135, 187, 40, 52, 39, 147, 72, 92, 23, 5, 202, 52, 50, 108, 66, 238, 46, 136, 8, 162, 126, 75, 60, 135, 167, 136, 244, 161, 204, 158, 112, 192, 2, 98, 207, 233, 121, 191, 18, 210, 151, 252, 155, 139, 42, 188, 170, 127, 151, 38, 16, 227, 120, 137, 2, 72, 71, 214, 130, 194, 96, 102, 33, 92, 47, 211, 226, 237, 132, 244, 45, 82, 73, 239, 198, 118, 191, 170, 238, 177, 246, 66, 5, 44, 3, 18, 40, 226, 94, 130, 216, 68, 89, 150, 40, 96, 155, 95, 5, 132, 88, 124, 241, 143, 15, 1, 220, 46, 220, 216, 155, 190, 4, 98, 33, 142, 153, 185, 61, 153, 160, 164, 102, 75, 8, 26, 231, 160, 245, 119, 69, 95, 137, 232, 249, 89, 220, 54, 3, 43, 134, 172, 31, 106, 234, 132, 1, 29, 65, 12, 107, 52, 196, 95, 165, 4, 101, 124, 240, 203, 50, 142, 231, 5, 23, 43, 198, 41, 80, 66, 232, 86, 151, 126, 51, 122, 111, 162, 192, 148, 210, 5, 251, 40, 176, 32, 2, 22, 91, 180, 31, 218, 9, 10, 178, 27, 115, 54, 199, 163, 10, 180, 222, 102, 198, 202, 220, 96, 145, 237, 127, 172, 51, 64, 47, 84, 37, 196, 147, 244, 206, 244, 43, 170, 186, 162, 157, 125, 230, 212, 140, 186, 127, 12, 48, 0, 92, 168, 73, 228, 121, 248, 255);
greens = newArray(0, 217, 131, 18, 66, 198, 59, 170, 108, 8, 167, 207, 248, 138, 215, 204, 95, 249, 102, 66, 1, 138, 71, 33, 209, 80, 72, 87, 129, 24, 200, 98, 16, 160, 47, 1, 224, 49, 126, 41, 235, 205, 84, 249, 222, 125, 5, 58, 90, 137, 73, 98, 109, 167, 91, 106, 68, 23, 10, 241, 51, 35, 77, 112, 243, 235, 53, 41, 21, 134, 106, 60, 231, 107, 124, 96, 131, 62, 213, 220, 78, 96, 44, 106, 128, 96, 129, 164, 59, 86, 45, 87, 237, 192, 171, 93, 223, 206, 158, 42, 255, 175, 142, 177, 48, 67, 221, 123, 125, 182, 135, 31, 163, 211, 220, 28, 81, 113, 235, 236, 30, 104, 238, 227, 18, 134, 193, 15, 122, 151, 6, 132, 0, 128, 88, 20, 130, 87, 127, 55, 13, 76, 15, 124, 251, 160, 177, 179, 14, 7, 189, 49, 210, 77, 63, 132, 17, 84, 214, 63, 206, 252, 184, 168, 109, 129, 89, 70, 66, 151, 151, 100, 27, 123, 35, 210, 112, 183, 135, 97, 19, 7, 159, 221, 46, 253, 42, 229, 101, 187, 10, 33, 152, 138, 236, 208, 117, 230, 98, 200, 139, 200, 255, 19, 219, 183, 181, 3, 43, 143, 130, 75, 21, 228, 121, 208, 51, 82, 41, 233, 56, 220, 190, 176, 136, 108, 88, 118, 228, 206, 11, 170, 236, 232, 204, 241, 241, 69, 71, 28, 143, 207, 52, 188, 183, 80, 4, 222, 162, 30, 213, 228, 119, 142, 10, 255);
blues = newArray(0, 43, 203, 219, 253, 158, 5, 190, 72, 11, 23, 233, 220, 246, 53, 10, 90, 49, 215, 182, 74, 50, 27, 107, 39, 48, 192, 134, 247, 89, 14, 3, 67, 65, 30, 136, 78, 129, 178, 138, 186, 204, 5, 160, 18, 103, 255, 162, 42, 128, 213, 204, 49, 80, 181, 130, 60, 185, 31, 203, 184, 89, 108, 190, 109, 157, 231, 62, 128, 96, 150, 153, 160, 54, 24, 143, 90, 216, 128, 120, 87, 244, 15, 213, 235, 142, 140, 33, 98, 164, 202, 38, 84, 63, 229, 163, 28, 239, 210, 131, 79, 83, 168, 79, 89, 170, 26, 168, 149, 217, 31, 20, 11, 141, 121, 139, 21, 58, 194, 75, 110, 234, 16, 126, 24, 41, 62, 88, 232, 38, 243, 83, 195, 58, 84, 106, 151, 32, 146, 24, 140, 217, 176, 186, 174, 170, 250, 1, 48, 141, 99, 213, 127, 46, 97, 12, 143, 237, 153, 185, 72, 170, 23, 222, 216, 23, 92, 232, 54, 64, 72, 128, 182, 38, 192, 138, 115, 162, 231, 2, 143, 117, 167, 196, 4, 182, 220, 52, 252, 34, 2, 233, 132, 135, 230, 36, 199, 228, 222, 43, 119, 7, 148, 59, 10, 35, 158, 237, 17, 116, 110, 129, 172, 233, 172, 47, 114, 26, 115, 212, 177, 157, 74, 183, 102, 132, 151, 18, 242, 242, 12, 138, 21, 159, 165, 213, 230, 147, 174, 206, 116, 9, 242, 233, 202, 205, 116, 169, 80, 53, 161, 239, 211, 73, 96, 255);
setLut(reds, greens, blues);

setBatchMode("exit & display");
exit("hi");

}
else{
	rename("Objects map of dF Stack");
	resultsFile = replace(fileOpen, "Objects map of dF Stack.tif", "Results.xls");
	dfFile = replace(fileOpen, "Objects map of dF Stack.tif", "dF Stack.tif");
	open(resultsFile);
	open(dfFile);
	rename("dF Stack");
}

//Remove each wave one at a time and apply a temporal color code
selectWindow("Objects map of dF Stack");
max = nResults;
getDimensions(width, height, channels, slices, frames);
newImage("Max Wave Velocity ("+ grid + "x" + grid +"array)", "32-bit black", step, step, max);
newImage("Vector Sum Velocity ("+ grid + "x" + grid +"array)", "32-bit black", step, step, max);
newImage("Vector Sum Angle ("+ grid + "x" + grid +"array)", "32-bit black", step, step, max);
//newImage("dt Stack", "8-bit black", width, height, slices);

for(a=1; a<=max; a++){
	selectWindow("Objects map of dF Stack");
	
	//Duplicate the object map, and remove everything but the current wave
	run("Duplicate...", "title=wave duplicate");
	selectWindow("wave");

	waveStart = getResult("BZ", a-1);
	waveEnd = waveStart + getResult("B-depth", a-1);
	waveStart -= waveAddSlice;
	if(waveStart<1) waveStart = 1;
	waveEnd += waveAddSlice;
	if(waveEnd > nSlices) waveEnd = nSlices;
				
	waveFrontStack(waveStart, waveEnd, grid, a, waveGap, width, height, step, waveThreshold);
	
}

selectWindow("dF Stack");
getDimensions(width, height, channels, slices, frames);
selectWindow("Max Wave Velocity ("+ grid + "x" + grid +"array)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
selectWindow("Vector Sum Velocity ("+ grid + "x" + grid +"array)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
selectWindow("Vector Sum Angle ("+ grid + "x" + grid +"array)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
setBatchMode("exit & display");


function waveFrontStack(startSlice, endSlice, grid, waveID, waveGap, width, height, step, waveThreshold){
	
	//Remove the substack containing the wave
	selectWindow("wave");
	slices = nSlices;
	run("Make Substack...", "delete slices=" + startSlice + "-" + endSlice);
	close("wave");

	//Create a mask of just the current wave
	selectWindow("Substack (" + startSlice + "-" + endSlice + ")");
	rename("wave mask");

	//Create a mask of the wave
	selectWindow("wave mask");
	run("Macro...", "code=[if(v != " + waveID + ") v=0] stack");
	run("Multiply...", "value=255.000 stack");
	run("Divide...", "value=255.000 stack");

	//Retrieve the corresponding substack from the dF stack
	selectWindow("dF Stack");
	run("Make Substack...", "slices=" + startSlice + "-" + endSlice);
	selectWindow("Substack (" + startSlice + "-" + endSlice + ")");
	rename("wave dF");

	//Isolate the current wave in the dF stack
	imageCalculator("Multiply stack", "wave dF","wave mask");
	close("wave mask");
	
	//Measure the transit time of the wave through each grid point
	selectWindow("wave dF");
	maxVelocityArray = newArray(step*step);
	vecSumVelArray = newArray(step*step);
	vecSumAngleArray = newArray(step*step);
	
	for(xGrid = 0; xGrid < step; xGrid++){
		showProgress(xGrid/step);
		for(yGrid = 0; yGrid < step; yGrid++){
			makeRectangle(((xGrid + 0.5)*width/step-0.5*width/grid), ((yGrid + 0.5)*height/step-0.5*height/grid), width/grid, height/grid);
//			wait(100);
			waveXcm = newArray(nSlices);
			waveYcm = newArray(nSlices);
			Array.fill(waveXcm, -1);
			Array.fill(waveYcm, -1);
			
			//Find wave passing through grid box
			for(a=1; a<=nSlices; a++){
				setSlice(a);
				List.setMeasurements;
				mean = List.getValue("Mean");
				//If the mean in the selection is > 0, wave is in the box
				if(mean > waveThreshold){
					waveXcm[a] = List.getValue("XM");
					waveYcm[a] = List.getValue("YM");
				}
			}

			//Calculate the moment velocity and angle
			velCount = 0;
			xVecSum = 0;
			yVecSum = 0;
			waveVel = 0;
			maxVel = 0;
			for(a=0; a<waveXcm.length-1; a++){
				if(waveXcm[a] > -1){
					if(waveXcm[a+1] > -1){
						xDist = waveXcm[a+1] - waveXcm[a];
						yDist = waveYcm[a+1] - waveYcm[a];
						waveVel = sqrt((xDist*xDist)+(yDist*yDist));
						if(waveVel > maxVel) maxVel = waveVel;
						xVecSum += xDist;
						yVecSum += yDist;
						velCount += 1;
					}
				}
			}

			//Calculate the mean velocity and angle
			//Calculate velocity only if non-zero (otherwise NaN will result)
			if(abs(xVecSum) + abs(yVecSum) > 0 && velCount > 0) vecSumVel = sqrt((xVecSum*xVecSum)+(yVecSum*yVecSum))/velCount;
			else vecSumVel = 0;
			vecSumAngle = atan2(yVecSum, xVecSum)*180/PI;

			
			//Store the wave velocity for that grid
			maxVelocityArray[xGrid*step + yGrid] = maxVel;
			vecSumVelArray[xGrid*step + yGrid] = vecSumVel;
			vecSumAngleArray[xGrid*step + yGrid] = vecSumAngle;
		}
	}

	//output the array onto the Mean Velocity image
	selectWindow("Max Wave Velocity ("+ grid + "x" + grid +"array)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, maxVelocityArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
	run("Median...", "radius=2 slice");
	
	//output the array onto the Vector Sum Velocity image
	selectWindow("Vector Sum Velocity ("+ grid + "x" + grid +"array)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, vecSumVelArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
	run("Median...", "radius=2 slice");
	
	//output the array onto the Vector Sum Angle image
	selectWindow("Vector Sum Angle ("+ grid + "x" + grid +"array)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, vecSumAngleArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
	run("Median...", "radius=2 slice");

	close("wave dF");

}

