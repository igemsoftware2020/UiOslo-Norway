using Flux
using CSV
using DataFrames
using Random
using Plots

data=CSV.File("traningData.CSV",header=false)

function countcsvlines(file)
    n = 0
    for row in eachrow(file)
        n += 1
    end
    return n
end

function getNrFeatures(file)
    n=0
    for i in file[1]
        n +=1
    end
    return n
end


N_vec=countcsvlines(data)

#println(N_vec)

N_feat=getNrFeatures(data)-1

#return accuracy
function getAccuracy(model,data)
    #accuracy
    F=0
    P=0
    for i in 1:size(data)[1]
        #println(D_test[i][2])
        res=model(data[i][1])
        res=res[1]
        #println(model(Xs[1,:]))
        #if convert(Float32,res[1])==convert(Float32,D_test[i][2])
        if data[i][2]==1
            if convert(Float32,res)>0.5
                P=P+1
            else
                F=F+1
            end
        else
            if convert(Float32,res)<=0.5
                P=P+1
            else
                F=F+1
            end
        end

    end

    return P/(F+P)

end





let
    #convert CSV into arrays contaning feature vectors and targets
    Xs=zeros(N_vec,N_feat)
    Ys=zeros(N_vec,1)
    i=1
    for row in eachrow(data)
        temp_row=[]
        for entry in row
            append!(temp_row,entry)
        end
        Xs[i,:]=temp_row[2:N_feat+1]
        Ys[i]=Int(temp_row[1])
        i=i+1
    end


    model=Flux.Chain(Dense(N_feat,5,σ),Dense(5,1))
    L(x,y)=Flux.Losses.mse(model(x), y)
    par=Flux.params(model)
    opt = Flux.Descent(0.05)

    D=Vector(undef,N_vec)
    for i in 1:N_vec
        dat=(Xs[i,:],Ys[i])
        D[i,:]=[dat]
    end

    shuffle!(D)

    ind=Int(N_vec*0.9)
    D_train=D[1:ind]
    D_test=D[ind+1:N_vec]
    #D_test=D_train

    A=[]
    echos=1000
    for e in 1:echos
        Flux.train!(L,par,D_train,opt)
        if e%10==0
            acc=getAccuracy(model,D_test)
            append!(A,acc)
        end
    end

    #println(model(D_test[1][1]))

    println(A)
    #fig=plot(1:size(A)[1],A)
    #display(fig)
    #savefig("fig1")

end
