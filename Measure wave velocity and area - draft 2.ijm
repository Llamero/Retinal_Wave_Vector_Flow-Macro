histMin = 0;
histMax = 182; //Max possible distance in 128x128
histBins = histMax+1;
histArray = newArray(histBins);

close("*");
run("Clear Results");
setBackgroundColor(0, 0, 0);
dir = getDirectory("Choose input directory");
outDir = getDirectory("Choose output directory");
list = getFileList(dir);

setBatchMode(true);

nFile = 0;
searchArray = newArray(list.length*2);

//Count all "_object.tif files
for(a=0; a<list.length; a++){
	if(endsWith(list[a], "_object.tif")){
		//Confirm there is a matching "_MASK.tif" file
		temp = replace(list[a], "_object.tif", "_MASK.tif");
		for(b=0; b<list.length; b++){
			if(list[b] == temp){
				searchArray[2*nFile] = list[a];
				searchArray[2*nFile+1] = list[b];
				nFile++;
			}
		}
	}
}

//Generate a new array containing just the pairs of object and mask files, in order
processArray = newArray(2*nFile);
nFile = 0;
for(a=0; a<searchArray.length; a++){
	if(searchArray[a] != 0) processArray[nFile++] = searchArray[a];	
}

//Process each pair of images
for(a=0; a<nFile; a+=2){
	open(dir+processArray[a]); //Open object file
	sampleID = replace(processArray[a], "_object.tif", ""); //Get name of current sample
	rename("object");
	setMinAndMax(0, 255); //convert object to 8-bit
	run("Grays");
	run("8-bit");
	Stack.getStatistics(dummy, dummy, dummy, nWaves, dummy); //Count max number of waves in mask
	run("Duplicate...", "title=Raw duplicate");
	open(dir+processArray[a+1]); //Open mask file
	rename("mask");

	//Create a temporary matrix to store measurements
	newImage("Hist-Results", "32-bit black", histBins, nWaves, 1);
	
	//Remove waves outside of mask
	selectWindow("mask");
	Stack.getStatistics(dummy, dummy, dummy, max, dummy);
	setMinAndMax(0,max);
	run("8-bit");
	run("Divide...", "value=255.000 stack");
	imageCalculator("Multiply stack", "object","mask");

	//Measure the speed of each wave
	for(b=1; b<=nWaves; b++){
		selectWindow("object");
		run("Duplicate...", "title=2 duplicate");
		
		//Isolate the wave
		selectWindow("2");
		setThreshold(b,b);
		run("Convert to Mask", "method=Default background=Dark black");
		slice = 1; 
		while((slice <= nSlices) && (nSlices >  1)){
			setSlice(slice);
			getStatistics(dummy, dummy, dummy, max);
			if(max == 0) run("Delete Slice");
			else slice++;
		}
		
		//If there is only one slice left, no wave was found so close window
		if(nSlices <= 1) close("2");

		//Otherwise, analyze the wave
		else{
			setResult("ID", nResults, b); //Record ID of wave on results table

			//Measure mask cropped area of wave
			selectWindow("2");
			run("Z Project...", "projection=[Max Intensity]");
			selectWindow("MAX_2");
			setThreshold(1, 255);
			run("Create Selection");
			getStatistics(area);
			setResult("Mask_Area_(pixels)", nResults-1, area);
			close("MAX_2");

			//Measure raw area of wave
			selectWindow("Raw");
			run("Duplicate...", "title=Raw2 duplicate");
			selectWindow("Raw2");
			setThreshold(b, b);
			run("Convert to Mask", "method=Default background=Dark black");
			run("Z Project...", "projection=[Max Intensity]");
			selectWindow("MAX_Raw2");
			setThreshold(1, 255);
			run("Create Selection");
			getStatistics(area);
			setResult("Raw_Area_(pixels)", nResults-1, area);
			close("MAX_Raw2");
			close("Raw2");
	
			
			//Make temporary image to store histogram values
			selectWindow("2");
			newImage("Temp", "32-bit black", histBins, nSlices-1, 1);
	
			//Make an wave boundary stack
			selectWindow("2");
			run("Duplicate...", "title=dx1 duplicate");
			run("Duplicate...", "title=dx2 duplicate");
			selectWindow("dx1"); //Remove first slice of dx1
			run("Erode", "stack"); //Add extra perimeter of pixels on dx1
			imageCalculator("XOR stack", "dx1","dx2");
			close("dx2");
			close("2");

			//Keep only edges inside boundary
			selectWindow("mask");
			setThreshold(1,1);
			run("Create Selection");
			selectWindow("dx1");
			run("Restore Selection");
			run("Clear Outside", "stack");
			run("Select None");

			//Find distance travelled between edges
			selectWindow("dx1");
			run("Duplicate...", "title=EDT duplicate"); //Generate distance map
			selectWindow("EDT");
			run("Distance Map", "stack"); //Phase shift stacks to get dt
			setSlice(nSlices);
			run("Delete Slice");
			selectWindow("dx1");
			setSlice(1);
			run("Delete Slice");

			//Set background of edge mask to NaN
			imageCalculator("Divide create 32-bit stack", "dx1","dx1");
			close("dx1");
			selectWindow("Result of dx1");

			//Get dx/dt stack
			imageCalculator("Multiply create stack", "Result of dx1","EDT");
			close("Result of dx1");
			close("EDT");

			//Measure the dx on each slice
			selectWindow("Result of Result of dx1");
			for(c=1; c<=nSlices; c++){				
				setSlice(c);
				getHistogram(values, counts, histBins, histMin, histMax);
				selectWindow("Temp");
				for(d=0; d<histBins; d++) setPixel(d, c-1, counts[d]);
				selectWindow("Result of Result of dx1");
			}
			//Measure stats of stack
			if(nSlices > 1) Stack.getStatistics(dummy, mean, dummy, max, stdDev); 
			else getStatistics(dummy, mean, dummy, max, stdDev);
			setResult("Mean_Speed_(px/frame)", nResults-1, mean);
			setResult("Max_Speed_(px/frame)", nResults-1, max);
			setResult("stdDev_Speed_(px/frame)", nResults-1, stdDev);
			setResult("Duration_(Frames)", nResults-1, nSlices);
			close("Result of Result of dx1");
			
			//Send histogram to results matrix
			selectWindow("Temp");
			run("Bin...", "x=1 y=" + c-1 + "  bin=Sum"); //Sum histograms from all slices
			for(d=0; d<2; d++){
				for(c=0; c<histBins; c++){
					if(d) setPixel(c,b-1,histArray[c]);
					else histArray[c] = getPixel(c,0);
				}
				selectWindow("Hist-Results"); //Switch to hist results for sending results
			}
			close("temp");
		}
	}
	close("Raw");
	close("mask");
	close("object");
	selectWindow("Hist-Results");
	saveAs("Text Image", outDir + sampleID + "-Histogram per wave.txt");
	close("Hist-Results");
	saveAs("Results", outDir + sampleID + "-Stats per wave.csv");
	run("Clear Results");
}

setBatchMode("exit and display");
