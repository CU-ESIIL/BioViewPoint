# Data Processing Documentation

## Overview
We aim to harness geotagged biodiversity data in the modelling of environmental conditions represented by multispectral satellite data. Additionally, given the importance of functional diversity in maintaining and promoting ecosystem functioning, we will use our modelling framework to explore scenarios of environmental change in the absence of species belonging to particular functional groups. We will develop and test our approach in areas targeted by the North American Breeding Bird Survey (BBS), using data obtained between 2015 and 2021.

## Data Sources
Our project will depend exclusively on open-access data. We will use:
* **Landsat (LT) surface reflectances**, specifically from LT8 and LT9 sensors.
* **Differences data sources on the occurrence of bird species**, namely BBS, GBIF, and Xeno-canto
* **Land cover data** for all of North American (i.e. North American Environmental Atlas)
* **Information on functional traits** for every known bird species (i.e. AVONET)
* **Data on species function interactions** for every bird species (i.e. GloBI)

## CyVerse Discovery Environment
Instructions for setting up and using the CyVerse Discovery Environment for data processing. Tips for cloud-based data access and processing.

## Data Processing Steps
1. Acquisition of Landsat acquisitions during BBS observation months, and over BBS sites
2. Derivation of annual, multispectral, pheonological composites centered around BBS surveying periods
3. Extraction and harmonization of species observations from BBS, GBIF, Xeno-Canto into tabular checklists
4. Detection of causal interactions, and detection of causal effect sizes, between changes species compositions and changes multispectral data
5. Use of step 4 to reduce list of test sites for subsequent modelling
6. Development of GAN models to predict multispectral satellite data (step 2) based on species compositions (steps 3) for the selected test sites (step 5)
7. Use of spectral decomposition to distinguish proportions of land cover types based on national land cover data

### Using GDAL VSI
Guidance on using GDAL VSI (Virtual System Interface) for data access and processing. Example commands or scripts:
```bash
gdal_translate /vsicurl/http://example.com/data.tif output.tif
```

## Cloud-Optimized Data
Advantages of using cloud-optimized data formats and processing data without downloading. Instructions for such processes.

## Data Storage
(Information on storing processed data, with guidelines for choosing between the repository and CyVerse Data Store)
Satellite data: 
Species observation data: 

## Best Practices

Recommendations for efficient and responsible data processing in the cloud. Tips to ensure data integrity and reproducibility.

## Challenges and Troubleshooting

Common challenges in data processing and potential solutions. Resources for troubleshooting in the CyVerse Discovery Environment.

## Conclusions

Summary of the data processing phase and its outcomes. Reflect on the methods used.

## References

Citations of tools, data sources, and other references used in the data processing phase.
