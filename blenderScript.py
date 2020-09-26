import csv
import bpy


N_obj=10 #number of objects
dim=3 #number of dimensions that the object s hould move in

#set true if you want to import an .obj file that is suppose to be copied
importObject=False
#set true if you want to copy a object that is selected with cursour
CopySelected=True

#file path for import, the name of the imported object has to contain name_space
obj_loc = '/home/jonas/Desktop/Salmon_texture.obj'

#file path to csv that contains the locations of each object at each time frame.
#each line contains a frame, first entry is a time stamp or somem other information.
#then the next tree entries in that line are [x,y,z] positions 
csv_loc='/home/jonas/Desktop/FileName.csv'  

#The objects that are important or copied will only be found if their name 
#contains this name space, this is not case sensetive
name_space="salmon"


#imports object 
if importObject:
    #import N_obj objects and put them in scene
    for i in range(N_obj):
        new_obj = bpy.ops.import_scene.obj(filepath=obj_loc)
        
        
        
if CopySelected:
    #The scene that our object will be placed in
    scn = bpy.context.scene.collection
    
    #object that we are going to copy, this is selected on the gui by the user
    src_obj = bpy.context.active_object
    
    #for N-1 we copy our object, -1 since we have one from before
    for i in range (N_obj-1):
        new_obj = src_obj.copy()
        #change name such that the object can be found by it later
        new_obj.name= "Salmon"
        #copy object data
        new_obj.data = src_obj.data.copy()
        #clear animation data
        new_obj.animation_data_clear()
        #set the object in our scene
        scn.objects.link(new_obj)
    



#array hold the objects that we want to animate
our_objects=[]
#loop over all objects in scene
for ob in bpy.context.scene.objects:
    #checks if object has the right name not case sensetiv
    if name_space.lower() in ob.name.lower():
        #append to array
        our_objects.append(ob)



#frame number
frame_num=1
#open csv 
with open(csv_loc, 'r', newline='') as csvfile:
    #our file 
    current_file = csv.reader(csvfile, delimiter=',')
    
    #for each line (row) in current file
    for line in current_file:
        #f takes the time stamp first entry, then *pos contains all our positions 
        f, *pos = line
        
        #convert positional values to floats
        fpos = [float(p) for p in pos]
        #initialize array to hold coordinates
        coordinates=[]
        
        #for N_obj append positional values for each agent to the coordinate array
        for i in range(N_obj):
            #if dimension equals 2 then set z=0
            if dim==2:
                temp_pos=[fpos[i-1],fpos[i],0]
                coordinates.append(temp_pos)
                       
            if dim==3:
                temp_pos=[fpos[i-1],fpos[i],fpos[i+1]]
                coordinates.append(temp_pos)
        
        #set frame
        bpy.context.scene.frame_set(frame_num)
        #for each object and position 
        for ob, position in zip(our_objects, coordinates):
            #assign new position
            ob.location = position
            #save frame
            ob.keyframe_insert(data_path="location", index=-1)
        #count frame number
        frame_num+=1
        
        
#Special thanks to zeffii at stackexchange, for a good answer to a similar problem.
