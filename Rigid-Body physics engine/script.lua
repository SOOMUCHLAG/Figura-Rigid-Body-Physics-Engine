PhysicsObjects = {}
quaternions = require("quaternion")
copyStorage = models:newPart("copyStorage", "WORLD")
models.model:setParentType("WORLD")
cuboidWidth = 1
cuboidDepth = 1
cuboidHeight = 1
--I swear to go this fucking book 
--it has quaternions using w as the first component
--fix that shit








--transforms local coordinates into world coordinates using the objects transform matrix
local function transformLocalToWorld(vector3, rotMat,translation)
return (vector3 * rotMat)+translation
end

local function transformWorldToLocal(vector3, rotMat,translation)
    return ((vector3-translation) * rotMat:inverted())
end

local function transformLocalDirToWorld(vector3, rotMat)
return vector3*rotMat 
end    

local function transformWorldDirToLocal(vector3, rotMat)
return vector3*rotMat:inverted() 
end    

local function inertiaTensorToWorld(object,rotMat)
return rotMat*object.inertiaTensor*rotMat:transposed()
end    
--use this for rotation integration
models.model:setPos(vec(0,1000000,0))
--quaternion2 does not have the first value

--rotates a quaternion by a given vector
--quaternion2 does not have the first value

local function addScaledQuaternion(quaternion1,rotation,scale)
    local quaternion2 = quaternions.new(0,rotation.x*scale,rotation.y*scale,rotation.z*scale)
    quaternion2 = quaternion2*quaternion1
    return quaternions.new(quaternion1.x+quaternion2.x*0.5,quaternion1.y+quaternion2.y*0.5,quaternion1.z+quaternion2.z*0.5,quaternion1.w+quaternion2.w*0.5):normalize()
end





function events.entity_init()

    local mass = 1 
    local cuboidInertiaTensor = matrices.mat3()
    cuboidInertiaTensor[1] = vec((1/12)*mass*(cuboidHeight*cuboidHeight+cuboidDepth*cuboidDepth),0,0)
    cuboidInertiaTensor[2] = vec(0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidDepth*cuboidDepth),0)
    cuboidInertiaTensor[3] = vec(0,0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidHeight*cuboidHeight))




    createRigidBody(mass,player:getPos(),vec(0,0,0),quaternions.new(0,1,0,0),vec(0,0,0),models.model.cuboid,cuboidInertiaTensor)
end








local angle = math.rad(0)
local angle2 = 45
local angle3 = 20
local quaternion = quaternions.new(math.cos(angle/2),1*math.sin(angle/2),0*math.sin(angle/2),0*math.sin(angle/2))
local rotation = vec(math.rad(angle2),math.rad(angle3),0)
function events.tick()
    

for i, object in pairs(PhysicsObjects) do
     --quaternion = rotateQuaternionByVector(quaternion,rotation)

    tempmat = object.rotation:getMatrix()
    mat = matrices.mat3()
    mat[1] = vec(tempmat[1].x,tempmat[1].y,tempmat[1].z)
    mat[2] = vec(tempmat[2].x,tempmat[2].y,tempmat[2].z)
    mat[3] = vec(tempmat[3].x,tempmat[3].y,tempmat[3].z)
    

    local objectWorldInertiaTensor = inertiaTensorToWorld(object,mat)
    object.rotation = addScaledQuaternion(object.rotation,rotation,0.05)
    



    local posToConvert = vec(2,0,0)

    posToConvert = transformLocalToWorld(posToConvert,mat, object.position)
--    log(posToConvert)

    particles:newParticle("minecraft:bubble", posToConvert)
for i, vertex in pairs(object.copy:getAllVertices()["model.texture"]) do
    vertex:setPos(object.defVerts[i]*mat+object.position*16)

    particles:newParticle("minecraft:bubble", vertex:getPos()/16)
end
end

--log(avatar:getNBT().models.chld[1].chld[1].mesh_data)
end











function events.render(delta, context)

end





function createRigidBody(mass,position,velocity,rotation,angularVelocity,modelpart,inertiaTensor)
    local copy
    copy = modelpart:copy("block")
    copyStorage:addChild(copy)
    local defVerts = {}
for i, vertex in pairs(copy:getAllVertices()["model.texture"]) do
    table.insert(defVerts,vertex:getPos())
end
    table.insert(PhysicsObjects,{
mass = mass,
position = position,
velocity = velocity,
rotation = rotation,
angularVelocity = angularVelocity,
copy = copy,
defVerts = defVerts,
inertiaTensor = inertiaTensor,
    })

end    

function getTransformMatrix(object)
    
    local transformMatrix = object.rotation:getMatrix()
    transformMatrix[1].w = object.position.x
    transformMatrix[2].w = object.position.y
    transformMatrix[3].w = object.position.z

    return transformMatrix

end