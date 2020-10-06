# iGEM2020_UiOslo_Norway (sal.coli)
Fish school model in julia where you can export data to a julia script for machine learning and to blender for visualization
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

- Running the model 

After installation simply download the Julia file iGEMSchoolingModel.jl and parametersForModel.txt and put them in the same folder. Then open iGEMSchoolingModel.jl with your julia editor and hit "run all". You can play around with the schooling model by changing parameters in parametersForModel without needing to touch the code itself. Depending on your choices with the parameters it will generate data for analysis and animations + a simple scatter animation 


# Blender: Vizualization
-   Import of template model from .obj file
-   Setting up our import script in the scripting menu
-   Pre-run of materials and modifiers for template model.
-   Render settings and output


