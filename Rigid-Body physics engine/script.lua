PhysicsObjects = {}
quaternions = require("quaternion")
copyStorage = models:newPart("copyStorage", "WORLD")
models.model:setParentType("WORLD")
cuboidWidth = 1
cuboidDepth = 1
cuboidHeight = 1
deltaTime = 0.05
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

local function inertiaTensorToWorld(object,rotMatrix)
    local tempmat = object.rotation:getMatrix()
 --   log(tempmat)
    local rotMat = matrices.mat3()
    rotMat[1] = vec(tempmat[1].x,tempmat[1].y,tempmat[1].z)
    rotMat[2] = vec(tempmat[2].x,tempmat[2].y,tempmat[2].z)
    rotMat[3] = vec(tempmat[3].x,tempmat[3].y,tempmat[3].z)
    local newTensor = rotMat*object.inertiaTensor:inverted()*rotMat:transposed()

    return newTensor
end    
--use this for rotation integration
models.model:setPos(vec(0,1000000,0))
--quaternion2 does not have the first value

--rotates a quaternion by a given vector
--quaternion2 does not have the first value

local function addScaledQuaternion(quaternion1,rotation,scale)
    local tempRot = rotation:copy():normalize()
    local quaternion2 = quaternions.new(rotation.x*0.5*deltaTime,rotation.y*0.5*deltaTime,rotation.z*0.5*deltaTime,0)
--    log(quaternion2,quaternion1,"1")

--    log(quaternion2,quaternion1,"2")
    return (quaternion1 + (quaternion1*quaternion2)):normalize()
end





function events.entity_init()

    local mass = 1 
    local cuboidInertiaTensor = matrices.mat3()
    cuboidInertiaTensor[1] = vec((1/12)*mass*(cuboidHeight*cuboidHeight+cuboidDepth*cuboidDepth),0,0)
    cuboidInertiaTensor[2] = vec(0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidDepth*cuboidDepth),0)
    cuboidInertiaTensor[3] = vec(0,0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidHeight*cuboidHeight))




    createRigidBody(mass,player:getPos()+vec(0,3,0),vec(0.05,0,0),quaternions.new(0,0,0,1),vec(0,0,math.rad(0)),models.model.cuboid,cuboidInertiaTensor)
end







local dampening = 0.992
local angleDampening = 0.99
local angle = math.rad(0)
local angle2 = 199
local angle3 = 247
local quaternion = quaternions.new(math.cos(angle/2),1*math.sin(angle/2),0*math.sin(angle/2),0*math.sin(angle/2))
local rotation = vec(math.rad(angle2),math.rad(angle3),0)
function events.tick()
    

for i, object in pairs(PhysicsObjects) do
     --quaternion = rotateQuaternionByVector(quaternion,rotation)



    local tempmat = object.rotation:getMatrix()

    object.rotMat = matrices.mat3()
    object.rotMat[1] = vec(tempmat[1].x,tempmat[1].y,tempmat[1].z)
    object.rotMat[2] = vec(tempmat[2].x,tempmat[2].y,tempmat[2].z)
    object.rotMat[3] = vec(tempmat[3].x,tempmat[3].y,tempmat[3].z)
--    log(object.rotMat*object.inertiaTensor*object.rotMat:transposed(),"LLLLLLLLLL")

    local objectWorldInertiaTensor = inertiaTensorToWorld(object,object.rotMat)
   -- log(objectWorldInertiaTensor)
    local angularAcceleration = object.torqueAccumulator*objectWorldInertiaTensor:inverted()
   -- log(object.angularVelocity,object.rotation.x,object.rotation.y,object.rotation.z,object.rotation.w)

drawVector(object.angularVelocity*3,nil,object.position)
    object.angularVelocity = object.angularVelocity + angularAcceleration*deltaTime
 --s   log(objectWorldInertiaTensor)



    object.position = object.position + object.velocity*deltaTime
    object.rotation = addScaledQuaternion(object.rotation,object.angularVelocity,-deltaTime)

    object.velocity = object.velocity*dampening
    object.angularVelocity = object.angularVelocity*angleDampening


    local posToConvert = vec(1,0,0)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
    local posToConvert = vec(-1,0,0)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
    local posToConvert = vec(0,-1,0)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
    local posToConvert = vec(0,1,0)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
    local posToConvert = vec(0,0,1)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
    local posToConvert = vec(0,0,-1)
    posToConvert = transformLocalToWorld(posToConvert,object.rotMat, object.position)
    particles:newParticle("minecraft:end_rod", posToConvert)
--    log(posToConvert)]]

--log(object.rotMat,"asasdhdjjkadjhdakjadsjjdkasdjkdaadsjhkdasjdasjhdjjashjkdasjdasj")
for i, vertex in pairs(object.copy:getAllVertices()["model.texture"]) do
    vertex:setPos(object.defVerts[i]*object.rotMat+object.position*16)

   particles:newParticle("minecraft:bubble", vertex:getPos()/16)
end


object.torqueAccumulator = vec(0,0,0)
object.forceAccumulator = vec(0,0,0)
end

--log(avatar:getNBT().models.chld[1].chld[1].mesh_data)
end




function pings.addForceAtBodyPoint(objectIndex,force,point)
    local newPoint = point-PhysicsObjects[objectIndex].position--transformWorldToLocal(point,PhysicsObjects[objectIndex].rotMat,PhysicsObjects[objectIndex].position)
    PhysicsObjects[objectIndex].torqueAccumulator = PhysicsObjects[objectIndex].torqueAccumulator+newPoint:crossed(force)
    PhysicsObjects[objectIndex].forceAccumulator = PhysicsObjects[objectIndex].forceAccumulator+force
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
forceAccumulator = vec(0,0,0),
torqueAccumulator = vec(0,0,0),
centerOfMass = vec(0,0,0),
rotMat = nil,
boundingSphere = findBoundingSphere(defVerts)
    })

end    


function getTransformMatrix(object)
    
    local transformMatrix = object.rotation:getMatrix()
    transformMatrix[1].w = object.position.x
    transformMatrix[2].w = object.position.y
    transformMatrix[3].w = object.position.z

    return transformMatrix

end


function events.mouse_press(button, action, modifier)
   if button == 0 and action == 1 then
    local eyePos = transformWorldToLocal(player:getPos() + vec(0, player:getEyeHeight(), 0),PhysicsObjects[1].rotMat,PhysicsObjects[1].position)
    local eyeEnd = transformWorldToLocal((player:getPos() + vec(0, player:getEyeHeight(), 0))+player:getLookDir()*10,PhysicsObjects[1].rotMat,PhysicsObjects[1].position)
    local hitLocation = { { vec(-cuboidWidth/2, -cuboidHeight/2, -cuboidDepth/2), vec(cuboidWidth/2, cuboidHeight/2, cuboidDepth/2)} } 
    local aabb, hitPos, side, aabbHitIndex = raycast:aabb(eyePos, eyeEnd, hitLocation)

    if hitPos~= nil then
    local worldHitPos = transformLocalToWorld(hitPos,PhysicsObjects[1].rotMat,PhysicsObjects[1].position)
    particles:newParticle("minecraft:sonic_boom", worldHitPos)
    pings.addForceAtBodyPoint(1,player:getLookDir()*-300,worldHitPos)
 --   drawVector(player:getLookDir()*10,nil,nil,10)
    end
   end
end


function drawVector(vector,particle,at,steps)
    particle = particle or "minecraft:bubble"
    at = at or player:getPos():add(0,player:getEyeHeight(),0)
    steps = steps or vector:length()*8
    local step = vector:normalized()*(vector:length()/steps)
    local cur = vec(0,0,0)
    for i = 1, steps do
        particles:newParticle("minecraft:crit", at+cur)
        cur:add(step)
    end
end













