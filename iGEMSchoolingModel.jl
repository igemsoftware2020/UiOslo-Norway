
#Import packages

#Pkg.add("Distributions")
#Pkg.add("Plots")
#Pkg.add("Printf")
#Pkg.add("LinearAlgebra")
#Pkg.add("PyPlot")
#Pkg.add("PyCall")
#Pkg.add("DataFrames")
#Pkg.add("CSV")
#using packages
using Random, Distributions
using DataFrames
using LinearAlgebra
using PyPlot
using PyCall
using CSV
@pyimport matplotlib.animation as anim

#all units are fish length
#returns a named touple of environment parameters
function environmentParameters()
    Env_Para=(
    L=1000,  #length of each side of cubic tank
    R_Fish=100, #Multiplies initial normal distribution of fish positions to
    #spread them out
    ampVNoise = 0.3, # amplitude of velocity noise
    ampPosNoise=1, #amplitude of position noise
    )
    return Env_Para
end

#returns a named touple of simulation parameters
function simulationParameters()
    Sim_Para=(
    N_Fish = 100, #number of fishes
    dimension=2, #number of dimensions
    dt = 0.25, # time step
    N_steps=1000, #number of time steps
    N_runs=1, #number of simulation runs, can be used to average measurements
    #number of times code is ran, this can be used to change variables for
    #each instance to generate statistic.
    N_instances=100
    )
    return Sim_Para
end

#returns a named touple of fish parameters
function fishParameters()
    Fish_Para=(
    R_attraction = 5*100, #radius of attraction
    R_orientation = 5*20, #radius of orientation
    R_repulsion = 5*5, # radius of repulsion
    attractWeight=1.4, #scalling for attraction
    repulseWeight=0.7, #scalling for repulsion
    selfWeight=1, # force for current direction
    orientationWeight=2, #scalling for orientation
    mean_v=1, # fish lengths per second
    max_v=3, # max velocity 3 times mean_v
    var_v=1, # variance in velocity
    )
    return Fish_Para
end

#returns a named touple of sick paramters
function sickParameters()
    Sick_Para=(
    #selfweights are different for certain individuals (sick ones)
    selfWeightOffIndivually=false,
    N_selfweightOff=100, #the number of fishes for which selfweight is ofset
    selfOffAm=10, #amplitude that the self weight is multiplied by
    )
    return Sick_Para
end

#returns named touple of visualisation paramters
function visualParamters()
    Vizual_Para=(
    #the number of frames for blender and scatter animation that will be saved
    N_frames=100,  #number of frames needs to be even
    #saves N_frames positions in dataForVisualization, only saves first run
    save_pos=true,
    # create an scatter animation
    scatter_anim=false,
    )
    return Vizual_Para
end
#returns name touple of data analysis parameters
function dataAnalysisParameters()
    DataAnalaysis_Para=(
    N_measurements= 100, #number of measurements

    #if this is set to true then for each instance a measure will be appended
    #to CSV dataforAanalysis where the first entry is class
    appendToDataForAnalysis=true,
    #set your target value or class here, it will be assigned to all
    #saved data for analysis
    class=0,

    #different measurements only use one at a time

    #uses a measure that gives the average position of each time step, then
    #takes the sum of those positions and all their dimensions over all time
    #and returns that value
    avgPositionDimensionSum=false,
    #uses measure that takes the average position
    avgPosition=true,
    )
end
#returns a singel scalar
function avgPositionDimSum(vecOfPos)
    val=0  #temporary value
    #for all entries in vecOfPos add up the sum of all elements in that matrix
    for i in 1:size(vecOfPos)[1]
        val=val+sum(abs.(vecOfPos[i]))
    end
    return val
end

#returns vector contaning a indexes of fishes between min and max distance
function indexInZone(minDist,maxDist,P,j)
        #calculate distance to all fishes
        dist=sqrt.(sum((P.-transpose(P[j,:])).^2,dims=2))
        #return index for those fishes whose distance is whitin the interval
        inZone=[i for (i,x) in enumerate(dist) if minDist<x<maxDist]
        return inZone
end

#Returns the attraction direction, a vector pointing towards a the set of fishes
#which the selected fish is attracted to
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

#return vector which represents repulsion, pointing away from the fishes in the
#repulsive zone
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

#returns vector pointing in direction of orientation, the average between
#self direction and the direction that those in orientation zone is moving
#towards
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

#Return a matrix wich can be added to the current velocity matrix as noise
function velocityNoise(Env_Para,Sim_Para)
    vNoise=Env_Para[:ampVNoise]*rand(Normal(0,1),Sim_Para[:N_Fish],Sim_Para[:dimension])
    return vNoise
end

#Return a matrix wich can be added to the current position matrix as noise
function positionNoise(Env_Para,Sim_Para)
    posNoise=Env_Para[:ampPosNoise]*rand(Normal(0,1),Sim_Para[:N_Fish],Sim_Para[:dimension])
    return posNoise
end

#return a matrix which represents initial velocities, where each fish has
#velocity V[j,:]
function initVelocity(Fish_Para,Sim_Para)
    #speed=rand(Normal(Fish_Para[:mean_v], Fish_Para[:var_v]), Sim_Para[:N_Fish],1)
    #speed=Fish_Para[:max_v]*rand(Sim_Para[:N_Fish],1)
    speed=5
    #V=speed.*rand(Normal(0,1), Sim_Para[:N_Fish],Sim_Para[:dimension])
    V=speed.*(rand(Sim_Para[:N_Fish],Sim_Para[:dimension]).-0.5)
    return V
end

#return a matrix of initial positions where each fish has a position P[j,:]
function initPosition(Env_Para,Sim_Para)
    P=(Env_Para[:R_Fish])*rand(Normal(0,1),Sim_Para[:N_Fish],Sim_Para[:dimension])
    return P
end

#return vector contaning initial self weights for all fish
function initSelfWeight(Fish_Para,Sim_Para)
    selfW=Fish_Para[:selfWeight]*ones(Sim_Para[:N_Fish],1)
    return selfW
end

#return vector contaning initial repulsion weights
function initRepWeight(Fish_Para,Sim_Para)
    repWeight=Fish_Para[:repulseWeight]*ones(Sim_Para[:N_Fish],1)
    return repWeight
end

#return vector contaning initial orientation weights
function initOriWeight(Fish_Para,Sim_Para)
    oriWeight=Fish_Para[:orientationWeight]*ones(Sim_Para[:N_Fish],1)
    return oriWeight
end

#return vector contaning initial attraction weights
function initAttWeight(Fish_Para,Sim_Para)
    attWeight=Fish_Para[:attractWeight]*ones(Sim_Para[:N_Fish],1)
    return attWeight
end

#return matrix with all velocities after keeping them within limits
function velAdjustedForLimit(Fish_Para,Sim_Para,V)
    #gives a boolean vector for velocities in V whose norm is greater than
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
        V[vec(V_over),:]=Fish_Para[:max_v]*norm_V
    end

    return V
end

#return position matrix and velocity matrix of all fish after making sure
#that they are within boundry
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

#given a vector wher each entry is a matrix create a animation in mp4 format
#and save that animation, each frame is a set of points defined by the matrices
function animScatterFromVec(Env_Para,Data,Vizual_Para)

    #function animation for updates
    function animUpdate(i)
        clf() #clear figure
        #create axis
        ax = plt.axes(xlim = (-Env_Para[:L]/2,Env_Para[:L]/2),ylim=(-Env_Para[:L]/2,Env_Para[:L]/2))
        #return new scatter plot
        return plt.scatter(Data[i+1][:,1], Data[i+1][:,2])
    end

    #Construct Figure and Plot Data
    fig = plt.figure(figsize=(5,5))
    #set axis
    ax = plt.axes(xlim = (-Env_Para[:L]/2,Env_Para[:L]/2),ylim=(-Env_Para[:L]/2,Env_Para[:L]/2))
    #scatter plot
    scat= plt.scatter(Data[1][:,1], Data[1][:,2])
    #create function animation object
    myanim = anim.FuncAnimation(fig, animUpdate, frames=100, interval=100)
    #save animation where code is located
    myanim[:save]("test1.mp4", bitrate=-1, extra_args=["-vcodec", "libx264", "-pix_fmt", "yuv420p"])

end

#Returns the velocity matrix, udating it taking the sum over all fish in each
#zone
function updateDirSumAll(V,Fish_Para,P,j,Sim_Para,selfW,repWeight,oriWeight,attWeight)
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

    return V

end
#change the self weight of N_selfweightOff individuals by an amplitude
#selfOffAm times a random number, returns vector of self weights
function selfWeightShiftSome(Sick_Para,selfW,Sim_Para)
    #find random individuals
    ind=randperm(Sim_Para[:N_Fish])[1:Sick_Para[:N_selfweightOff]]
    #change weight of those individuals by multiplication
    selfW[ind]=rand(Sick_Para[:N_selfweightOff],1)*Sick_Para[:selfOffAm].*selfW[ind]
    return selfW
end

#sightly change self weight of all individuals
function ShiftSelfWeightAll(Sick_Para,selfW,Sim_Para)
end

#saves position data in csv file
function generateCSVFromData(time_stamps,P,Vizual_Para,Sim_Para,Env_Para)
    #initialize matrix that will hold all data, each row's first entry is a
    #time stamp followed by positions [x,y,z] or [x,y] for each fish
    M=zeros(Vizual_Para[:N_frames],1+Sim_Para[:dimension]*Sim_Para[:N_Fish])
    #put time stamps in first column
    #M[:,1]=time_stamps
    M[:,1]=ones(Vizual_Para[:N_frames],1)
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

#appends a vector as a row to a csv where first entry is class and the rest
#features
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
    CSV.write("dataforAanalysis.CSV", DataFrame(data), header = false, append = true)
end

#returns the average position as an array [x,y] or [x,y,z] depending on
#dimension
function avgPos(Pos)
    #calculate average position
    avgP=sum(Pos,dims=1)/size(Pos)[1]
    return avgP
end

#returns an array of indicies that we want samples when we want N_samples
#samples from a set with N_set entries
function getIndicesToSample(N_set,N_samples)
    #initialization
    ind=[]
    for i in 1:N_set
        #next index we want to sample
        next_ind=Int(ceil(i*(N_set/N_samples)))
        #if that in index is in the set then append to array
        if next_ind<=N_set
            append!(ind,next_ind)
        end
    end
    return ind
end

#main
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

    #run simulation with different instance of parameters
    for _inst_ in 1:Sim_Para[:N_instances]
        #marix of initial poisitions
        P=initPosition(Env_Para,Sim_Para)
        #matrix of initial velocities
        V=initVelocity(Fish_Para,Sim_Para)

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

        vecForDatanalysis=Vector(undef,Vizual_Para[:N_frames])
        #run simulation N_runs number of times to generate averages
        for run_k in 1:Sim_Para[:N_runs]

            #sample indicies for visualisation
            vis_indicies=getIndicesToSample(Sim_Para[:N_steps],Vizual_Para[:N_frames])
            #counter to know which index of vis_indicies that we are looking for
            count_vis_ind=1
            #sample indicies for datanalysis
            ana_indicies=getIndicesToSample(Sim_Para[:N_steps],DataAnalysis_Para[:N_measurements])
            #counter to know which index of ana_indicies that we are looking for
            count_ana_ind=1


            #run main code N_steps times
            for i in 1:Sim_Para[:N_steps]
                #add velocity noise
                V=V+velocityNoise(Env_Para,Sim_Para)
                #add position noise
                P=P+positionNoise(Env_Para,Sim_Para)
                #keep velocity under maximum
                V=velAdjustedForLimit(Fish_Para,Sim_Para,V)

                #for each fish
                for j in 1:Sim_Para[:N_Fish]
                    #update direction
                    V=updateDirSumAll(V,Fish_Para,P,j,Sim_Para,selfW,repWeight,oriWeight,attWeight)

                end

                #Keep fishes within boundry
                P,V=keepWithinBoundry(Env_Para,P,V)

                P=P+Sim_Para[:dt]*V #update position


                #if we are the right iteration calculate and save
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
            #saves time stamps and posdata_anim to a csv
            if (run_k==1) & (_inst_==1)
                if Vizual_Para[:save_pos]
                    generateCSVFromData(time_stamps,Posdata_anim,Vizual_Para,Sim_Para,Env_Para)
                end
            end

        end
        #appends vecForDatanalysis to csv
        if DataAnalysis_Para[:appendToDataForAnalysis]
            appendVectorToCsv(vecForDatanalysis,DataAnalysis_Para)
        end


    end


    if Vizual_Para[:scatter_anim]
        #creates an animation and saves it
        animScatterFromVec(Env_Para,Posdata_anim,Vizual_Para)
    end

end
