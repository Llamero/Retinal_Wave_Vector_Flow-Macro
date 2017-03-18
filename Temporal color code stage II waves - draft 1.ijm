//Convert stack to 8-bit
run("Duplicate...", "title=color duplicate");
Stack.getStatistics(dummy, dummy, dummy, max);
setMinAndMax(0, max);
run("8-bit");

//Find each wave and color code them
Stack.getStatistics(dummy, stackMean);
startFound = false;
endFound = false;

//Start at slice 2 because slice 1 is an artifact from calculating dT
for(a=2; a<=nSlices; a++){
		setSlice(a);
		getStatistics(dummy, mean);

		//If slice mean > stack mean, then wave start has been found
		if(!startFound && mean > stackMean){
			startFound = !startFound;
			waveStart = a;
		}
		
		//If slice mean < stack mean, then wave end has been found
		if(startFound && mean < stackMean){
			endFound = !endFound;
			waveEnd = a;
		}

		//If a full wave is found, remove it from the stack and analyze it
		if(startFound && endFound){
			startFound = !startFound;
			endFound = !endFound;
print(waveStart);
print(waveEnd);
		}
		
}
