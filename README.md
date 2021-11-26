# toso2021-comment

Matlab code (tested on versions 2019b and 2020b) for reanalyzing the behavioral & neural [data](https://data.mendeley.com/datasets/wp9h39kbtv/2) from [Toso et al. 2021](https://doi.org/10.1016/j.neuron.2021.08.020).

### toso2021_wrapper.m  
- Loads the data;
- Sets _if_ and _where_ to save figures;
- Runs all other scripts in sequence (in the same order as they appear below);

### toso2021_preface.m
- Curates the data & prints _before_ & _after_ metrics;
- Parses the data;
- Sets neuron selection criteria;
- Sets aesthetic preferences for figures & axes;
- Sets all color schemes;

### toso2021_behavior.m
- Plots stimulus pairs with the corresponding average performance;
<img src="panels/sampling_scheme.svg" width="500"/>

- Same as above, plus a gradient representing the hypothesized continuous performance so as to allow for a better visualization of _contraction bias_ on T1;
<img src="panels/contraction_bias.svg" width="500"/>

- Plots psychometric curves assuming T2 as the stimulus & split by I1;
<img src="panels/psychometric_curves_i1.svg" width="500"/>

- Same as above, but split by I2;
<img src="panels/psychometric_curves_i2.svg" width="500"/>

- Fits a generalized linear model (GLM) to choice data using T1, T2, I1 & I2 as predictors;
<img src="panels/choice_GLM.svg" width="500"/>

### toso2021_trialTypeDistributions.m
- Plots the joint distribution of trial counts and T2s that neurons were recorded for;

### toso2021_neuronSelection.m
- Selects neurons according to the criteria specified in `toso2021_preface.m` & prints how many passed selection (**affects all subsequent scripts!**);

### toso2021_overallModulation.m

### toso2021_rasters.m

### toso2021_PCA.m

### toso2021_neurometricCurves.m

### toso2021_naiveBayesDecoder.m
