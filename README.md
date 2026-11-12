# Automated Detection of Micro-Cracks in Solar Cells

### Project Description

#### Summary
This MATLAB project processes electroluminescence (EL) images of photovoltaic cells to highlight suspected micro-cracks and flag cells with candidate defects.

#### Course concepts used
1. Grayscale conversion, resizing to 300 × 300 pixels, and 8-connected component processing.
2. Singular value decomposition (SVD) for background estimation and the 2-D discrete Fourier transform for frequency-domain filtering.
3. Median filtering, contrast-limited adaptive histogram equalization (CLAHE), and Gaussian low-pass filtering.
4. Morphological black-hat filtering, area opening, skeletonization, and pseudocolor visualization.

#### Additional concepts used
1. Median absolute deviation for adaptive thresholding.
2. Connected-component measurements such as eccentricity, major-axis length, area, and orientation.

#### Dataset
[ELPV dataset](https://github.com/zae-bayern/elpv-dataset) contains EL images of monocrystalline and polycrystalline solar cells and image-level defect-probability labels.

#### Novelty
The pipeline combines a low-rank SVD background estimate with morphological filtering to detect dark candidate regions. It uses both the total skeleton length of elongated candidates and the area of larger candidates to make a cell-level decision.

### Contributors
Contributor names and SRNs are pending.

### Steps
1. Clone this repository and open its root folder in MATLAB.
2. Use MATLAB with Image Processing Toolbox. Arrange the ELPV files so that the repository root contains elpv_dataset/data/labels.csv and elpv_dataset/data/images/.
3. Run the project MATLAB script. It displays the processing stages for cell0003.png and evaluates image-level predictions on confidently labelled ELPV cells.

### Outputs
The script displays the original image and histogram, preprocessed image, SVD background and residual, DFT spectrum, filtered residual, black-hat heat map, and a red candidate-region overlay. It also reports accuracy, precision, recall, and F1 score and displays a confusion matrix. Sample input images and matching output exports are pending.

### References
- [ELPV dataset and citation information](https://github.com/zae-bayern/elpv-dataset)

### Limitations and Future Work
ELPV provides image-level defect labels. These labels support cell-level evaluation, while pixel-level crack localization would require annotated crack masks. Cell texture and grid lines may produce false detections, and faint cracks may be missed. Future work can evaluate localization against manual masks and assess thresholds on a separate validation set.
