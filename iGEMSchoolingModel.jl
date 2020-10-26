
#using packages
using Random, Distributions
using DataFrames
using LinearAlgebra
using PyPlot
using PyCall
using CSV



#returns a named tuple of environment parameters
function environmentParameters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='
    Env_Para=(
    #dimensionless length of each side of cubic/square tank
    L=parse(Float32,getParaFromFile(file,"L",avoidStr,delimiter)),
    #Multiplies initial normal distribution of fish positions to spread them out
    R_Fish=parse(Float32,getParaFromFile(file,"R_Fish",avoidStr,delimiter)),
    # amplitude of velocity noise
    ampVNoise = parse(Float64,getParaFromFile(file,"ampVNoise",avoidStr,delimiter)),
    #amplitude of position noise
    ampPosNoise=parse(Float64,getParaFromFile(file,"ampPosNoise",avoidStr,delimiter)),
    )
    return Env_Para
end

#Returns a named tuple of simulation parameters
function simulationParameters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='

    Sim_Para=(
     #number of fishes
    N_Fish = parse(Int,getParaFromFile(file,"N_Fish",avoidStr,delimiter)),
    # number of dimensions
    dimension=parse(Int,getParaFromFile(file,"dimension",avoidStr,delimiter)),
    # time step
    dt = parse(Float64,getParaFromFile(file,"dt",avoidStr,delimiter)),
    # number of time steps
    N_steps=parse(Int,getParaFromFile(file,"N_steps",avoidStr,delimiter)),
    # number of simulation runs, can be used to average measurements
    N_runs=parse(Int,getParaFromFile(file,"N_runs",avoidStr,delimiter)),
    # number of times code is ran, this can be used to change variables for
    #each instance to generate statistic.
    N_instances=parse(Int,getParaFromFile(file,"N_instances",avoidStr,delimiter)),
    )
    return Sim_Para
end

#Returns a named tuple of fish parameters
function fishParameters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='

    Fish_Para=(
    # radius of attraction
    R_attraction = parse(Float32,getParaFromFile(file,"R_attraction",avoidStr,delimiter)),
    # radius of orientation
    R_orientation = parse(Float32,getParaFromFile(file,"R_orientation",avoidStr,delimiter)),
    # radius of repulsion
    R_repulsion = parse(Float32,getParaFromFile(file,"R_repulsion",avoidStr,delimiter)),
    # scalling for attraction
    attractWeight=parse(Float32,getParaFromFile(file,"attractWeight",avoidStr,delimiter)),
    # scalling for repulsion
    repulseWeight=parse(Float32,getParaFromFile(file,"repulseWeight",avoidStr,delimiter)),
    # force for current direction
    selfWeight=parse(Float32,getParaFromFile(file,"selfWeight",avoidStr,delimiter)),
    # scalling for orientation
    orientationWeight=parse(Float32,getParaFromFile(file,"orientationWeight",avoidStr,delimiter)),
    # fish lengths per second
    mean_v=parse(Float32,getParaFromFile(file,"mean_v",avoidStr,delimiter)),
    # max velocity 3 times mean_v
    max_v=parse(Float32,getParaFromFile(file,"max_v",avoidStr,delimiter)),
    # variance in velocity
    var_v=parse(Float32,getParaFromFile(file,"var_v",avoidStr,delimiter)),
    )
    return Fish_Para
end

#Returns a named tuple of sick paramters
function sickParameters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='


    Sick_Para=(
    # selfweights are different for certain individuals (sick ones)
    selfWeightOffIndivually=parse(Bool,getParaFromFile(file,"selfWeightOffIndivually",avoidStr,delimiter)),
    # the number of fishes for which selfweight is ofset
    N_selfweightOff=parse(Int,getParaFromFile(file,"N_selfweightOff",avoidStr,delimiter)),
    # amplitude that the self weight is multiplied by
    selfOffAm=parse(Float32,getParaFromFile(file,"selfOffAm",avoidStr,delimiter)),
    )
    return Sick_Para
end

#Returns named tuple of visualisation paramters
function visualParamters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='

    Vizual_Para=(
    #the number of frames for blender and scatter animation that will be saved
    #number of frames needs to be even
    N_frames=parse(Int,getParaFromFile(file,"N_frames",avoidStr,delimiter)),
    #saves N_frames positions in dataForVisualization, only saves first run
    save_pos=parse(Bool,getParaFromFile(file,"save_pos",avoidStr,delimiter)),
    # create an scatter animation
    scatter_anim=parse(Bool,getParaFromFile(file,"scatter_anim",avoidStr,delimiter)),
    )
    return Vizual_Para
end
#Returns name tuple of data analysis parameters
function dataAnalysisParameters()
    file = open("parametersForModel.txt")
    avoidStr="#"
    delimiter='='

    DataAnalaysis_Para=(
    # number of measurements
    N_measurements= parse(Int,getParaFromFile(file,"N_measurements",avoidStr,delimiter)),

    # if this is set to true then for each instance a measure will be appended
    #to CSV dataforAanalysis where the first entry is class
    appendToDataForAnalysis=parse(Bool,getParaFromFile(file,"appendToDataForAnalysis",avoidStr,delimiter)),
    # set your target value or class here, it will be assigned to all
    # saved data for analysis
    class=parse(Int,getParaFromFile(file,"class",avoidStr,delimiter)),

    # Start measuring at this percentage of N_steps
    measure_Start=parse(Float32,getParaFromFile(file,"measure_Start",avoidStr,delimiter)),

    # Stop measuring at this percentage of N_steps
    measure_Stop=parse(Float32,getParaFromFile(file,"measure_Stop",avoidStr,delimiter)),


    # different measurements only use one at a time

    # uses a measure that gives the average position of each time step, then
    #takes the sum of those positions and all their dimensions over all time
    #and returns that value
    avgPositionDimensionSum=parse(Bool,getParaFromFile(file,"avgPositionDimensionSum",avoidStr,delimiter)),
    # uses measure that takes the average position
    avgPosition=parse(Bool,getParaFromFile(file,"avgPosition",avoidStr,delimiter)),

    )
end

#=
Gets line in the file that contains wantedStr but not avoidStr
Input:
1. file, a file
2. wantedStr,  string
3. wantedStr, string
Output:
1. l, string
=#
function getLineInFile(file,wantedStr,avoidStr)
    for l in eachline(file)
        if !occursin(avoidStr,l)
            if occursin(wantedStr,l)
                return l
            end
        end
    end
    return "None"
end

#=
get string after expression +1, so [12=5] returns 5 if expression='='
Input:
1. Str, string
2. expression, char
Output:
1. string
=#
function getStringAfterExpression(Str,expression)
    ind_break=findfirst(isequal(expression),Str)
    return Str[ind_break+1:end]
end

#=
get parameter from file using getLineInFile and GetStringAfterExpression.
This parameter is the string on the line that contains wantedStr but not
avoidStr after the delimiter
Input:
1. file, a file
2. wantedStr, string
3. avoidStr, string
4. delimiter, char
Output:
1. String
=#
function getParaFromFile(file,wantedStr,avoidStr,delimiter)
    line = getLineInFile(file,wantedStr,avoidStr)
    return getStringAfterExpression(line,delimiter)
end


#=
Add the absolute value of all positional componenets togheter
Input:
1. vecOfPos, Multidimensional array
Output:
1. val, Float64
=#
function avgPositionDimSum(vecOfPos)
    val=0  #temporary value
    #for all entries in vecOfPos add up the sum of all elements in that matrix
    for i in 1:size(vecOfPos)[1]
        val=val+sum(abs.(vecOfPos[i]))
    end
    return val
end


#=
Finds fishes whos distance is between minDist and maxDist from fish j
where fish j's position is P[j,:]
Input:
1. minDist, Float64
2. maxDist, Float 64
3. P, Multidimensional array, position of fishes
4. j, Integer, which fish we are looking at
Output:
1. inZone, array of Integers
=#
function indexInZone(minDist,maxDist,P,j)
        #calculate distance to all fishes
        dist=sqrt.(sum((P.-transpose(P[j,:])).^2,dims=2))
        #return index for those fishes whose distance is whitin the interval
        inZone=[i for (i,x) in enumerate(dist) if minDist<x<maxDist]
        return inZone
end

#=
Returns the attraction direction, a vector pointing towards a the set of fishes
which the selected fish is attracted to
Input:
1. P, Multidimensional array, position of fishes
2. j, Integer, which fish we are looking at
3. inAttZone, array of integers, indicies of fishes in attraction zone
4. attWeight, float
5. Sim_Para, named tuple of simulation parameters
Output:
1. attDir, array of float, attraction direction
=#
function attractDir(P,j,inAttZone,attWeight,Sim_Para)
    #initialization
    attDir=zeros(Sim_Para[:dimension],1)

    #greate vector towards the average position of fishes in attraction zone
    a_v=sum(P[vec(inAttZone),:],dims=1)./size(inAttZone)[1]-transpose(P[j,:])

    #check for 0
    if sum(a_v.^2)>0
        #normalize and scale vector
        attDir=transpose(attWeight*normalize(a_v))
    end


    return attDir

end
#=
Return weighted vector which represents repulsion, pointing away from the fishes
in the repulsive zone
Input:
1. P, Multidimensional array, position of fishes
2. j, Integer, which fish we are looking at
3. inRepZone, array of integers, indicies of fishes in repulsion zone
4. repWeight, float
5. Sim_Para, named tuple of simulation parameters
Output:
1. repDir, array of float, repulsion direction
=#
function repulsDir(P,j,inRepZone,repWeight,Sim_Para)
    #initialization
    repulsDir=zeros(Sim_Para[:dimension],1)
    #create vector
    r_v=transpose(P[j,:])-sum(P[vec(inRepZone),:],dims=1)
    #check for 0
    if sum(r_v.^2)>0
        #normalize, scale and transpose vector
        repulsDir=transpose(repWeight*normalize(r_v))
    end

    return repulsDir

end


#=
Returns weighted vector pointing in direction of orientation, the average
direction that those in orientation zone is moving towards
Input:
1. V, Multidimensional array, velocity of fishes
2. j, Integer, which fish we are looking at
3. inOriZone, array of integers, indicies of fishes in orientation zone
4. oriWeight, float
5. abs_v, float, absolute velocity
6. Sim_Para, named tuple of simulation parameters
Output:
1. oriDir, array of float, orientation direction
=#
function orientDir(V,j,inOriZone,oriWeight,abs_v,Sim_Para)
    #initialization
    oriDir=zeros(Sim_Para[:dimension],1)
    #add directions of fish in orientation zone
    V_temp=0*V
    for i in size(V)[1]
        V_temp[i,:]=normalize(V[1,:])
    end
    o_v=sum(V_temp[vec(inOriZone),:],dims=1)
    #check length greater than 0
    if sum(o_v.^2)>0
        #normalize, scale and tranpose
        oriDir=oriWeight*transpose(normalize(o_v))
    end

    return oriDir
end

#=
#Return a matrix wich can be added to the current velocity matrix as noise
Input:
1. Env_Para, named tuple, environment parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. vNoise, multidimensional array
=#
function velocityNoise(Env_Para,Sim_Para)
    vNoise=Env_Para[:ampVNoise]*rand(Normal(0,1),Sim_Para[:N_Fish],
           Sim_Para[:dimension])
    return vNoise
end

#=
Return a matrix wich can be added to the current position matrix as noise
Input:
1. Env_Para, named tuple, environment parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. posNoise, multidimensional array
=#
function positionNoise(Env_Para,Sim_Para)
    posNoise=Env_Para[:ampPosNoise]*rand(Normal(0,1),Sim_Para[:N_Fish],
             Sim_Para[:dimension])
    return posNoise
end

#=
Return a matrix which represents initial velocities, where each fish has
velocity V[j,:]
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. V, multidimensional array of floats
=#
function initVelocity(Fish_Para,Sim_Para)
    speed=Fish_Para[:mean_v]*rand(Sim_Para[:N_Fish],1)
    V=speed.*(rand(Sim_Para[:N_Fish],Sim_Para[:dimension]).-0.5)
    return V
end

#=
Return a matrix of initial positions where each fish has a position P[j,:]
there fish are normally distributed around the center of the tank
Input:
1. Env_Para, named tuple, environment parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. P, multidimensional array of floats
=#
function initPosition(Env_Para,Sim_Para)
    P=(Env_Para[:R_Fish])*rand(Normal(0,1),Sim_Para[:N_Fish],Sim_Para[:dimension])
    return P
end

#=
Return vector contaning initial self weights for all fish
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. selfW, array of floats
=#
function initSelfWeight(Fish_Para,Sim_Para)
    selfW=Fish_Para[:selfWeight]*ones(Sim_Para[:N_Fish],1)
    return selfW
end

#=
Return vector contaning initial repulsion weights
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. repWeight, array of floats
=#
function initRepWeight(Fish_Para,Sim_Para)
    repWeight=Fish_Para[:repulseWeight]*ones(Sim_Para[:N_Fish],1)
    return repWeight
end

#=
Return vector contaning initial orientation weights
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. oriWeight, array of floats
=#
function initOriWeight(Fish_Para,Sim_Para)
    oriWeight=Fish_Para[:orientationWeight]*ones(Sim_Para[:N_Fish],1)
    return oriWeight
end


#=
Return vector contaning initial attraction weights
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
Output:
1. attWeight, array of floats
=#
function initAttWeight(Fish_Para,Sim_Para)
    attWeight=Fish_Para[:attractWeight]*ones(Sim_Para[:N_Fish],1)
    return attWeight
end

#=
Return matrix with all velocities after keeping them within limits
Input:
1. Fish_Para, named tuple, fish parameters
2. Sim_Par, named tuple, simulation paramaters
3. V, multidimensional array of floats, representing velocities
Output:
1. V, multidimensional array of floats, representing velocities
=#
function velAdjustedForLimit(Fish_Para,Sim_Para,V)
    #Gives a boolean vector for velocities in V whose norm is greater than
    #the limit
    V_over=sqrt.(sum(V.^2,dims=2)) .> Fish_Para[:max_v]

    #Initialization of matrix to store normalized velocity vectors whose
    #magnitude needs to be reduced
    norm_V=zeros(sum(V_over),Sim_Para[:dimension])
    #check if there are any velocities over the limit
    if sum(V_over)>0
        #loop for each vector that is over the limit
        for k in 1:sum(V_over)
            #Holds the vectors that are over the limit
            Vk=V[vec(V_over),:]
            #if there is more than one vector then only read one vector at
            #a time
            if size(Vk)[1]>1
                Vk=Vk[k,:]
            end
            #normalize vector and put it in norm_V
            norm_V[k,:]=normalize(Vk)

        end
        #Change the velocities that where over the limit to be max velocities
        V[vec(V_over),:]=Fish_Para[:mean_v]*norm_V
    end

    return V
end

#=
Return position matrix and velocity matrix of all fish after making sure
that they are within boundry
Input:
1. Env_Para, named tuple, environment parameters
2. P, multidimensional array of floats, representing positions
3. V, multidimensional array of floats, representing velocities
Output:
1. P,V multidimensional array of floats, representing positions and
       velocities
=#
function keepWithinBoundry(Env_Para,P,V)
    #check if fishes are outside of boundry for any dimension
    #returns logical matrix N_Fish x dimension
    P_under= P .< -Env_Para[:L]/2
    P_over = P .> Env_Para[:L]/2
    #change positions to be on boundry
    P[vec(P_under)] .= -Env_Para[:L]/2
    P[vec(P_over)] .=Env_Para[:L]/2
    #Gend indicies of those fish that crossed the boundry
    ind=P_under+P_over
    ind=sum(ind,dims=2)
    ind=ind.>0
    #make the fish that crossed boundry turn 180 degrees for all
    #dimensions
    V[vec(ind),:] =-V[vec(ind),:]

    return P,V
end

#=
Given a vector where each entry is a matrix representing positions create a
animation in mp4 format and save that animation, each frame is a set of points
defined by the matrices
Input:
1. Env_Para, named tuple, environment parameters
2. Data, vector where each entry is a multidimensional array of floats
3. Vizual_Para, named tuple, visualization parameters
Output:
none, saves an .mp4 file
=#
function animScatterFromVec(Env_Para,Data,Vizual_Para)
    anim=pyimport("matplotlib.animation")
    #function animation for updates
    function animUpdate(i)
        clf() #clear figure
        #create axis
        ax = plt.axes(xlim = (-Env_Para[:L]/2,Env_Para[:L]/2),ylim=(
            -Env_Para[:L]/2,Env_Para[:L]/2))
        #return new scatter plot
        return plt.scatter(Data[i+1][:,1], Data[i+1][:,2])
    end

    #Construct Figure and Plot Data
    fig = plt.figure(figsize=(5,5))
    #set axis
    ax = plt.axes(xlim = (-Env_Para[:L]/2,Env_Para[:L]/2),ylim=(
        -Env_Para[:L]/2,Env_Para[:L]/2))
    #scatter plot
    scat= plt.scatter(Data[1][:,1], Data[1][:,2])
    #create function animation object
    myanim = anim.FuncAnimation(fig, animUpdate, frames=Vizual_Para[:N_frames], interval=100)
    #save animation where code is located
    myanim[:save]("test1.mp4", bitrate=-1, extra_args=["-vcodec", "libx264",
                  "-pix_fmt", "yuv420p"])

end

#=
Updates the direction of fish j according to the simple model
Input:
1. V, multidimensional array of floats, representing velocities
2. Fish_Para, named tuple, fish parameters
3. P, multidimensional array of floats, representing positions
4. j, integer
5. Sim_Para, named tuple, simulation parameters
6. selfW, array of floats, self weight
7. repWeight, array of floats, repulsion weight
8. oriWeight, array of floats, orientation weight
9. attWeight, array of floats, attraction weight
Output:
1. V, multidimensional array of floats, representing velocities
=#
function updateDirSumAll(V,Fish_Para,P,j,Sim_Para,selfW,repWeight,oriWeight,
                         attWeight)
    #magnitude of current velocity
    abs_v=norm(V[j,:])

    if abs_v>0

        #find index for fishes in repulsion zone
        inRepZone=indexInZone(0,Fish_Para[:R_repulsion],P,j)
        #find index for fishes in orientation zone
        inOriZone=indexInZone(Fish_Para[:R_repulsion],Fish_Para[:R_orientation],P,j)
        #find index for fishes in attraction zone
        inAttZone=indexInZone(Fish_Para[:R_orientation],Fish_Para[:R_attraction],P,j)

        #initialization of new direction vector
        new_dir=zeros(Sim_Para[:dimension],1)
        #if there are fishes in repulsion zone
        if size(inRepZone)[1]>0
            #calculate new direction away from fishes in repulsion zone
            new_dir=new_dir+repulsDir(P,j,inRepZone,repWeight[j],Sim_Para)
        end
        #if there are fishes in orientation zone
        if size(inOriZone)[1]>0
            #calculate new direction to orient with fishes in orientation zone
            new_dir=new_dir+orientDir(P,j,inOriZone, oriWeight[j],abs_v,Sim_Para)
        end
        #if there are fishes in attraction zone
        if size(inAttZone)[1]>0
            #calculate new direction towards fishes in attraction zone
            new_dir=new_dir+attractDir(P,j,inAttZone, attWeight[j],Sim_Para)
        end

        #if new dir is not empty
        if size(new_dir)[1]>0
            #change velocity to have same magnitude but new direction
            V[j,:]=abs_v*normalize(selfW[j]*V[j,:]/abs_v+new_dir)
        end

    end

    return V[j,:]

end
#=
Change the self weight of N_selfweightOff individuals by an amplitude
selfOffAm times a random number, returns vector of self weights
Input:
1. Sick_Para, named tuple, sickness parameters
2. selfW, array of floats, self weight
3. Sim_Para, named tuple, simulation parameters
Output:
1. selfW, array of floats, self weight
=#
function selfWeightShiftSome(Sick_Para,selfW,Sim_Para)
    #find random individuals
    ind=randperm(Sim_Para[:N_Fish])[1:Sick_Para[:N_selfweightOff]]
    #change weight of those individuals by multiplication
    selfW[ind]=rand(Sick_Para[:N_selfweightOff],1)*Sick_Para[:selfOffAm].*selfW[ind]
    return selfW
end

#=
Saves position data in csv file
Input:
1. time_stamps, array of floats
2. P, multidimensional array of floats, representing positions
3. Vizual_Para, named tuple, visualization parameters
4. Sim_Para, named tuple, simulation parameters
5. Env_Para, named tuple, environment parameters
Output:
none, saves a csv
=#
function generateCSVFromData(time_stamps,P,Vizual_Para,Sim_Para,Env_Para)
    #initialize matrix that will hold all data, each row's first entry is a
    #time stamp followed by positions [x,y,z] or [x,y] for each fish
    M=zeros(Vizual_Para[:N_frames],1+Sim_Para[:dimension]*Sim_Para[:N_Fish])
    #put time stamps in first column
    M[:,1]=time_stamps
    #M[:,1]=ones(Vizual_Para[:N_frames],1)
    #for number of frames
    for i in 1:Vizual_Para[:N_frames]
        #reshape position matrix s.t that the matrix is on the form specified
        P_reshaped=reshape(transpose(P[i]),1,length(P[i]))
        #add positions to M
        M[i,2:(1+Sim_Para[:dimension]*Sim_Para[:N_Fish])]=P_reshaped
    end
    #create csv that contains M
    CSV.write("dataForVisualization.CSV",  DataFrame(M), writeheader=false)
end

#=
Appends a vector as a row to a csv where first entry is class and the rest
features
Input:
1. vec, array of floats
2. DataAanalysis_Para, named tuple, data analysis parameters
Output:
none, saves to a csv
=#
function appendVectorToCsv(vec,DataAnalysis_Para)
    #temporary vector
    temp_vec=[]
    count=0
    for entry in transpose(vec)
        append!(temp_vec,entry[1])
        if length(entry)>1
            append!(temp_vec,entry[2])
            count+=1
        end
        if length(entry)>2
            append!(temp_vec,entry[3])
            count+=1
        end
        count+=1
    end
    #initialize vector
    data=zeros(length(temp_vec)+1,1)
    #set class as first entry
    data[1]=DataAnalysis_Para[:class]
    #put vector in data
    for i in 1:count
        data[i+1]=temp_vec[i]
    end
    #transpose
    data=transpose(data)
    #append vector to CSV file
    CSV.write("dataforAnalysis.CSV", DataFrame(data), header = false, append = true)
end
#=
Returns the average position as an array [x,y] or [x,y,z] depending on
dimension
Input:
1. Pos, multidimensional array of floats
Output:
1. avgP, array of floats
=#
function avgPos(Pos)
    #calculate average position
    avgP=sum(Pos,dims=1)/size(Pos)[1]
    return avgP
end

#=
Returns an array of indicies that we want sample when we want N_samples
samples from a set with N_set entries between measure_Start*N_set and
measure_Stop*N_set.
Input:
1. N_set, Integer
2. N_samples, Integer
3. measure_Start, Float
4. measure_Stop, Float
Output:
1. ind, array of integers
=#
function getIndicesToSample(N_set,N_samples,measure_Start,measure_Stop)
    #initialization
    ind=[]
    for i in 1:N_set
        #interval
        interval=measure_Stop-measure_Start
        #next index we want to sample
        next_ind=Int(ceil(measure_Start+i*((N_set*interval)/N_samples)))
        #if that in index is in the set then append to array
        if next_ind<=Int(ceil(measure_Stop*N_set))
            append!(ind,next_ind)
        end
    end
    return ind
end



#Main
let
    #enviorment Parameters
    Env_Para=environmentParameters()

    #Simulation parameters
    Sim_Para=simulationParameters()

    #Fish parameters
    Fish_Para=fishParameters()

    #parameters for sickness, defines how sickness affects fish
    Sick_Para=sickParameters()

    #Parameters for ploting and animation
    Vizual_Para=visualParamters()

    #Parameters for data analysis
    DataAnalysis_Para=dataAnalysisParameters()


    #vector to store position data for visualisation
    Posdata_anim=Vector(undef,Vizual_Para[:N_frames])
    #vector to store time stamps
    time_stamps=Vector(undef,Vizual_Para[:N_frames])
    #vector for ploting data gathered on each instance
    Plot_data=Vector(undef,Sim_Para[:N_instances])

    #Run simulation with different instance of parameters
    for _inst_ in 1:Sim_Para[:N_instances]
        #marix of initial poisitions
        P_init=initPosition(Env_Para,Sim_Para)
        P=P_init
        #matrix of initial velocities
        V_init=initVelocity(Fish_Para,Sim_Para)
        V=V_init

        #vector of initial self weight
        selfW=initSelfWeight(Fish_Para,Sim_Para)
        #vector of repulsion weights
        repWeight=initRepWeight(Fish_Para,Sim_Para)
        #vector of orientation weights
        oriWeight=initOriWeight(Fish_Para,Sim_Para)
        #vector of attraction weights
        attWeight=initAttWeight(Fish_Para,Sim_Para)
        #change self weight of some individuals if set true
        if Sick_Para[:selfWeightOffIndivually]
            selfW=selfWeightShiftSome(Sick_Para,selfW,Sim_Para)
        end
        #variable to hold avgPos measure
        avgPosData=zeros(1,Sim_Para[:dimension])
        #variable to hold avgPositionDimSum measure
        avgPosDimSumData=0

        vecForDatanalysis=Vector(undef,DataAnalysis_Para[:N_measurements])
        #Run simulation N_runs number of times to generate averages
        for run_k in 1:Sim_Para[:N_runs]
            #reinitialize positions
            P=P_init
            #reinitialize velocities
            V=V_init

            #sample indicies for visualisation
            vis_indicies=getIndicesToSample(Sim_Para[:N_steps],Vizual_Para[:N_frames],0,1)
            #counter to know which index of vis_indicies that we are looking for
            count_vis_ind=1
            #sample indicies for datanalysis
            ana_indicies=getIndicesToSample(Sim_Para[:N_steps],
                DataAnalysis_Para[:N_measurements],
                DataAnalysis_Para[:measure_Start],
                DataAnalysis_Para[:measure_Stop])
            #counter to know which index of ana_indicies that we are looking for
            count_ana_ind=1


            #Run main code N_steps times
            for i in 1:Sim_Para[:N_steps]
                #add velocity noise
                V=V+velocityNoise(Env_Para,Sim_Para)
                #add position noise
                P=P+positionNoise(Env_Para,Sim_Para)
                #keep velocity under maximum
                V=velAdjustedForLimit(Fish_Para,Sim_Para,V)

                #for each fish
                #this loop is multi threaded, be carefull when implementing new
                #functions or models, there is always the danger of a data race
                #if you want to remove the multi threading simply remove
                # "Threads.@threads"
                Threads.@threads for j in 1:Sim_Para[:N_Fish]
                    #update direction
                    V[j,:]=updateDirSumAll(V,Fish_Para,P,j,Sim_Para,selfW,repWeight,oriWeight,attWeight)

                end

                #Keep fishes within boundry
                P,V=keepWithinBoundry(Env_Para,P,V)

                P=P+Sim_Para[:dt]*V #update position


                #If we are the right iteration calculate and save
                #visualization data
                if count_vis_ind<=Vizual_Para[:N_frames]
                    if Int(vis_indicies[count_vis_ind])==Int(i)
                        #save for first run
                        if run_k==1
                            time_stamps[count_vis_ind]=Sim_Para[:dt]*i
                            Posdata_anim[count_vis_ind]=P
                        end
                        count_vis_ind+=1
                    end
                end


                #If we are the right iteration calculate and save measures
                if count_ana_ind<=DataAnalysis_Para[:N_measurements]
                    if Int(ana_indicies[count_ana_ind])==Int(i)
                        #if we use measure avgPositionDimSum
                        if DataAnalysis_Para[:avgPositionDimensionSum]
                            avgPosDimSumData=avgPosDimSumData+avgPositionDimSum(P)
                            vecForDatanalysis[count_ana_ind]=avgPosDimSumData
                        end
                        #if we use measure avgPosition
                        if DataAnalysis_Para[:avgPosition]
                            avgPosData=avgPosData+avgPos(P)
                            #append measure to vec for analysis
                            vecForDatanalysis[count_ana_ind]=avgPosData
                        end
                        count_ana_ind+=1
                    end

                end


            end
            #Saves time stamps and posdata_anim to a csv
            if (run_k==1) & (_inst_==1)
                if Vizual_Para[:save_pos]
                    generateCSVFromData(time_stamps,Posdata_anim,Vizual_Para,Sim_Para,Env_Para)
                end
            end

        end
        #Appends vecForDatanalysis to csv
        if DataAnalysis_Para[:appendToDataForAnalysis]
            appendVectorToCsv(vecForDatanalysis,DataAnalysis_Para)
        end


    end


    if Vizual_Para[:scatter_anim]
        #Creates an animation and saves it
        animScatterFromVec(Env_Para,Posdata_anim,Vizual_Para)
    end

end
