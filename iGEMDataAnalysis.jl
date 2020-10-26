using Flux
using CSV
using DataFrames
using Random
using BSON: @save

#Counts number of lines in the cvs, this is the number of feature vectors
#Input: data, a CSV file
#Output: n,Integer number of rows
function countcsvlines(data)
    #counter
    n = 0
    #iterate over rows and count
    for row in eachrow(data)
        n += 1
    end
    return n
end

#Gets the number of rows which is the number of features in each feature vector
#-1
#Input: data, a CSV file
#Output: n,Integer number of columns -1
function getNrFeatures(data)
    #counter
    n=0
    #iterate over the last row and count
    for i in data[end]
        n +=1
    end
    return n-1
end

#Normalize data such that all elements are on [0,1] for each feature
#Input: data, a multidimensional array
#Output: data, a multidimensional array
function minMaxNormalization(data)
    #for each colmn in data
    for i in 1:size(data)[2]
        #find max in column
        max=maximum(data[:,i])
        #find min in column
        min=minimum(data[:,i])
        #scale column
        data[:,i]=(data[:,i].-min)/(max-min)
    end
    #return scaled data
    return data
end

#=
Evaluates are model with the test data and returns
Input:
1. model, Flux model our nerual net
2. test_data, multidimensional array
Output:
1. Array of integers. [positive,negative,false positive,false negative]
=#
function getEvaluation(model,test_data)
    #variables to store results
    FP=0
    FN=0
    P=0
    N=0
    #for all rows in test data
    for i in 1:size(test_data)[1]
        #Evalute feature vector i with model
        res=model(test_data[i][1])
        #remove extra brackets
        res=res[1]
        #if target is 1
        if test_data[i][2]==1
            #rightly classified as positive
            if res>0.5
                P+=1
            #wrongly classified as negative
            else
                FN+=1
            end
        #if target is 0
        else
            #rightly classified as negative
            if res<=0.5
                N+=1
            #wrongly classified as positive
            else
                FP+=1
            end
        end
    end
    #return values in an array
    return [P,N,FP,FN]

end



#=
Calculate accuracy based on output from evaluation function
Input:
1. eval, Array of integers [positive,negative,false positive,false negative]
Output:
1. Float64, (rightly classified)/(wrongly classified+rightly classified)
=#
function getAccuracy(eval)
    return (eval[1]+eval[2])/(sum(eval))
end


#=
#Splits data as close as possible to the train_percentage then returns an array
#of the form [data_train, data_test]
Input:
1. train_percentage, Float 64,
2. data, Multidimensional array, data used of traning and testing the classifier
Output:
1. D_train,D_test multidimensional array
=#
function splitDataTraningAndTest(train_percentage,data)
    #find cutoff index
    cutoff=Int(ceil(length(data)*train_percentage))
    #split data
    D_test=data[1:cutoff]
    D_train=data[cutoff+1:end]
    return D_train,D_test
end

#Main script
let
    #saves the neural net (Flux model) as bson file if set true
    savemodel=true
    #Imports CSV file, each line contains a target value of 0 or 1 followed by
    #a feature vector
    data=CSV.File("dataforAnalysis.CSV",header=false)

    #percentage of data that is for traning, the rest is for testing
    train_percentage=0.9
    #get number of feature vectors
    N_vec=countcsvlines(data)
    #get number of features in each vector
    N_feat=getNrFeatures(data)

    #Initialization of matrix to hold feature vectors
    Xs=zeros(N_vec,N_feat)
    #initialization of vector to hold target values
    Ys=zeros(N_vec,1)
    #counter
    i=1
    #Convert CSV into feature vectors and targets
    #for each row
    for row in eachrow(data)
        temp_row=[]
        #add each element of that row to the temporary vector
        for entry in row
            append!(temp_row,entry)
        end
        #add all features to feature matrix s.t. each row is a feature
        Xs[i,:]=temp_row[2:N_feat+1]
        #add the target to the target vector
        Ys[i]=Int(temp_row[1])
        #increment
        i+=1
    end
    #Normalize data
    Xs=minMaxNormalization(Xs)
    #Convert to Float32 to save memmory
    Xs=convert(Array{Float32},Xs)
    Ys=convert(Array{Float32},Ys)

    #Create nerual net model, example: Flux.Chain(Dense(N_feat,20,σ),Dense(20,1))
    #has N feature inputs, with one hidde layer that has 20 nodes and one
    #output layer with one node
    model=Flux.Chain(Dense(N_feat,40,σ),Dense(40,30),Dense(30,15),Dense(15,10),Dense(10,5),Dense(5,1))

    #Create our loss function, mse = mean square error
    L(x,y)=Flux.Losses.mse(model(x), y)
    #model parameters
    par=Flux.params(model)
    #eta our learning rate
    η=0.001
    #The optimizer, decides how we change our parameters to minimize loss
    #Use classic gradient decent
    opt = ADAM(η, (0.9, 0.999))
    #Combine feature vector and target into a vector of touples
    D=Vector(undef,N_vec)
    for i in 1:N_vec
        dat=(Xs[i,:],Ys[i])
        D[i,:]=[dat]
    end
    #Shoufle data randomly
    shuffle!(D)

    D_test,D_train=splitDataTraningAndTest(train_percentage,D)

    #Number of traning steps
    echos=1000
    for e in 1:echos
        #train our model (update weights)
        Flux.train!(L,par,D_train,opt)
    end
    #evalute model
    eval=getEvaluation(model,D_test)

    #get accuracy given output from getEvaluation
    acc=getAccuracy(eval)
    #print results
    println("Accuracy: ",acc,"  ","Positive: ",eval[1],"  ","Negative: ",
    eval[2],"  ","False positive: ",eval[3],"  ","False negative: ",eval[4])

    #save model as "FluxModel.bson" in project directory
    if savemodel
        @save "FluxModel.bson" model
    end

end
