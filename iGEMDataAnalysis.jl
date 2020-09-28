using Flux
using CSV
using DataFrames
using Random

#imports CSV file, each line contains a target value of 0 or 1 followed by
#a feature vector
data=CSV.File("dataforAanalysis.CSV",header=false)

#counts number of lines in the cvs, this is the number of feature vectors
function countcsvlines(data)
    #counter
    n = 0
    #iterate over rows and count
    for row in eachrow(data)
        n += 1
    end
    return n
end

#gets the number of rows which is the number of features in each feature vector
#-1
function getNrFeatures(data)
    #counter
    n=0
    #iterate over the last row and count
    for i in data[end]
        n +=1
    end
    return n-1
end

#normalize data such that all elements are on [0,1]
function minMaxNormalization(data)
    #find max
    max=maximum(data)
    #find min
    min=minimum(data)
    #scale all elements
    data=(data.-min)/(max-min)
    #return scaled data
    return data
end


#Evaluates are model with the test data and returns
#[positive,negative,false positive,false negative]
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

#calculate accuracy based on output from evaluation function
function getAccuracy(eval)
    return (eval[1]+eval[2])/(sum(eval))
end




#main script
let
    #get number of feature vectors
    N_vec=countcsvlines(data)
    #get number of features in each vector
    N_feat=getNrFeatures(data)

    #initialization of matrix to hold feature vectors
    Xs=zeros(N_vec,N_feat)
    #initialization of vector to hold target values
    Ys=zeros(N_vec,1)
    #counter
    i=1
    #convert CSV into feature vectors and targets
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
    #normalize data
    Xs=minMaxNormalization(Xs)
    #convert to Float32 to save memmory
    Xs=convert(Array{Float32},Xs)
    Ys=convert(Array{Float32},Ys)

    #create nerual net model, example: Flux.Chain(Dense(N_feat,20,σ),Dense(20,1))
    #has N feature inputs, with two length 20 hidden nodes and one output
    model=Flux.Chain(Dense(N_feat,20,σ),Dense(20,1))
    #create our loss function, mse = mean square error
    L(x,y)=Flux.Losses.mse(model(x), y)
    #model parameters
    par=Flux.params(model)
    #opt = Flux.Descent(0.0001)
    opt = RMSProp(0.0001, 0.9)
    #our optimizer
    #opt = ADAM()

    #combine feature vector and target into a vector of touples
    D=Vector(undef,N_vec)
    for i in 1:N_vec
        dat=(Xs[i,:],Ys[i])
        D[i,:]=[dat]
    end
    #shoufle data randomly
    shuffle!(D)
    #keep 90% of data for traning and 10% for testing
    ind=Int(N_vec*0.9)
    D_train=D[1:ind]
    D_test=D[ind+1:N_vec]

    #number of traning steps
    echos=500
    for e in 1:echos
        #train our model (update weights)
        Flux.train!(L,par,D_train,opt)
    end
    #evalute model
    eval=getEvaluation(model,D_test)
    #get accuracy
    acc=getAccuracy(eval)
    #print results
    println("Accuracy: ",acc,"  ","Positive: ",eval[1],"  ","Negative: ",eval[2],"  ","False positive: ",eval[3],"  ","False negative: ",eval[4])

end
