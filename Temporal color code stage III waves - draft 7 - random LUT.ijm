close("*");
open(File.openDialog("Choose a 16x stage II wave file."));
image = getTitle();

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
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 redirect_to=none");run("3D Objects Counter", "threshold=1 slice=900 min.=1000 max.=29491200 objects statistics"); //1000 min size cutoff to remove non-wave phenomena

//Create random lUT and apply to objects map
selectWindow("Objects map of dF Stack");
reds = newArray(0, 231, 25, 27, 112, 89, 53, 77, 155, 153, 91, 19, 25, 135, 187, 40, 52, 39, 147, 72, 92, 23, 5, 202, 52, 50, 108, 66, 238, 46, 136, 8, 162, 126, 75, 60, 135, 167, 136, 244, 161, 204, 158, 112, 192, 2, 98, 207, 233, 121, 191, 18, 210, 151, 252, 155, 139, 42, 188, 170, 127, 151, 38, 16, 227, 120, 137, 2, 72, 71, 214, 130, 194, 96, 102, 33, 92, 47, 211, 226, 237, 132, 244, 45, 82, 73, 239, 198, 118, 191, 170, 238, 177, 246, 66, 5, 44, 3, 18, 40, 226, 94, 130, 216, 68, 89, 150, 40, 96, 155, 95, 5, 132, 88, 124, 241, 143, 15, 1, 220, 46, 220, 216, 155, 190, 4, 98, 33, 142, 153, 185, 61, 153, 160, 164, 102, 75, 8, 26, 231, 160, 245, 119, 69, 95, 137, 232, 249, 89, 220, 54, 3, 43, 134, 172, 31, 106, 234, 132, 1, 29, 65, 12, 107, 52, 196, 95, 165, 4, 101, 124, 240, 203, 50, 142, 231, 5, 23, 43, 198, 41, 80, 66, 232, 86, 151, 126, 51, 122, 111, 162, 192, 148, 210, 5, 251, 40, 176, 32, 2, 22, 91, 180, 31, 218, 9, 10, 178, 27, 115, 54, 199, 163, 10, 180, 222, 102, 198, 202, 220, 96, 145, 237, 127, 172, 51, 64, 47, 84, 37, 196, 147, 244, 206, 244, 43, 170, 186, 162, 157, 125, 230, 212, 140, 186, 127, 12, 48, 0, 92, 168, 73, 228, 121, 248, 255);
greens = newArray(0, 217, 131, 18, 66, 198, 59, 170, 108, 8, 167, 207, 248, 138, 215, 204, 95, 249, 102, 66, 1, 138, 71, 33, 209, 80, 72, 87, 129, 24, 200, 98, 16, 160, 47, 1, 224, 49, 126, 41, 235, 205, 84, 249, 222, 125, 5, 58, 90, 137, 73, 98, 109, 167, 91, 106, 68, 23, 10, 241, 51, 35, 77, 112, 243, 235, 53, 41, 21, 134, 106, 60, 231, 107, 124, 96, 131, 62, 213, 220, 78, 96, 44, 106, 128, 96, 129, 164, 59, 86, 45, 87, 237, 192, 171, 93, 223, 206, 158, 42, 255, 175, 142, 177, 48, 67, 221, 123, 125, 182, 135, 31, 163, 211, 220, 28, 81, 113, 235, 236, 30, 104, 238, 227, 18, 134, 193, 15, 122, 151, 6, 132, 0, 128, 88, 20, 130, 87, 127, 55, 13, 76, 15, 124, 251, 160, 177, 179, 14, 7, 189, 49, 210, 77, 63, 132, 17, 84, 214, 63, 206, 252, 184, 168, 109, 129, 89, 70, 66, 151, 151, 100, 27, 123, 35, 210, 112, 183, 135, 97, 19, 7, 159, 221, 46, 253, 42, 229, 101, 187, 10, 33, 152, 138, 236, 208, 117, 230, 98, 200, 139, 200, 255, 19, 219, 183, 181, 3, 43, 143, 130, 75, 21, 228, 121, 208, 51, 82, 41, 233, 56, 220, 190, 176, 136, 108, 88, 118, 228, 206, 11, 170, 236, 232, 204, 241, 241, 69, 71, 28, 143, 207, 52, 188, 183, 80, 4, 222, 162, 30, 213, 228, 119, 142, 10, 255);
blues = newArray(0, 43, 203, 219, 253, 158, 5, 190, 72, 11, 23, 233, 220, 246, 53, 10, 90, 49, 215, 182, 74, 50, 27, 107, 39, 48, 192, 134, 247, 89, 14, 3, 67, 65, 30, 136, 78, 129, 178, 138, 186, 204, 5, 160, 18, 103, 255, 162, 42, 128, 213, 204, 49, 80, 181, 130, 60, 185, 31, 203, 184, 89, 108, 190, 109, 157, 231, 62, 128, 96, 150, 153, 160, 54, 24, 143, 90, 216, 128, 120, 87, 244, 15, 213, 235, 142, 140, 33, 98, 164, 202, 38, 84, 63, 229, 163, 28, 239, 210, 131, 79, 83, 168, 79, 89, 170, 26, 168, 149, 217, 31, 20, 11, 141, 121, 139, 21, 58, 194, 75, 110, 234, 16, 126, 24, 41, 62, 88, 232, 38, 243, 83, 195, 58, 84, 106, 151, 32, 146, 24, 140, 217, 176, 186, 174, 170, 250, 1, 48, 141, 99, 213, 127, 46, 97, 12, 143, 237, 153, 185, 72, 170, 23, 222, 216, 23, 92, 232, 54, 64, 72, 128, 182, 38, 192, 138, 115, 162, 231, 2, 143, 117, 167, 196, 4, 182, 220, 52, 252, 34, 2, 233, 132, 135, 230, 36, 199, 228, 222, 43, 119, 7, 148, 59, 10, 35, 158, 237, 17, 116, 110, 129, 172, 233, 172, 47, 114, 26, 115, 212, 177, 157, 74, 183, 102, 132, 151, 18, 242, 242, 12, 138, 21, 159, 165, 213, 230, 147, 174, 206, 116, 9, 242, 233, 202, 205, 116, 169, 80, 53, 161, 239, 211, 73, 96, 255);
setLut(reds, greens, blues);

//Remove each wave one at a time and apply a temporal color code
selectWindow("Objects map of dF Stack");
max = nResults;
getDimensions(width, height, channels, slices, frames);
newImage("dt Stack", "8-bit black", width, height, slices);

for(a=1; a<=max; a++){
	selectWindow("Objects map of dF Stack");
	
	//Duplicate the object map, and remove everything but the current wave
	run("Duplicate...", "title=wave duplicate");
	selectWindow("wave");

	waveStart = getResult("BZ", a-1);
	waveEnd = waveStart + getResult("B-depth", a-1);
				
	temporalColorCode(waveStart, waveEnd, a, width, height);
	
}


//Color the stack using a modified physics LUT
selectWindow("dt Stack");
run("physics");
getLut(reds, greens, blues);
reds[0] = 0;
greens[0] = 0;
blues[0] = 0;
setLut(reds, greens, blues);
run("RGB Color");
run("Volume Viewer");

function temporalColorCode(startSlice, endSlice, waveID, width, height){
	
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
	
	//find where each pixel peaks in intensity
	selectWindow("wave dF");
	run("Z Project...", "projection=[Max Intensity]");
	imageCalculator("Divide create 32-bit stack", "wave dF","MAX_wave dF");
	selectWindow("Result of wave dF");
	setMinAndMax(0.9990, 1.0000);
	run("8-bit");
	close("MAX_wave dF");

	//Code the time of the wave via intensity
	selectWindow("Result of wave dF");
	for(a=1; a<=nSlices; a++){
		setSlice(nSlices - a + 1);
		dIntensity = (a/nSlices)*254;
		run("Subtract...", "value=" + dIntensity + " slice");
	}
	close("wave dF");


	//Add in the remaining slices
	selectWindow("Result of wave dF");
	if(startSlice > 2) {
		newImage("1-pre", "8-bit black", width, height, startSlice-1);
		run("Concatenate...", "  title=[Result of wave dF] image1=1-pre image2=[Result of wave dF] image3=[-- None --] image4=[-- None --]");
	}

	selectWindow("Result of wave dF");
	while(nSlices < slices){
		setSlice(nSlices);
		run("Add Slice");
	}

	//Add this wave to the final wave stack
	imageCalculator("Add stack", "dt Stack","Result of wave dF");
	close("Result of wave dF");
}

