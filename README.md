![Logo](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Logo_with_title.png)
# iGEM2020_UiOslo_Norway (sal.coli)
Fish school model in julia where you can export data to a julia script for machine learning and to blender for visualization. The purpose of our project is to investigate if it is feasable to detect disease in individuals by using measures on collective behaviour. We have therefor implemented a simple discrete stochastic schooling model where we can change some parameters to create "sick" fish and analyse different measures with a nerual net. Our work is now contanied in three parts:

1. A schooling model, iGEMSchoolingModel.jl, which generates data for our other two parts. 

2. The analysis part iGEMDataAnalysis.jl which consist of a nerual net that is trained and tested on dataforAnalaysis.CSV outputed by the model. 

3. And finally we have visualization part consisting of blenderScript.py which imports trajectories from the schooling model outputed in dataforVisualization.CSV.

The model is easy to use by non programers as the parameters can be simply set in a txt file and no programming is necisarry. We hope that someone will come along and extend this project as it has the capability to be a usefull tool for scientist and those working with the diagnoistics of fish diseases. We have designed the code as best as possible to allow for introducing different and realistic behaviours. 

# Installation and setup

To use our repository to the fullest you will need to install Julia, blender and ffmpeg. 

- Julia 

Instructions for Julia installation can be found at https://julialang.org/downloads/, there is a prepackaged version with an IDE called juliaPro which is the easiest way to install Julia. The other way to install that we recomend is to first download Atom as described here https://atom.io/. Then follow the instructions found here https://docs.junolab.org/stable/man/installation/ to install juno. 

Inside of the IDE packages are added to Julia by using the command Pkg.add("packageName"). Keep in mind that package names are cAsE sensetive. In the top of our code you will find a list of packages that we are using. In Julia this looks like "using Flux", for each package go the terminal (REPL) in your IDE and type Pkg.add("packageName") for eksample Pkg.add("Flux"). Leaving this out of the code itself means that Julia does not need to use time on checking the package every time it runs. If a package is not installed this will throw a very clear error stating "Package packageName not found in currnet path". 


- Blender

Blender can be downloaded here https://www.blender.org/download/.
On ubuntu it is also found as an easy install in the Ubuntu Software. 
We have tested this this project on versions 2.83 & 2.9.

- FFMPEG

FFMPEG can be found here https://ffmpeg.org/download.html. You can either install it or simply put the .exe in the same folder as the schooling model. On Ubuntu installation instructions can be found here https://linuxize.com/post/how-to-install-ffmpeg-on-ubuntu-18-04/ and it is also found in Ubuntu Software


# Schooling model 
Description of the discrete stochastic schooling model that is currently implemented. 
![Model description](https://github.com/igemsoftware2020/UiOslo-Norway/blob/master/DescriptionDiscreteStochasticSchoolingModel.png)
This model is an extension to 3 dimensions of "Simulating The Collective Behavior of Schooling Fish With A Discrete Stochastic Model" by Alethea Barbaro , Bjorn Birnir, Kirk Taylor (2006).

# Running the model

After installation of software and packages simply download the Julia file iGEMSchoolingModel.jl and parametersForModel.txt and put them in the same folder. Then open iGEMSchoolingModel.jl with your Julia editor and hit "run all". You can play around with the schooling model by changing parameters in parametersForModel without needing to touch the code itself. Depending on your choices with the parameters it will generate data for analysis and animations + a simple scatter animation 

# Extending the modeling code 
We have done our best to make the code easily extendable. To add a new model or parts of a model, we advise you to read which functions are already implemented. Then implement some new functions and call them from the most inner loop with an if statement. Then add the parameters required for these new functions to the parametersForModel.txt and import them as seen in the code.

# Data analysis 
As described the schooling model outputs a file called dataforAnalysis.CSV. The data contained in this file is the basis for training and testing our classifier. To run the code simply download iGEMDataAnalysis.jl and open it in your editor and hit run. It will output results into the terminal automatically. The file dataforAnalysis has each time series as a row, the first entry will be the class as defined in parametersforModel.txt. If you want to classify a set of data you need to run the model at least twice with two different classes, since as of now the analysis code only implements binary classification, two classes is the maximum. The target values should be c_1<=0.5 for one class and c_2>0.5 for the other.


# Blender: Vizualization
- Import of template model from .OBJ file
    - Create a blank canvas. First click "A" on your keyboard or select all entities in scene collection. When all are selected press the delete button or right click on a selected object and press the "delete" option in the righ-click menu.
    - To import our 3D model into blender, click "File" -> "Import" -> "Wavefront (.obj)"
    then select "SALMON.OBJ" which is located in the folder of this project. ![How to import .OBJ](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Blender_import_OBJ.png) ![Select .OBJ](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Blender_select_OBJ.png)
- Setting up our import script in the scripting menu and running it.
    - Open the scripting tab at the middle top of the window. 
    ![Select scripting tab](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Blender_select_scripting_tab.png)
    - Press "New" to start a new text block.
    - Open our provided "blenderScript.py" in a preferred text editor and copy the code into the text block you created in the previous step.
    - Before running the script, select the salmon model "SALMON" in the "Scene collection" frame at the top right of the window. Make sure that the line 
    ```python
    csv_loc='/home/User/iGEM2020_UiOslo/dataForVisualization.CSV' # Linux 
    ```
     or
    ```python
    csv_loc = r'C:\Users\<your user name>\iGEM2020_UiOslo_Norway\dataforVisualization.CSV' # Windows
    ``` 
    directs to the "dataforVisualization.CSV" that you generated by running iGEMSchoolingModel.jl.
    - Run the script by clicking the arrow at the top of the scripting window or press "ALT-P" on windows.
    ![Run script](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Blender_run_script.png)
- Playing the animation
    - Press the animation tab at the top of the window. When you are in the animation view, press space to start the animation. ![Run animation](https://github.com/iGEMOslo/iGEM2020_UiOslo_Norway/blob/master/Blender_run_animation.png)


Vizualization options
======
-   By default, blenderScript.py imports 10 objects from "dataForVisualization.CSV" to make it easier to run on low-powered computers.
iGEMSchoolingModel.jl by default outputs data for 100 objects. By changing the integer value of 
 
    ```python
    N_obj = 10 # Number of objects
    ```
    in blenderScript.py to
    ```python
    N_obj = 100 # Number of objects
    ```
    you can import all default created objects.
    


Authors
======
Jonas Grønbakken, Unviersity of Oslo 

- https://github.com/JonasGronbakken

- https://orcid.org/0000-0003-0549-0494

Martin Eide Lien, Norwegian University of Science and Technology
- https://github.com/meidelien

- https://orcid.org/0000-0003-3225-9175


