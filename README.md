# iGEM2020_UiOslo_Norway (sal.coli)
Fish school model in julia where you can export data to a julia script for machine learning and to blender for visualization. 
The purpose of our project is to investigate if it is feasable to detect disease in individuals by using measures on collective behaviour. We have therefor 
implemented a simple discrete stochastic schooling model where we can change some parameters to create "sick" fish and analyse different measures with a nerual net. Our work is now contanied in three parts, a schooling model iGEMSchoolingModel.jl which generates data for our other two parts. The analysis part iGEMDataAnalysis.jl which consist of a nerual net that is trained and tested on dataforAnalaysis.CSV outputed by the model. And finally we have visualization part consisting of blenderScript.py which imports trajectories from the schooling model outputed in dataforVisualization.CSV. The model is easy to use by non programers as the parameters can be simply set in a txt file and no programming is necisarry. We hope that someone will come along and extend this project as it has the capability to be a usefull tool for scientist and those working with the diagnoistics of fish diseases.
# installation 

To use our repository to the fullest you will need to install Julia, blender and ffmpeg. 

- Julia 

Instructions for Julia installation can be found at https://julialang.org/downloads/, there is a prepackaged version with an IDE called juliaPro which is the easiest way to install Julia. The other way to install that we recomend is to first download Atom as described here https://atom.io/. Then follow the instructions found here https://docs.junolab.org/stable/man/installation/ to install juno. 

Inside of the IDE packages are added to Julia by using the command Pkg.add("packageName"). Keep in mind that package names are cAsE sensetive. In the top of our code you will find a list of packages that we are using. In Julia this looks like "using Flux", for each package go the terminal (REPL) in your IDE and type Pkg.add("packageName") for eksample Pkg.add("Flux"). Leaving this out of the code itself means that Julia does not need to use time on checking the package every time it runs. If a package is not installed this will throw a very clear error stating "Package packageName not found in currnet path". 


- Blender

Blender can be downloaded here https://www.blender.org/download/ . On ubuntu it is also found as an easy install in the Ubuntu Software. 

- FFMPEG

FFMPEG can be found here https://ffmpeg.org/download.html. You can either install it or simply put the .exe in the same folder as the schooling model. On Ubuntu installation instructions can be found here https://linuxize.com/post/how-to-install-ffmpeg-on-ubuntu-18-04/ and it is also found in Ubuntu Software


# Schooling model 
- Descreption 
![Model description](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/Parameters-in-separate-text-file/discreteschoolingmodeltest.png)


- Running the model 

After installation of software and packages simply download the Julia file iGEMSchoolingModel.jl and parametersForModel.txt and put them in the same folder. Then open iGEMSchoolingModel.jl with your julia editor and hit "run all". You can play around with the schooling model by changing parameters in parametersForModel without needing to touch the code itself. Depending on your choices with the parameters it will generate data for analysis and animations + a simple scatter animation 


# Blender: Vizualization
-   Import of template model from .obj file
-   Setting up our import script in the scripting menu
-   Pre-run of materials and modifiers for template model.
-   Render settings and output


