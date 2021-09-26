# Integrated_MT_TFM
Latest compilations of MT_TFM geared towards AIM3 of my PhD thesis entitled
**"Integration of Magnetic Tweezers and Traction Force Microscopy to Investigate Extracellular Matrix Microrheology and Keratinocyte Mechanobiology"**
by **Waddah Moghram**, PhD student in Biomedical Engineering at the University of Iowa Between 2016-06-28 through 2021-10-31.**

This code is a compilation of other codes that is to be used to conduct the complete analysis for the following:

## Chapter 2 Code



## Chapter 3 Code
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



# References
