# Integrated_MT_TFM
Latest compilations of MT_TFM geared etween 2016-06-28 through 2021-10-31 for the my PhD thesis entitled, **"Integration of Magnetic Tweezers and Traction Force Microscopy to Investigate Extracellular Matrix Microrheology and Keratinocyte Mechanobiology"** [1].

This code is a compilation of other codes that is to be used to conduct the complete analysis for the following:

# Dependencies
For this code to be guaranteed to work, use MATLAB 2021b. Previous version as old as MATLAB 2018a have been not been tested throughly for code parts at later times.
The project needs the following MATLAB toolboxes and add-ons: 
* Curve Fitting Toolbox
* Deep Learning Toolbox
* Image Processing Toolbox
* MATLAB
* Optimization Toolbox
* Parallel Computing Toolbox
* Signal Processing Toolbox
* Statistics and Machine Learning Toolbox
* Symbolic Math
* C\C++ Library Header
* C\C++ System Header

## Chapter 2 Code [2]


## Chapter 3 Code [3]
1. DIC Video Analysis (MT):
	1. Run Dr. Sander Modified code to track the magnetic bead. See protocol on how to execute that code.
	2. Run ExtractBeadCoorindates
	3. Plot Big Delta vs. Time
	4. Plot Small Delta vs. Time
	5. Plot Force vs. Time, based on calibration curve
		* Modified the code so that in-between values are not mapped to the closest force curve.

2. EPI videos analysis (TFM): 
	1. Run TFM Package by Han et al. See protocol for the parameters used. Track displacement and calculate force using FTTC method.
	2. Using displField.mat output generated the following:
		1. tracked bead overlays on epi video
		2. displacement vector overlays on epi video.
		3. displacement magnitude heat map (and maybe vector overlays) based on the epi video.
		4. Plot small delta for hot spot vs. time.
	3. Using forceField.mat output from the TFM package: 
		1. traction stress vector overlays on epi video.
		2. traction stress magnitude (and maybe traction vector overlays) based on the epi video.
		3. traction force (integrated stresses over the area) vs. time.

3. Compare MT force vs. TFM force. Use timestamps to match results.**

## Chapter 4 Code




## Chapter 5 Code

## Previous Notes
### Integrated MT & TFM
Contains MT/TFM Integration Code as used in: Moghram et. al. "Integration of magnetic tweezers and traction force microscopy...." , AIP Advances 11, 045216 (2021). https://doi.org/10.1063/5.0041262

#### Instructions
1. Run movieselectorGUI
2. Create movie data: following parameters
3. Run TFMpackageGUI
4. Following instruction


#### Data Analysis
1. Analyze DIC videos
2. Analyze EPI videos
3. Combine both analyses

4. calculate elastic modulus using forces-balance
5. calculate elastic modulus using energetics balance.

## Plots



# References
[1]
[2]
[3]

