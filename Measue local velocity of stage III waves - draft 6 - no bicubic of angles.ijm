close("*");
setBatchMode(true);
fileOpen = File.openDialog("Choose a 16x stage II/III wave file.");
open(fileOpen);
image = getTitle();
getDimensions(width, height, channels, slices, frames);

//Variable for size of grid as nxn grid to measure velocity (ideally power of 2)
grid = 16;

//Width divisor step size for translating grid square (ideally power of 2)
step = 32;

//8-bit intensity threshold for finding a wave in dt stack.
waveThreshold = 1;

//Variable for how many frames a wave can stall in a single grid box
waveGap = 2;

//SLices to add to either side of detected wave (increase window size)
waveAddSlice = 3;

//Ask user what stage wave this is
Dialog.create("Radio Buttons");
items = newArray("N/A", "Stage II", "Stage III");

//Try and identify the wave stage from the file name, and set default radio button to this position
if(matches(image, ".*_sII_.*")) defaultButton = "Stage II";
else if(matches(image, ".*_sIII_.*")) defaultButton = "Stage III";
else defaultButton = "N/A";

Dialog.addRadioButtonGroup("What stage wave is this?", items, 3, 1, defaultButton);
Dialog.show;
waveStage = Dialog.getRadioButton;

//Calculate final variables and double check validity
if(step < grid){
	exit("stepDvisor needs to be >= grid in order for no gaps between grid squares");
}

//Exit the macro if no wave type is specified
if(matches(waveStage, "N/A")){
	exit("No stage was specified, so mask analysis cannot be performed.");
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

//setBatchMode("exit & display");
//exit("hi");

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

//Make dF/dt images to store results
newImage("Max Wave Velocity dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Max Wave Velocity (Angle) dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);

//Make mask images to store reuslts
newImage("Max Wave Velocity mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Max Wave Velocity (Angle) mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Angle mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
//newImage("dt Stack", "8-bit black", width, height, slices);

//Perform wave vector analysis on dF/dt stack
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
				
	waveFrontStack(waveStart, waveEnd, grid, a, waveGap, width, height, step, waveThreshold, "dF/dt");
	
}

//Create mask from dF/dt stack
selectWindow("dF Stack");
run("Duplicate...", "title=[dF Stack Copy] duplicate");

if(matches(waveStage, "Stage II")){
	selectWindow("dF Stack");
	run("Gaussian Blur...", "sigma=10 stack");
	setAutoThreshold("MaxEntropy dark stack");
	run("Convert to Mask", "method=MaxEntropy background=Dark black");
}


if(matches(waveStage, "Stage III")){
	selectWindow("dF Stack");
	getDimensions(width, height, channels, slices, frames);
	run("Canvas Size...", "width="+ width + 2 + " height=" + height + 2 + " position=Center zero");
	run("Find Edges", "stack");
	setAutoThreshold("Intermodes dark stack");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Intermodes background=Dark black");
	run("Invert", "stack");
	run("Fill Holes", "stack");
	run("Invert", "stack");
	run("Canvas Size...", "width="+ width + " height=" + height + " position=Center zero");
}

//Perform wave vector analysis on mask stack
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
				
	waveFrontStack(waveStart, waveEnd, grid, a, waveGap, width, height, step, waveThreshold, "mask");
	
}
setBatchMode("exit & display");

selectWindow("Objects map of dF Stack");
getDimensions(width, height, channels, slices, frames);

//set Luts
redAngle = newArray(255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
greenAngle = newArray(0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
blueAngle = newArray(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0);

redVel = newArray(0, 46, 45, 44, 42, 41, 40, 39, 37, 36, 35, 33, 32, 30, 29, 27, 26, 24, 23, 21, 19, 18, 16, 14, 12, 10, 9, 7, 5, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 22, 22, 22, 27, 32, 37, 42, 48, 53, 58, 63, 69, 74, 79, 85, 90, 96, 101, 107, 112, 118, 123, 129, 134, 140, 145, 148, 151, 153, 156, 159, 161, 164, 166, 169, 172, 174, 177, 180, 182, 185, 188, 190, 193, 196, 198, 201, 204, 206, 210, 213, 216, 220, 222, 222, 222, 222, 222, 223, 223, 223, 223, 223, 223, 224, 224, 224, 224, 224, 225, 225, 225, 225, 225, 225, 226, 226, 226, 226, 226, 227, 227, 227, 227, 227, 228, 228, 228, 228, 228, 228, 229, 229, 229, 229, 229, 230, 230, 230, 230, 230, 230, 231, 231, 231, 231, 231, 232, 232, 232, 232, 232, 233);
greenVel = newArray(0, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 3, 5, 7, 9, 11, 13, 15, 18, 20, 23, 26, 28, 31, 33, 36, 39, 41, 44, 47, 49, 52, 55, 58, 60, 63, 66, 69, 71, 74, 77, 80, 82, 85, 88, 91, 94, 96, 99, 102, 105, 108, 111, 114, 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 161, 164, 167, 170, 173, 176, 179, 182, 185, 188, 191, 194, 198, 198, 198, 198, 198, 199, 199, 199, 199, 199, 200, 200, 200, 200, 200, 201, 201, 201, 201, 202, 202, 202, 203, 203, 203, 204, 204, 204, 205, 205, 205, 206, 206, 206, 207, 207, 207, 208, 208, 208, 209, 209, 209, 210, 210, 210, 211, 211, 211, 212, 212, 212, 213, 213, 213, 214, 214, 214, 215, 215, 215, 216, 216, 216, 217, 217, 217, 217, 217, 218, 218, 218, 218, 218, 218, 219, 219, 219, 219, 219, 219, 219, 220, 220, 220, 220, 220, 220, 221, 221, 221, 221, 221, 221, 220, 217, 214, 212, 209, 206, 203, 200, 197, 194, 191, 188, 185, 182, 178, 175, 172, 169, 166, 163, 160, 157, 154, 151, 148, 145, 141, 138, 135, 132, 129, 126, 122, 119, 116, 113, 110, 106, 103, 100, 97, 94, 90, 87, 84, 80, 77, 74, 71, 67, 64, 61, 57, 54, 51, 47, 44, 41, 37, 34);
blueVel = newArray(0, 120, 122, 123, 124, 125, 126, 127, 128, 129, 131, 132, 133, 134, 135, 136, 137, 138, 139, 141, 142, 143, 144, 145, 146, 147, 148, 149, 151, 152, 153, 154, 155, 156, 157, 158, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 191, 191, 191, 192, 192, 192, 192, 192, 193, 193, 193, 193, 193, 194, 194, 194, 194, 194, 195, 195, 195, 195, 195, 196, 196, 196, 196, 196, 197, 197, 197, 197, 197, 198, 195, 192, 190, 187, 184, 181, 178, 176, 173, 170, 167, 165, 162, 159, 156, 153, 150, 148, 143, 138, 133, 129, 124, 119, 114, 109, 104, 99, 94, 89, 84, 79, 74, 69, 64, 59, 54, 49, 44, 39, 33, 28, 23, 22, 22, 22, 22, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16);

selectWindow("Max Wave Velocity dF/dt ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max);
else getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
setLut(redVel, greenVel, blueVel);
run("In [+]");
setLocation(410, 665);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Max Wave Velocity (Angle) dF/dt ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
setMinAndMax(-180, 180);
setLut(redAngle, greenAngle, blueAngle);
run("In [+]");
setLocation(0, 665);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max);
else getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
setLut(redVel, greenVel, blueVel);
run("In [+]");
setLocation(410, 200);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
setMinAndMax(-180, 180);
setLut(redAngle, greenAngle, blueAngle);
run("In [+]");
setLocation(0, 200);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}

selectWindow("Objects map of dF Stack");
setLocation(820, 820);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("dF Stack");
rename("dF Stack Mask");
setLocation(820, 485);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("dF Stack Copy");
rename("Processed dF Stack");
if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max); 
else getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("Rainbow RGB");
setLocation(820, 150);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}

selectWindow("Max Wave Velocity mask ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max); 
else getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
setLut(redVel, greenVel, blueVel);
run("In [+]");
setLocation(1510, 665);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Max Wave Velocity (Angle) mask ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
setMinAndMax(-180, 180);
setLut(redAngle, greenAngle, blueAngle);
run("In [+]");
setLocation(1100, 665);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max); 
else getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
setLut(redVel, greenVel, blueVel);
run("In [+]");
setLocation(1510, 200);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}
selectWindow("Vector Sum Angle mask ("+ grid + " grid " + step +" step)");
run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
setMinAndMax(-180, 180);
setLut(redAngle, greenAngle, blueAngle);
run("In [+]");
setLocation(1100, 200);
if(nSlices > 1){
	setSlice(2);
	setSlice(1);
}

//Create user interface to navigate waves
quitMacro = false;
while(!quitMacro){
	waitForUser("Select the wave of interest");

	//Find the selected wave
	waveID = 0;
	if(bitDepth() == 32){
		waveID = getSliceNumber();
	}
	else if(selectionType() != -1){
		slice = getSliceNumber();
		run("Select None");
		selectWindow("Objects map of dF Stack");
		setSlice(slice);
		run("Restore Selection");
		getStatistics(dummy, dummy, dummy, waveID);	
		run("Select None");
	}

	//If wave was selected, update all windows to present wave
	if(waveID > 0){
		selectWindow("Max Wave Velocity dF/dt ("+ grid + " grid " + step +" step)");
		setSlice(waveID);
		selectWindow("Max Wave Velocity (Angle) dF/dt ("+ grid + " grid " + step +" step)");
		setSlice(waveID);
		selectWindow("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");	
		setSlice(waveID);
		selectWindow("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)");	
		setSlice(waveID);
		selectWindow("Max Wave Velocity mask ("+ grid + " grid " + step +" step)");
		setSlice(waveID);
		selectWindow("Max Wave Velocity (Angle) mask ("+ grid + " grid " + step +" step)");
		setSlice(waveID);
		selectWindow("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");
		setSlice(waveID);	
		selectWindow("Vector Sum Angle mask ("+ grid + " grid " + step +" step)");	
		setSlice(waveID);

		//Get the stack positions of the wave
		waveStart = getResult("BZ", waveID-1);
		waveEnd = waveStart + getResult("B-depth", waveID-1);

		repeatWave = true;
		while(repeatWave){
			for(a=waveStart; a<=waveEnd; a++){
				selectWindow("Processed dF Stack");
				setSlice(a);
				selectWindow("dF Stack Mask");
				setSlice(a);
				selectWindow("Objects map of dF Stack");
				setSlice(a);
				wait(100);
			}
			repeatWave = getBoolean("Would you like to replay the wave?");
		}				
	}
	else{
		quitMacro = getBoolean("Would you like to quit the macro?");
	}
}


function waveFrontStack(startSlice, endSlice, grid, waveID, waveGap, width, height, step, waveThreshold, analysisType){
	
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
	maxAngleArray = newArray(step*step);
	vecSumVelArray = newArray(step*step);
	vecSumAngleArray = newArray(step*step);
	
	for(xGrid = 0; xGrid < step; xGrid++){
		showProgress(xGrid/step);
		for(yGrid = 0; yGrid < step; yGrid++){
			makeOval(((xGrid + 0.5)*width/step-0.5*width/grid), ((yGrid + 0.5)*height/step-0.5*height/grid), width/grid, height/grid);
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
			maxAngle = 0;
			for(a=0; a<waveXcm.length-1; a++){
				if(waveXcm[a] > -1){
					if(waveXcm[a+1] > -1){
						xDist = waveXcm[a+1] - waveXcm[a];
						yDist = waveYcm[a+1] - waveYcm[a];
						waveVel = sqrt((xDist*xDist)+(yDist*yDist));
						if(waveVel > maxVel){
							maxVel = waveVel;
							maxAngle = atan2(yDist, xDist)*180/PI; 
						}
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
			maxAngleArray[xGrid*step + yGrid] = maxAngle;
			vecSumVelArray[xGrid*step + yGrid] = vecSumVel;
			vecSumAngleArray[xGrid*step + yGrid] = vecSumAngle;
		}
	}

	//output the array onto the Max Velocity image
	selectWindow("Max Wave Velocity " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, maxVelocityArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
	run("Median...", "radius=2 slice");

	//output the array onto the Max Angle image
	selectWindow("Max Wave Velocity (Angle) " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			setPixel(a, b, maxAngleArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
	run("Median...", "radius=2 slice");
	
	//output the array onto the Vector Sum Velocity image
	selectWindow("Vector Sum Velocity " + analysisType + " ("+ grid + " grid " + step +" step)");
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
	selectWindow("Vector Sum Angle " + analysisType + " ("+ grid + " grid " + step +" step)");
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

