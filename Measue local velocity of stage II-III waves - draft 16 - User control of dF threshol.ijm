close("*");
run("Clear Results");
setBatchMode(true);
fileOpen = File.openDialog("Choose a 16x stage II/III wave file.");
open(fileOpen);
directory = File.directory();
image = getTitle();
getDimensions(width, height, channels, slices, frames);

//maximum Fi/Fmed value to be removed as artifact
maxdF = 4;


//Variable for size of grid square as nxn grid to measure velocity (ideally power of 2)
grid = 8;

//Width divisor step size for translating grid square (ideally power of 2)
step = 32;

//8-bit intensity threshold for finding a wave in dt stack. Default is 1.
waveThreshold = 1;

//Variable for how many frames a wave can stall in a single grid box
waveGap = 2;

//SLices to add to either side of detected wave (increase window size)
waveAddSlice = 3;

//Have a user interface to double check the stage III mask
thresholdGUI = true;

//Ask user what stage wave this is
Dialog.create("Choose Stage and Output");
items = newArray("N/A", "Stage II", "Stage III");
outputChoice = newArray("Angle/Mag Maps", "Quiver Plots", "XY Map");

//Try and identify the wave stage from the file name, and set default radio button to this position
if(matches(image, ".*_sII_.*")) defaultButton = "Stage II";
else if(matches(image, ".*_sIII_.*")) defaultButton = "Stage III";
else defaultButton = "N/A";

Dialog.addRadioButtonGroup("What stage wave is this?", items, 3, 1, defaultButton);
Dialog.addRadioButtonGroup("Select Output Type:", outputChoice, 1, 2, "Quiver Plots");
Dialog.addCheckbox("Quiver plot temporal color code", true) 
Dialog.show;
waveStage = Dialog.getRadioButton();
outputType = Dialog.getRadioButton();
colorCode = Dialog.getCheckbox();

//Calculate final variables and double check validity
if(step < grid){
	exit("stepDvisor needs to be >= grid in order for no gaps between grid squares");
}

//Exit the macro if no wave type is specified
if(matches(waveStage, "N/A")){
	exit("No stage was specified, so mask analysis cannot be performed.");
}
 
//If image has not yet been processed and segmented, process it.
if(!matches(image, "Objects map of dF Stack.tif")){
	//If the wave is a stage III wave, then process stack to find peak dF/dt
	if(matches(waveStage, "Stage II")){
		//Perform initial processing to dF/dt stack
		processStageII(image);
		
		//Find each wave and color code them
		selectWindow("dF Stack");
		Stack.getStatistics(dummy, stackMean);
		startFound = false;
		endFound = false;
		longestWave = 0;
		waveCount = 1;

		for(a=1; a<=nSlices; a++){
			selectWindow("Objects map of dF Stack");
			setSlice(a);
			getStatistics(dummy, mean);
	
			//If slice mean > stack mean, then wave start has been found
			if(!startFound && mean > stackMean){
				startFound = true;
				waveStart = a - waveAddSlice;
				if(waveStart<1) waveStart = 1;
	
				//If a start slice is found too close to the end, ignore start slice
				if(waveStart > nSlices-2) startFound = false;				
			}
			
			//If slice mean < stack mean, then wave end has been found
			if(startFound && mean < stackMean){
				endFound = true;
	
				//A -1 offset is needed to 
				waveEnd = a + waveAddSlice;
				if(waveEnd > nSlices) waveEnd = nSlices;
	
			}
	
			//If a full wave is found, remove it from the stack and analyze it
			if(startFound && endFound){
				startFound = false;
				endFound = false;
	
				stageIIsegmentMask(waveStart, waveEnd, waveCount);
				
				waveCount += 1;
				a = waveEnd;
			}
			
			//Otherwise, data is not a wave, so clear slice
			if (!startFound && !endFound){
				selectWindow("Objects map of dF Stack");
				setSlice(a);
				run("Select All");
				setBackgroundColor(0, 0, 0);
				run("Clear", "slice");
				run("Select None");
			}									
		}
	}
	//If the wave is a stage III wave, then process stack to find peak dF/F
	else{
		processStageIIIimage(image);
		
	}

	//Create random lUT and apply to objects map
	selectWindow("Objects map of dF Stack");
	reds = newArray(0, 231, 25, 27, 112, 89, 53, 77, 155, 153, 91, 19, 25, 135, 187, 40, 52, 39, 147, 72, 92, 23, 5, 202, 52, 50, 108, 66, 238, 46, 136, 8, 162, 126, 75, 60, 135, 167, 136, 244, 161, 204, 158, 112, 192, 2, 98, 207, 233, 121, 191, 18, 210, 151, 252, 155, 139, 42, 188, 170, 127, 151, 38, 16, 227, 120, 137, 2, 72, 71, 214, 130, 194, 96, 102, 33, 92, 47, 211, 226, 237, 132, 244, 45, 82, 73, 239, 198, 118, 191, 170, 238, 177, 246, 66, 5, 44, 3, 18, 40, 226, 94, 130, 216, 68, 89, 150, 40, 96, 155, 95, 5, 132, 88, 124, 241, 143, 15, 1, 220, 46, 220, 216, 155, 190, 4, 98, 33, 142, 153, 185, 61, 153, 160, 164, 102, 75, 8, 26, 231, 160, 245, 119, 69, 95, 137, 232, 249, 89, 220, 54, 3, 43, 134, 172, 31, 106, 234, 132, 1, 29, 65, 12, 107, 52, 196, 95, 165, 4, 101, 124, 240, 203, 50, 142, 231, 5, 23, 43, 198, 41, 80, 66, 232, 86, 151, 126, 51, 122, 111, 162, 192, 148, 210, 5, 251, 40, 176, 32, 2, 22, 91, 180, 31, 218, 9, 10, 178, 27, 115, 54, 199, 163, 10, 180, 222, 102, 198, 202, 220, 96, 145, 237, 127, 172, 51, 64, 47, 84, 37, 196, 147, 244, 206, 244, 43, 170, 186, 162, 157, 125, 230, 212, 140, 186, 127, 12, 48, 0, 92, 168, 73, 228, 121, 248, 255);
	greens = newArray(0, 217, 131, 18, 66, 198, 59, 170, 108, 8, 167, 207, 248, 138, 215, 204, 95, 249, 102, 66, 1, 138, 71, 33, 209, 80, 72, 87, 129, 24, 200, 98, 16, 160, 47, 1, 224, 49, 126, 41, 235, 205, 84, 249, 222, 125, 5, 58, 90, 137, 73, 98, 109, 167, 91, 106, 68, 23, 10, 241, 51, 35, 77, 112, 243, 235, 53, 41, 21, 134, 106, 60, 231, 107, 124, 96, 131, 62, 213, 220, 78, 96, 44, 106, 128, 96, 129, 164, 59, 86, 45, 87, 237, 192, 171, 93, 223, 206, 158, 42, 255, 175, 142, 177, 48, 67, 221, 123, 125, 182, 135, 31, 163, 211, 220, 28, 81, 113, 235, 236, 30, 104, 238, 227, 18, 134, 193, 15, 122, 151, 6, 132, 0, 128, 88, 20, 130, 87, 127, 55, 13, 76, 15, 124, 251, 160, 177, 179, 14, 7, 189, 49, 210, 77, 63, 132, 17, 84, 214, 63, 206, 252, 184, 168, 109, 129, 89, 70, 66, 151, 151, 100, 27, 123, 35, 210, 112, 183, 135, 97, 19, 7, 159, 221, 46, 253, 42, 229, 101, 187, 10, 33, 152, 138, 236, 208, 117, 230, 98, 200, 139, 200, 255, 19, 219, 183, 181, 3, 43, 143, 130, 75, 21, 228, 121, 208, 51, 82, 41, 233, 56, 220, 190, 176, 136, 108, 88, 118, 228, 206, 11, 170, 236, 232, 204, 241, 241, 69, 71, 28, 143, 207, 52, 188, 183, 80, 4, 222, 162, 30, 213, 228, 119, 142, 10, 255);
	blues = newArray(0, 43, 203, 219, 253, 158, 5, 190, 72, 11, 23, 233, 220, 246, 53, 10, 90, 49, 215, 182, 74, 50, 27, 107, 39, 48, 192, 134, 247, 89, 14, 3, 67, 65, 30, 136, 78, 129, 178, 138, 186, 204, 5, 160, 18, 103, 255, 162, 42, 128, 213, 204, 49, 80, 181, 130, 60, 185, 31, 203, 184, 89, 108, 190, 109, 157, 231, 62, 128, 96, 150, 153, 160, 54, 24, 143, 90, 216, 128, 120, 87, 244, 15, 213, 235, 142, 140, 33, 98, 164, 202, 38, 84, 63, 229, 163, 28, 239, 210, 131, 79, 83, 168, 79, 89, 170, 26, 168, 149, 217, 31, 20, 11, 141, 121, 139, 21, 58, 194, 75, 110, 234, 16, 126, 24, 41, 62, 88, 232, 38, 243, 83, 195, 58, 84, 106, 151, 32, 146, 24, 140, 217, 176, 186, 174, 170, 250, 1, 48, 141, 99, 213, 127, 46, 97, 12, 143, 237, 153, 185, 72, 170, 23, 222, 216, 23, 92, 232, 54, 64, 72, 128, 182, 38, 192, 138, 115, 162, 231, 2, 143, 117, 167, 196, 4, 182, 220, 52, 252, 34, 2, 233, 132, 135, 230, 36, 199, 228, 222, 43, 119, 7, 148, 59, 10, 35, 158, 237, 17, 116, 110, 129, 172, 233, 172, 47, 114, 26, 115, 212, 177, 157, 74, 183, 102, 132, 151, 18, 242, 242, 12, 138, 21, 159, 165, 213, 230, 147, 174, 206, 116, 9, 242, 233, 202, 205, 116, 169, 80, 53, 161, 239, 211, 73, 96, 255);
	setLut(reds, greens, blues);

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
newImage("Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("dF/dt NaN mask", "32-bit black", width, height, max);

//Make mask images to store reuslts
newImage("Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("Vector Sum Angle mask ("+ grid + " grid " + step +" step)", "32-bit black", step, step, max);
newImage("mask NaN mask", "32-bit black", width, height, max);

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
selectWindow("Objects map of dF Stack");
getDimensions(width, height, channels, slices, frames);

//If the ouput type is "map", then create all maps
if(matches(outputType, "Angle/Mag Maps")){
	//Create NaN mask by dividing the image by itself (0/0 = NaN)
	imageCalculator("Divide stack", "dF/dt NaN mask","dF/dt NaN mask");
	imageCalculator("Divide stack", "mask NaN mask","mask NaN mask");
	
	setBatchMode("exit & display");
	

	//set Luts
	redAngle = newArray(255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);
	greenAngle = newArray(0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
	blueAngle = newArray(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 72, 78, 84, 90, 96, 102, 108, 114, 120, 126, 132, 138, 144, 150, 156, 162, 168, 174, 180, 186, 192, 198, 204, 210, 216, 222, 228, 234, 240, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 252, 246, 240, 234, 228, 222, 216, 210, 204, 198, 192, 186, 180, 174, 168, 162, 156, 150, 144, 138, 132, 126, 120, 114, 108, 102, 96, 90, 84, 78, 72, 66, 60, 54, 48, 42, 36, 30, 24, 18, 12, 6, 0);
	
	redVel = newArray(0, 46, 45, 44, 42, 41, 40, 39, 37, 36, 35, 33, 32, 30, 29, 27, 26, 24, 23, 21, 19, 18, 16, 14, 12, 10, 9, 7, 5, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 3, 4, 5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 22, 22, 22, 27, 32, 37, 42, 48, 53, 58, 63, 69, 74, 79, 85, 90, 96, 101, 107, 112, 118, 123, 129, 134, 140, 145, 148, 151, 153, 156, 159, 161, 164, 166, 169, 172, 174, 177, 180, 182, 185, 188, 190, 193, 196, 198, 201, 204, 206, 210, 213, 216, 220, 222, 222, 222, 222, 222, 223, 223, 223, 223, 223, 223, 224, 224, 224, 224, 224, 225, 225, 225, 225, 225, 225, 226, 226, 226, 226, 226, 227, 227, 227, 227, 227, 228, 228, 228, 228, 228, 228, 229, 229, 229, 229, 229, 230, 230, 230, 230, 230, 230, 231, 231, 231, 231, 231, 232, 232, 232, 232, 232, 233);
	greenVel = newArray(0, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 3, 5, 7, 9, 11, 13, 15, 18, 20, 23, 26, 28, 31, 33, 36, 39, 41, 44, 47, 49, 52, 55, 58, 60, 63, 66, 69, 71, 74, 77, 80, 82, 85, 88, 91, 94, 96, 99, 102, 105, 108, 111, 114, 116, 119, 122, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 161, 164, 167, 170, 173, 176, 179, 182, 185, 188, 191, 194, 198, 198, 198, 198, 198, 199, 199, 199, 199, 199, 200, 200, 200, 200, 200, 201, 201, 201, 201, 202, 202, 202, 203, 203, 203, 204, 204, 204, 205, 205, 205, 206, 206, 206, 207, 207, 207, 208, 208, 208, 209, 209, 209, 210, 210, 210, 211, 211, 211, 212, 212, 212, 213, 213, 213, 214, 214, 214, 215, 215, 215, 216, 216, 216, 217, 217, 217, 217, 217, 218, 218, 218, 218, 218, 218, 219, 219, 219, 219, 219, 219, 219, 220, 220, 220, 220, 220, 220, 221, 221, 221, 221, 221, 221, 220, 217, 214, 212, 209, 206, 203, 200, 197, 194, 191, 188, 185, 182, 178, 175, 172, 169, 166, 163, 160, 157, 154, 151, 148, 145, 141, 138, 135, 132, 129, 126, 122, 119, 116, 113, 110, 106, 103, 100, 97, 94, 90, 87, 84, 80, 77, 74, 71, 67, 64, 61, 57, 54, 51, 47, 44, 41, 37, 34);
	blueVel = newArray(0, 120, 122, 123, 124, 125, 126, 127, 128, 129, 131, 132, 133, 134, 135, 136, 137, 138, 139, 141, 142, 143, 144, 145, 146, 147, 148, 149, 151, 152, 153, 154, 155, 156, 157, 158, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 191, 191, 191, 192, 192, 192, 192, 192, 193, 193, 193, 193, 193, 194, 194, 194, 194, 194, 195, 195, 195, 195, 195, 196, 196, 196, 196, 196, 197, 197, 197, 197, 197, 198, 195, 192, 190, 187, 184, 181, 178, 176, 173, 170, 167, 165, 162, 159, 156, 153, 150, 148, 143, 138, 133, 129, 124, 119, 114, 109, 104, 99, 94, 89, 84, 79, 74, 69, 64, 59, 54, 49, 44, 39, 33, 28, 23, 22, 22, 22, 22, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16);
	
	selectWindow("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
	imageCalculator("Multiply stack", "Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)","dF/dt NaN mask");
	setMinAndMax(-180, 180);
	setLut(redAngle, greenAngle, blueAngle);
	setLocation(0, 100);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
	imageCalculator("Multiply stack", "Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)","dF/dt NaN mask");
	setMinAndMax(-180, 180);
	setLut(redAngle, greenAngle, blueAngle);
	setLocation(0, 565);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
	imageCalculator("Multiply stack", "Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)","dF/dt NaN mask");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max);
	else getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	setLut(redVel, greenVel, blueVel);
	setLocation(410, 100);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
	imageCalculator("Multiply stack", "Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)","dF/dt NaN mask");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max);
	else getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	setLut(redVel, greenVel, blueVel);
	setLocation(410, 565);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Objects map of dF Stack");
	setLocation(820, 720);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("dF Stack");
	rename("dF Stack Mask");
	setLocation(820, 385);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
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
	setLocation(820, 50);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Angle mask ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
	imageCalculator("Multiply stack", "Vector Sum Angle mask ("+ grid + " grid " + step +" step)","mask NaN mask");
	setMinAndMax(-180, 180);
	setLut(redAngle, greenAngle, blueAngle);
	setLocation(1100, 100);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=None");
	imageCalculator("Multiply stack", "Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)","mask NaN mask");
	setMinAndMax(-180, 180);
	setLut(redAngle, greenAngle, blueAngle);
	setLocation(1100, 565);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
	imageCalculator("Multiply stack", "Vector Sum Velocity mask ("+ grid + " grid " + step +" step)","mask NaN mask");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max); 
	else getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	setLut(redVel, greenVel, blueVel);
	setLocation(1509, 100);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)");
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" constrain average interpolation=Bicubic");
	imageCalculator("Multiply stack", "Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)","mask NaN mask");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, dummy, max); 
	else getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	setLut(redVel, greenVel, blueVel);
	setLocation(1509, 565);
	for(a=1; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	
	//Close the NaN mask
	close("dF/dt NaN mask");
	close("mask NaN mask");
	
	//Create user interface to navigate waves
	quitMacro = false;
	while(!quitMacro){
		waitForUser("Select the wave of interest");
		selectedTitle = getTitle();
		
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
			selectWindow("Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
			selectWindow("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
			selectWindow("Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");
			setSlice(waveID);	
			selectWindow("Vector Sum Angle mask ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
	
			//Get the stack positions of the wave
			waveStart = getResult("BZ", waveID-1);
			waveEnd = waveStart + getResult("B-depth", waveID-1);
	
			for(a=waveStart; a<=waveEnd; a++){
				selectWindow("Processed dF Stack");
				setSlice(a);
				selectWindow("dF Stack Mask");
				setSlice(a);
				selectWindow("Objects map of dF Stack");
				setSlice(a);
				wait(100);
			}	
			selectWindow(selectedTitle);		
		}
		else{
			quitMacro = getBoolean("Would you like to quit the macro?");
		}
	}
}
//Otherwise, create quiver plots
else if(matches(outputType, "Quiver Plots")){
	//Close extra windows
	close("mask NaN mask");
	close("dF/dt NaN mask");
	
	//Generate quiver plots of the four vector sets
	quiverPlot("Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)", "Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)");
	quiverPlot("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)", "Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");
	quiverPlot("Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)", "Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)");
	quiverPlot("Vector Sum Angle mask ("+ grid + " grid " + step +" step)", "Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");

	plotNameArray = newArray(4);
	plotNameArray[0] = "Vector Sum dF/dt ("+ grid + " grid " + step +" step)";
	plotNameArray[1] = "Vector Sum mask ("+ grid + " grid " + step +" step)";
	plotNameArray[2] = "Max Wave Vector dF/dt ("+ grid + " grid " + step +" step)";
	plotNameArray[3] = "Max Wave Vector mask ("+ grid + " grid " + step +" step)";
	
	if(colorCode){
		imageNameArray = newArray(3);
		imageNameArray[0] = "dF Stack Copy";
		imageNameArray[1] = "dF Stack";
		imageNameArray[2] = "Objects map of dF Stack";
	
		//Save all the plots, close them, and them, re-open them, and delete the original files to restore batch mode
		for(a=0; a<plotNameArray.length + imageNameArray.length; a++){
			if(a<plotNameArray.length){
				selectWindow(plotNameArray[a]);
				run("Select None");
				saveAs("tiff", directory + a + "55XUTUv6VP0Z.tif");
				close(a + "55XUTUv6VP0Z.tif");
			}
			else{
				selectWindow(imageNameArray[a-plotNameArray.length]);
				run("Select None");
				saveAs("tiff", directory + a + "55XUTUv6VP0Z");
				close(a + "55XUTUv6VP0Z.tif");
			}
		}
		setBatchMode("exit & display");
		for(a=0; a<plotNameArray.length + imageNameArray.length; a++){
			if(a<plotNameArray.length){
				open(directory + a + "55XUTUv6VP0Z.tif");
				dummy = File.delete(directory + a + "55XUTUv6VP0Z.tif");
				selectWindow(a + "55XUTUv6VP0Z.tif");
				rename(plotNameArray[a]);
			}
			else{
				open(directory + a + "55XUTUv6VP0Z.tif");
				dummy = File.delete(directory + a + "55XUTUv6VP0Z.tif");
				selectWindow(a + "55XUTUv6VP0Z.tif");
				rename(imageNameArray[a-plotNameArray.length]);
			}
		}
		
		colorCodeQuiver(plotNameArray, "physics", "dF Stack", "Objects map of dF Stack");
	}
	else{
		//Trim plot border
		for(a=0; a<plotNameArray.length; a++){
			selectWindow(plotNameArray[a]);
			run("Canvas Size...", "width=511 height=511 position=Center zero");
		}		
		setBatchMode("exit & display");
	}
	
	//Show and position windows
	selectWindow("Vector Sum dF/dt ("+ grid + " grid " + step +" step)");
	setLocation(0,0,525,525);
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum mask ("+ grid + " grid " + step +" step)");
	setLocation(0,525,525,525);
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector dF/dt ("+ grid + " grid " + step +" step)");
	setLocation(460,0,525,525);
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector mask ("+ grid + " grid " + step +" step)");
	setLocation(460,525,525,525);
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}

	selectWindow("dF Stack Copy");
	run("Rainbow RGB");
	rename("Processed dF Stack");
	setLocation(920,0,350,350);
	
	selectWindow("dF Stack");
	rename("dF Stack Mask");
	setLocation(920,350,350,350);

	selectWindow("Objects map of dF Stack");
	setLocation(920,700,350,350);

	//Create user interface to navigate waves
	quitMacro = false;
	while(!quitMacro){
		waitForUser("Select the wave of interest");

		selectedTitle = getTitle();
		
		//Find the selected wave
		waveID = 0;
		getDimensions(width, height, dummy, dummy, dummy);
		if(width == 511 && height == 511){
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
			selectWindow("Vector Sum dF/dt ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Vector Sum mask ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Max Wave Vector dF/dt ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
			selectWindow("Max Wave Vector mask ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
	
			//Get the stack positions of the wave
			waveStart = getResult("BZ", waveID-1);
			waveEnd = waveStart + getResult("B-depth", waveID-1);
	
			for(a=waveStart; a<=waveEnd; a++){
				selectWindow("Processed dF Stack");
				setSlice(a);
				selectWindow("dF Stack Mask");
				setSlice(a);
				selectWindow("Objects map of dF Stack");
				setSlice(a);
				wait(100);
			}
			selectWindow(selectedTitle);				
		}
		else{
			quitMacro = getBoolean("Would you like to quit the macro?");
		}
	}
	
}

//Otherwise, create XY maps
else{
	//Create NaN mask by dividing the image by itself (0/0 = NaN)
	imageCalculator("Divide stack", "dF/dt NaN mask","dF/dt NaN mask");
	imageCalculator("Divide stack", "mask NaN mask","mask NaN mask");
	
	setBatchMode("exit & display");
	

	//set Luts
	redDisLUT = newArray(0, 0, 0, 4, 4, 4, 8, 8, 12, 12, 12, 16, 16, 20, 20, 20, 24, 24, 28, 28, 28, 32, 32, 36, 36, 36, 40, 40, 44, 44, 44, 48, 48, 52, 52, 52, 56, 56, 60, 60, 60, 64, 64, 68, 68, 68, 72, 72, 76, 76, 76, 80, 80, 84, 84, 84, 88, 88, 92, 92, 92, 96, 96, 96, 100, 100, 104, 104, 104, 108, 108, 112, 112, 112, 116, 116, 120, 120, 120, 124, 124, 128, 128, 128, 132, 132, 136, 136, 136, 140, 140, 144, 144, 144, 148, 148, 152, 152, 152, 156, 156, 160, 160, 160, 164, 164, 168, 168, 168, 172, 172, 176, 176, 176, 180, 180, 184, 184, 184, 188, 188, 192, 192, 192, 196, 196, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 204, 204, 204, 204, 204, 204, 204, 204, 204, 204, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 212, 212, 212, 212, 212, 212, 212, 212, 212, 212, 216, 216, 216, 216, 216, 216, 216, 216, 216, 216, 220, 220, 220, 220, 220, 220, 220, 220, 220, 220, 224, 224, 224, 224, 224, 224, 224, 224, 224, 228, 228, 228, 228, 228, 228, 228, 228, 228, 228, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 244, 244, 244, 244, 244, 244, 244, 244, 244, 244, 248, 248, 248, 248, 248, 248, 248, 248, 248, 252, 252);
	greenDisLUT = newArray(0, 0, 0, 4, 4, 4, 8, 8, 12, 12, 12, 16, 16, 20, 20, 20, 24, 24, 28, 28, 28, 32, 32, 36, 36, 36, 40, 40, 44, 44, 44, 48, 48, 52, 52, 52, 56, 56, 60, 60, 60, 64, 64, 68, 68, 68, 72, 72, 76, 76, 76, 80, 80, 84, 84, 84, 88, 88, 92, 92, 92, 96, 96, 96, 100, 100, 104, 104, 104, 108, 108, 112, 112, 112, 116, 116, 120, 120, 120, 124, 124, 128, 128, 128, 132, 132, 136, 136, 136, 140, 140, 144, 144, 144, 148, 148, 152, 152, 152, 156, 156, 160, 160, 160, 164, 164, 168, 168, 168, 172, 172, 176, 176, 176, 180, 180, 184, 184, 184, 188, 188, 192, 192, 192, 196, 196, 200, 200, 200, 196, 196, 196, 192, 192, 188, 188, 188, 184, 184, 180, 180, 180, 176, 176, 172, 172, 172, 168, 168, 168, 164, 164, 160, 160, 160, 156, 156, 152, 152, 152, 148, 148, 144, 144, 144, 140, 140, 136, 136, 136, 132, 132, 132, 128, 128, 124, 124, 124, 120, 120, 116, 116, 116, 112, 112, 108, 108, 108, 104, 104, 100, 100, 100, 96, 96, 96, 92, 92, 88, 88, 88, 84, 84, 80, 80, 80, 76, 76, 72, 72, 72, 68, 68, 68, 64, 64, 60, 60, 60, 56, 56, 52, 52, 52, 48, 48, 44, 44, 44, 40, 40, 36, 36, 36, 32, 32, 32, 28, 28, 24, 24, 24, 20, 20, 16, 16, 16, 12, 12, 8, 8, 8, 4, 4, 0, 0);
	blueDisLUT = newArray(252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 248, 248, 248, 248, 248, 248, 248, 248, 248, 248, 244, 244, 244, 244, 244, 244, 244, 244, 244, 244, 240, 240, 240, 240, 240, 240, 240, 240, 240, 236, 236, 236, 236, 236, 236, 236, 236, 236, 236, 232, 232, 232, 232, 232, 232, 232, 232, 232, 232, 228, 228, 228, 228, 228, 228, 228, 228, 228, 224, 224, 224, 224, 224, 224, 224, 224, 224, 224, 220, 220, 220, 220, 220, 220, 220, 220, 220, 220, 216, 216, 216, 216, 216, 216, 216, 216, 216, 212, 212, 212, 212, 212, 212, 212, 212, 212, 212, 208, 208, 208, 208, 208, 208, 208, 208, 208, 208, 204, 204, 204, 204, 204, 204, 204, 204, 204, 200, 200, 200, 196, 196, 196, 192, 192, 188, 188, 188, 184, 184, 180, 180, 180, 176, 176, 172, 172, 172, 168, 168, 168, 164, 164, 160, 160, 160, 156, 156, 152, 152, 152, 148, 148, 144, 144, 144, 140, 140, 136, 136, 136, 132, 132, 132, 128, 128, 124, 124, 124, 120, 120, 116, 116, 116, 112, 112, 108, 108, 108, 104, 104, 100, 100, 100, 96, 96, 96, 92, 92, 88, 88, 88, 84, 84, 80, 80, 80, 76, 76, 72, 72, 72, 68, 68, 68, 64, 64, 60, 60, 60, 56, 56, 52, 52, 52, 48, 48, 44, 44, 44, 40, 40, 36, 36, 36, 32, 32, 32, 28, 28, 24, 24, 24, 20, 20, 16, 16, 16, 12, 12, 8, 8, 8, 4, 4, 0, 0);
		
	selectWindow("Vector Sum Angle dF/dt ("+ grid + " grid " + step +" step)");
	rename("Normalized Vector Sum Y ("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(0, 100);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Angle dF/dt ("+ grid + " grid " + step +" step)");
	rename("Max Vector Y ("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(0, 565);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Velocity dF/dt ("+ grid + " grid " + step +" step)");
	rename("Normalized Vector Sum X ("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(410, 100);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Velocity dF/dt ("+ grid + " grid " + step +" step)");
	rename("Max Vector X ("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(410, 565);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Objects map of dF Stack");
	setLocation(820, 720);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("dF Stack");
	rename("dF Stack Mask");
	setLocation(820, 385);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
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
	setLocation(820, 50);
	for(a=2; a<512/width; a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Angle mask ("+ grid + " grid " + step +" step)");
	rename("Normalized Vector Sum Y mask("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(1100, 100);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Angle mask ("+ grid + " grid " + step +" step)");
	rename("Max Vector Y mask("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(1100, 565);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Vector Sum Velocity mask ("+ grid + " grid " + step +" step)");
	rename("Normalized Vector Sum X mask("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(1509, 100);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	selectWindow("Max Wave Vector Velocity mask ("+ grid + " grid " + step +" step)");
	rename("Max Vector X mask("+ grid + " grid " + step +" step)");
	if(nSlices > 1) Stack.getStatistics(dummy, dummy, min, max);
	else getStatistics(dummy, dummy, min, max);
	if((-1*min > max)) setMinAndMax(min, -1*min);
	else setMinAndMax(-1*max, max);	
	setLut(redDisLUT, greenDisLUT, blueDisLUT);
	setLocation(1509, 565);
	for(a=1; a<((512/step)/2); a++){
		wait(100);
		run("In [+]");
	}
	if(nSlices > 1){
		setSlice(2);
		setSlice(1);
	}
	
	//Close the NaN mask
	close("dF/dt NaN mask");
	close("mask NaN mask");
	
	//Create user interface to navigate waves
	quitMacro = false;
	while(!quitMacro){
		waitForUser("Select the wave of interest");
		selectedTitle = getTitle();
		
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
			selectWindow("Normalized Vector Sum Y ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Max Vector Y ("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Normalized Vector Sum X ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
			selectWindow("Max Vector X ("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
			selectWindow("Normalized Vector Sum Y mask("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Max Vector Y mask("+ grid + " grid " + step +" step)");
			setSlice(waveID);
			selectWindow("Normalized Vector Sum X mask("+ grid + " grid " + step +" step)");
			setSlice(waveID);	
			selectWindow("Max Vector X mask("+ grid + " grid " + step +" step)");	
			setSlice(waveID);
	
			//Get the stack positions of the wave
			waveStart = getResult("BZ", waveID-1);
			waveEnd = waveStart + getResult("B-depth", waveID-1);
	
			for(a=waveStart; a<=waveEnd; a++){
				selectWindow("Processed dF Stack");
				setSlice(a);
				selectWindow("dF Stack Mask");
				setSlice(a);
				selectWindow("Objects map of dF Stack");
				setSlice(a);
				wait(100);
			}	
			selectWindow(selectedTitle);		
		}
		else{
			quitMacro = getBoolean("Would you like to quit the macro?");
		}
	}
}
	
function processStageII(image){
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
	
	//Convert stack to 8-bit
	selectWindow("Result of dF Stack");
	setSlice(1);
	run("Delete Slice");
	rename("dF Stack");
	selectWindow("dF Stack");
	Stack.getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	run("8-bit");
	run("Duplicate...", "duplicate title=[Objects map of dF Stack]");
		
}

function processStageIIIimage(image){		
	//Process the filter to remove noise and isolate waves
	//Generate dF/F stack
image = getTitle();
maxdF = 4;
	run("Duplicate...", "title=200z duplicate");
	selectWindow("200z");
	run("Median 3D...", "x=0 y=0 z=200");
	imageCalculator("Divide create 32-bit stack", image,"200z");
	close("200z");
	close(image);
	selectWindow("Result of " + image);
	rename("dF Stack");
	run("Macro...", "  code=[if(isNaN(v) || v > " + maxdF + ") v=0;] stack");
	
	//Remove noise and enrich for wave signal
	//remove pixel noise
	run("Median 3D...", "x=2 y=2 z=2");
	
	//solidify waves
	for(a=1; a<=nSlices; a++){
		setSlice(a);
		setThreshold(0.000000000, 0.000000000);
		run("Create Selection");
		run("Make Inverse");
		run("Mean...", "radius=10 slice");
		run("Select None");
	}
	resetThreshold();

	//Remove negative values
	run("Subtract...", "value=1 stack");
	run("Macro...", "  code=[if(v<0) v=0;] stack");
	
	//Create a mask of just the stage III waves
	run("Duplicate...", "duplicate title=mask");
	setAutoThreshold("Triangle dark stack");
	setOption("BlackBackground", false);

	//Show the current threshold and ask user to approve value
	setBatchMode("show");
	//Remove this condition if triangle consistently yields the correct results
	if(thresholdGUI){
		if(!getBoolean("Do you want to keep this threshold?")){
			run("Threshold...");
			waitForUser("Please adjust the threshold, press Apply, then press OK.");
		}
		else{
			run("Convert to Mask", "method=Triangle background=Dark black");
		}
	}
	else{
		run("Convert to Mask", "method=Triangle background=Dark black");
	}

	run("Divide...", "value=255 stack");
	
	//Clear background signal from stack
	imageCalculator("Multiply stack", "dF Stack", "mask");	
	close("mask");
	
	//Convert to 8-bit and create an object map segmenting each wave
	selectWindow("dF Stack");
	run("Duplicate...", "title=[1.tif] duplicate");
	selectWindow("1.tif");
	Stack.getStatistics(dummy, dummy, dummy, max);
	setMinAndMax(0, max);
	run("8-bit");
	run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 redirect_to=none");run("3D Objects Counter", "threshold=1 slice=900 min.=1000 max.=" + (1/0) + " objects statistics"); //1000 min size cutoff to remove non-wave phenomena
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
	
	//Calculate the dt stack
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
}

function stageIIsegmentMask(startSlice, endSlice, waveID){
	//Remove the preceding substack so that it can be concatenated back on later
	selectWindow("Objects map of dF Stack");
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

	//Code the wave ID via intensity
	selectWindow("Result of 2-wave");
	run("Divide...", "value=255.000 stack");
	run("Multiply...", "value=" + waveID + " stack");
	close("2-wave");

	//Rebuild the stack
	selectWindow("Result of 2-wave");
	rename("2-wave");
	if(nImages == 4) run("Concatenate...", "  title=[Objects map of dF Stack] image1=1-pre image2=2-wave image3=3-post image4=[-- None --]");
	if(nImages == 3) run("Concatenate...", "  title=[Objects map of dF Stack] image1=2-wave image2=3-post image3=[-- None --] image4=[-- None --]");

	//Create a results table for the vector analysis
	setResult("BZ", waveID-1, startSlice);
	setResult("B-depth", waveID-1, endSlice-startSlice);
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

	//Add a max projection of the wave mask to the NaN mask
	selectWindow("wave mask");
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow("MAX_wave mask");
	run("Select All");
	run("Copy");
	close("MAX_wave mask");
	selectWindow(analysisType + " NaN mask");
	setSlice(waveID);
	run("Paste");

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

	xVecSumArray = newArray(step*step);
	yVecSumArray = newArray(step*step);
	xNormVecSumArray = newArray(step*step);
	yNormVecSumArray = newArray(step*step);
	
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
			maxAngle = 0;
			maxXdist = 0;
			maxYdist = 0;
			for(a=0; a<waveXcm.length-1; a++){
				if(waveXcm[a] > -1){
					if(waveXcm[a+1] > -1){
						xDist = waveXcm[a+1] - waveXcm[a];
						yDist = waveYcm[a+1] - waveYcm[a];
						waveVel = sqrt((xDist*xDist)+(yDist*yDist));
						if(waveVel > maxVel){
							maxVel = waveVel;
							maxXdist = xDist;
							maxYdist = yDist;
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

			xVecSumArray[xGrid*step + yGrid] = maxXdist;
			yVecSumArray[xGrid*step + yGrid] = maxYdist;
			if(vecSumVel > 0){
				xNormVecSumArray[xGrid*step + yGrid] = xVecSum/velCount;
				yNormVecSumArray[xGrid*step + yGrid] = yVecSum/velCount;
			}
			else{
				xNormVecSumArray[xGrid*step + yGrid] = 0;
				yNormVecSumArray[xGrid*step + yGrid] = 0;	
			}
		}
	}

	//output the array onto the Max Velocity image
	selectWindow("Max Wave Vector Velocity " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){

			//If the output is for the XY vector sum coordinates, store these values, otherwise return the angle/mag
			if(matches(outputType, "XY Map")) setPixel(a, b, xVecSumArray[a*step + b]);
			else setPixel(a, b, maxVelocityArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
//	run("Median...", "radius=2 slice");

	//output the array onto the Max Angle image
	selectWindow("Max Wave Vector Angle " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			//If the output is for the XY vector sum coordinates, store these values, otherwise return the angle/mag
			if(matches(outputType, "XY Map")) setPixel(a, b, yVecSumArray[a*step + b]);
			
			//Use 360-angle to get rotation to be counter clockwise rather than clockwise
			else setPixel(a, b, 0-maxAngleArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
//	run("Median...", "radius=2 slice");
	
	//output the array onto the Vector Sum Velocity image
	selectWindow("Vector Sum Velocity " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			//If the output is for the XY vector sum coordinates, store these values, otherwise return the angle/mag
			if(matches(outputType, "XY Map")) setPixel(a, b, xNormVecSumArray[a*step + b]);
			else setPixel(a, b, vecSumVelArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
//	run("Median...", "radius=2 slice");
	
	//output the array onto the Vector Sum Angle image
	selectWindow("Vector Sum Angle " + analysisType + " ("+ grid + " grid " + step +" step)");
	setSlice(waveID);
	setMetadata("Label", "Wave " + waveID);
	for(a=0; a<step; a++){
		for(b=0; b<step; b++){
			//If the output is for the XY vector sum coordinates, store these values, otherwise return the angle/mag
			if(matches(outputType, "XY Map")) setPixel(a, b, yNormVecSumArray[a*step + b]);
			
			//Use 0-angle to get roation to be counter clockwise rather than clockwise
			else setPixel(a, b, 0-vecSumAngleArray[a*step + b]);
		}
	}
	//Remove Velocity outliers
//	run("Median...", "radius=2 slice");

	close("wave dF");
}

function quiverPlot(angleImage, speedImage){
	//Replace NaNs with zeros taking advantage of the fact that NaN != NaN by definition
	selectWindow(angleImage);
	run("Macro...", "code=[if (v != v) v=0; ] stack");
	selectWindow(speedImage);
	run("Macro...", "code=[if (v != v) v=0; ] stack");

	//Create a quiver plot for each slice in the stack, and concatenate them into a stack
	slices = nSlices;
	for(a=1; a<=slices; a++){
		//Create a copy of the current image in the stack
		selectWindow(angleImage);
		setSlice(a);
		run("Duplicate...", "title=angle");
		selectWindow(speedImage);
		setSlice(a);
		run("Duplicate...", "title=speed");

		//Create the corresponding quicer plot
		run("Quiver Plot","angle, speed, 512");

		//Close the angle and speed images
		close("angle");
		close("speed");

		//Remove Grid and tick marks
		selectWindow("Quiver Plot");
		Plot.setFormatFlags("0");
		
		//Create an image copy of the plot
		run("Duplicate...", "title=[Quiver Image]");

		//Close the quiver plot
		selectWindow("Quiver Plot");
		run("Close");

		//If the original data is a stack, then concatenate 
		selectWindow("Quiver Image");
		if(slices > 1){
			if(a == 1) rename("Quiver Stack");
			if(a > 1) run("Concatenate...", "  title=[Quiver Stack] image1=[Quiver Stack] image2=[Quiver Image] image3=[-- None --]");
		}
		else rename("Quiver Stack");
	}

	//Add the metadata back onto the stack
	selectWindow("Quiver Stack");
	for(a=1; a<=slices; a++){
		setSlice(a);
		setMetadata("Label", "Wave " + a);
	}

	//Crop the stack to only show the quiver arrows
	makeRectangle(60, 13, 513, 513);
	run("Crop");

	//Rename the stack based on the angle image name
	selectWindow("Quiver Stack");
	rename(replace(angleImage, " Angle", ""));

	//Close the original images used to create the plot
	close(angleImage);
	close(speedImage);

}

function colorCodeQuiver(plot, LUT, mask, object){	
	//Color code each wave by its progression in time
	for(a=0; a<nResults; a++){
		startSlice = getResult("BZ", a);
		stopSlice = getResult("B-depth",a) + startSlice;
				
		//Create a color coded image of the corresponding substack
		selectWindow(mask);
		run("Make Substack...", "  slices=" + startSlice + "-" + stopSlice);
		rename("subMask");
		selectWindow(object);
		run("Make Substack...", "  slices=" + startSlice + "-" + stopSlice);
		rename("subObject");
		setMinAndMax(0,1);
		run("Divide...", "value=255.000 stack");
		imageCalculator("Multiply stack", "subMask","subObject");
		close("subObject");
		selectWindow("subMask");
		run("Temporal-Color Code", "lut=" + LUT + " start=1 end=" + nSlices + "");
		close("subMask");
		
		//Concatenate the color coded images together as a stack
		if(a > 0) run("Concatenate...", "  title=MAX_colored image1=MAX_colored image2=MAX_colored-1 image3=[-- None --]");
	}

	//Resize the mask to match the dimensions of the quiver plot
	selectWindow("MAX_colored");
	run("Size...", "width=513 height=513 depth=" + nSlices + " constrain average interpolation=Bilinear");
	wait(10000);

	
	
	for(b=0; b<plot.length; b++){
		selectWindow("MAX_colored");
		run("Duplicate...", "title=1 duplicate");	
		//Subtract the plot image from the color coded mask to create a color coded plot
		imageCalculator("Subtract stack", "1", plot[b]);
	
		//Close extra images and rename color coded plot to same name as quiver plot
		close(plot[b]);
		selectWindow("1");
		rename(plot[b]);
	
		//Trim border from plot
		selectWindow(plot[b]);
		run("Canvas Size...", "width=511 height=511 position=Center zero");
	}
	close("MAX_colored");
}
