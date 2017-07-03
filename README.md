# MATLAB implementation of B-COSFIRE filters
B-COSFIRE filters are non-linear trainable filters for detection of elongated patterns in images.  
This is the code of the trainable non-linear B-COSFIRE filters for delineation of elongated patterns
in images.  
The B-COSFIRE filters are proposed in the paper:

[Azzopardi, G., Strisciuglio, N., Vento, M., Petkov, N.: Trainable COSFIRE  filters for vessel delineation with application to retinal images. Medical Image Analysis 19(1), 46 - 57, 2015](http://www.cs.rug.nl/~george/articles/MEDIA2015.pdf)


## Applications
For applications of B-COSFIRE filters to different kinds of images and problems, please refer to the following codes.

### ExampleBloodVesselSegmentation.m
The example code for the configuration of a line detector and a line-ending detector and their 
applications to the segmentation of blood vessels in retinal images. 
The final response is the summation of the responses of the two filters. 

### INRIAImages.m
Application of the B-COSFIRE filters for detection of elongated structures in images.  
This code provides the benchmark results on the images of the INRIA data
set used in the paper  
_Strisciuglio, N. Petkov, N._ "Delineation of line patterns in images using B-COSFIRE filters", IWOBI 2017.

The images used in this example are available at [this website](http://www-sop.inria.fr/members/Florent.Lafarge/benchmark/line-network_extraction/line-networks.html).

### PavementCrackDelineation.m
_In preparation_

## Reference publications
If you use this code please cite the following articles. 

__Original paper:__  

	@article{BCOSFIRE-MedIA2015,
	title = "Trainable {COSFIRE} filters for vessel delineation with application to retinal images ",
	journal = "Medical Image Analysis ",
	volume = "19",
	number = "1",
	pages = "46 - 57",
	year = "2015",
	note = "",
	issn = "1361-8415",
	doi = "http://dx.doi.org/10.1016/j.media.2014.08.002",
	author = "George Azzopardi and Nicola Strisciuglio and Mario Vento and Nicolai Petkov",
	} 
 
__Supervised learning of B-COSFIRE filters:__  

	@article{BCOSFIRE-selection2016,
	author={Strisciuglio, Nicola and Azzopardi, George and Vento, Mario and Petkov, Nicolai},
	title={Supervised vessel delineation in retinal fundus images with the automatic selection of {B-COSFIRE} filters},
	journal={Machine Vision and Applications},
	year={2016},
	pages={1?13},
	issn={1432-1769},
	} 


## Changelog

__3 Jul 2017__
applyCOSFIRE_inhib.m:132/137 - Approximatation of the shifting amount corrected
The results published in the paper "_Strisciuglio, N. Petkov, N._ "Delineation of line patterns in images using B-COSFIRE filters", IWOBI 2017." are slightly different due to this bug fixing.

