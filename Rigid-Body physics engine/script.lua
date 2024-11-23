PhysicsObjects = {}
quaternions = require("quaternion")
copyStorage = models:newPart("copyStorage", "WORLD")
models.model:setParentType("WORLD")
cuboidWidth = 1
cuboidDepth = 1
cuboidHeight = 1


physicsIterations = 8
restitution = 0.4
deltaTime = 0.05/physicsIterations
gravity = vec(0,-10,0)

local function deRepetitize(tableIN)
local newTable = {}
for i, value in pairs(tableIN) do
    local included = true
    for j, oldValue in pairs(newTable) do
        if value == oldValue then
            included = false        
        end
    end
    log(value,newTable)
    if included then
        table.insert(newTable,value)
    end
end
return newTable
end



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

local function calculateContactAxis(axisX)
local axisY = (axisX+vec(0.01,0.1,1)):normalized()
local axisZ = axisX:crossed(axisY)
axisY = axisX:crossed(axisZ)
return {xAxis = axisX:normalized(), yAxis = axisY:normalize(), zAxis = axisZ:normalize()}
end

local function createBasisMatrix(x,y,z)
local newMat = matrices.mat3()
newMat[1] = vec(x.x,y.x,z.x)
newMat[2] = vec(x.y,y.y,z.y)
newMat[3] = vec(x.z,y.z,z.z)
return newMat
end    



function createContactMatrix(xAxis)

local yAxis = vec(0,0,0)
local zAxis = vec(0,0,0)


    if (math.abs(xAxis.x) > math.abs(xAxis.y)) then

        local s = 1/math.sqrt(xAxis.z*xAxis.z + xAxis.x*xAxis.x);

        
        yAxis.x = xAxis.z*s;
        yAxis.y = 0;
        yAxis.z = -xAxis.x*s;


        zAxis.x = xAxis.y*yAxis.x;
        zAxis.y = xAxis.z*yAxis.x - xAxis.x*yAxis.z;
        zAxis.z = -xAxis.y*yAxis.x;
    
    else

        local s = 1/math.sqrt(xAxis.z*xAxis.z + xAxis.y*xAxis.y)


        yAxis.x = 0;
        yAxis.y = -xAxis.z*s;
        yAxis.z = xAxis.y*s;

        zAxis.x = xAxis.y*yAxis.z -
            xAxis.z*yAxis.y;
        zAxis.y = -xAxis.x*yAxis.z;
        zAxis.z = xAxis.x*yAxis.y;
    

end
local retMat = matrices.mat3()
retMat[1] = vec(xAxis.x,yAxis.x,zAxis.x)
retMat[2] = vec(xAxis.y,yAxis.y,zAxis.y)
retMat[3] = vec(xAxis.z,yAxis.z,zAxis.z)
return retMat
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


local function findBoundingSphere(vertices)
    local sum = vec(0,0,0)
    for i, vertex in pairs(vertices) do
        sum = sum + vertex
    end
    local center = sum/#vertices
    local highestLength = 0
    for i, vertex in pairs(vertices) do
        local length = (center - vertex):length()
        if length > highestLength then
            highestLength = length
        end
    end
    return {center=center/16,radius=highestLength/16}
end

local colPlaneRadius = 10
function events.entity_init()
    colPlanes = {{colPlaneNormal = vec(0,1,0),colPlaneOffset = player:getPos().y},{colPlaneNormal = vec(1,0,0),colPlaneOffset = -colPlaneRadius+player:getPos().x},{colPlaneNormal = vec(0,0,1),colPlaneOffset = -colPlaneRadius+player:getPos().z},{colPlaneNormal = vec(-1,0,0),colPlaneOffset = -colPlaneRadius-player:getPos().x},{colPlaneNormal = vec(0,0,-1),colPlaneOffset = -colPlaneRadius-player:getPos().z}}
    local mass = 1
    local cuboidInertiaTensor = matrices.mat3()
    cuboidInertiaTensor[1] = vec((1/12)*mass*(cuboidHeight*cuboidHeight+cuboidDepth*cuboidDepth),0,0)
    cuboidInertiaTensor[2] = vec(0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidDepth*cuboidDepth),0)
    cuboidInertiaTensor[3] = vec(0,0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidHeight*cuboidHeight))
    cuboidInertiaTensor = cuboidInertiaTensor * 2



    createRigidBody(mass,player:getPos()+vec(0,3,0),vec(0.05,0,0),quaternions.new(0,0,0,1),vec(0,0,math.rad(0)),models.model.cuboid,cuboidInertiaTensor)
end







local dampening = 0.96
local angleDampening = 0.97
local angle = math.rad(0)
local angle2 = 199
local angle3 = 247
local quaternion = quaternions.new(math.cos(angle/2),1*math.sin(angle/2),0*math.sin(angle/2),0*math.sin(angle/2))
local rotation = vec(math.rad(angle2),math.rad(angle3),0)
function events.tick()
for j=1, physicsIterations do

for i, object in pairs(PhysicsObjects) do
     --quaternion = rotateQuaternionByVector(quaternion,rotation)
    addForce(i,gravity*object.mass)
 --   sphereMarker(object.position+object.boundingSphere.center, object.boundingSphere.radius, 1)

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
    local acceleration = 1/object.mass*object.forceAccumulator
--drawVector(object.angularVelocity*3,nil,object.position)
    object.angularVelocity = object.angularVelocity + angularAcceleration*deltaTime
 --s   log(objectWorldInertiaTensor)
    object.velocity = object.velocity+acceleration*deltaTime

    object.position = object.position + object.velocity*deltaTime
    object.rotation = addScaledQuaternion(object.rotation,object.angularVelocity,-deltaTime)

    object.velocity = object.velocity*dampening^(1/physicsIterations)
    object.angularVelocity = object.angularVelocity*angleDampening^(1/physicsIterations)
    for i, plane in pairs(colPlanes) do
    runCollision(object,objectWorldInertiaTensor,plane.colPlaneOffset,plane.colPlaneNormal)
    end
--[[
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
    particles:newParticle("minecraft:end_rod", posToConvert)]]
--    log(posToConvert)]]

--log(object.rotMat,"asasdhdjjkadjhdakjadsjjdkasdjkdaadsjhkdasjdasjhdjjashjkdasjdasj")
for i, vertex in pairs(object.copy:getAllVertices()["model.texture"]) do
    vertex:setPos(object.defVerts[i]*object.rotMat+object.position*16)

  -- particles:newParticle("minecraft:bubble", vertex:getPos()/16)
end


object.torqueAccumulator = vec(0,0,0)
object.forceAccumulator = vec(0,0,0)
end
end
--log(avatar:getNBT().models.chld[1].chld[1].mesh_data)
end




function pings.addForceAtBodyPoint(objectIndex,force,point)
    local newPoint = point-PhysicsObjects[objectIndex].position--transformWorldToLocal(point,PhysicsObjects[objectIndex].rotMat,PhysicsObjects[objectIndex].position)

    PhysicsObjects[objectIndex].torqueAccumulator = PhysicsObjects[objectIndex].torqueAccumulator+newPoint:crossed(force)*6
    PhysicsObjects[objectIndex].forceAccumulator = PhysicsObjects[objectIndex].forceAccumulator+force*-1
end

function addForce(objectIndex,force)
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
dimensions = {width = cuboidWidth, height = cuboidHeight, depth = cuboidDepth},
angularVelocity = angularVelocity,
copy = copy,
defVerts = defVerts,
defVertsButNoRepetition = deRepetitize(defVerts),
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


function runCollision(self,WIT,colPlaneOffset,colPlaneNormal) 
local tempVerts = {}
local highestPenetration = 0
local highestPenetrationIndex = 0
local contactPoints = {}

for i, vertex in pairs(self.defVertsButNoRepetition) do
        tempVerts[i] = (vertex/16)*self.rotMat+self.position
end

    for i, vertex in pairs(tempVerts) do
        local vertexDistance = vertex:dot(colPlaneNormal)

if vertexDistance <= colPlaneOffset then
    local penetration = colPlaneOffset - vertexDistance
    local contactNormal = colPlaneNormal
local contactPoint = colPlaneNormal*(vertexDistance-colPlaneOffset) + vertex




contactPoints[i]= {contactPoint=contactPoint,contactNormal=contactNormal,penetration=penetration,vertexDistance=vertexDistance}
if penetration>highestPenetration then
highestPenetration = penetration

highestPenetrationIndex = i
end    
end
end
if highestPenetrationIndex ~= 0 then
    --log(highestPenetrationIndex,contactPoints)
self.position = self.position - colPlaneNormal*(contactPoints[highestPenetrationIndex].vertexDistance-colPlaneOffset)
end
local impulses = {}

local contactAmount = 0
for i, contactPoint in pairs(contactPoints) do
contactAmount = contactAmount + 1
end
local velocityAccumulator = vec(0,0,0)
local angularVelocityAccumulator = vec(0,0,0)
for i, contactPoint in pairs(contactPoints) do

    local basisMatrix = createContactMatrix(contactPoint.contactNormal):transposed()
    local impulseContact = vec(0,0,0)

    local relativeContact = contactPoint.contactPoint-self.position

    local deltaVelWorld = (WIT*(relativeContact:crossed(contactPoint.contactNormal))):crossed(relativeContact)
    local deltaVelocity = deltaVelWorld:dot(contactPoint.contactNormal)+1/self.mass

    local velocity = self.angularVelocity:crossed(relativeContact)*-1+self.velocity
    local contactVelocity = basisMatrix:transposed()*velocity
    local desiredDeltaVelocity = -contactVelocity.x * (1+restitution)

    impulseContact.x = desiredDeltaVelocity/deltaVelocity
    
    local impulse = basisMatrix * impulseContact
   -- drawVector(impulse,nil,contactPoint.contactPoint)
    local velocityChange = impulse

    local impulsiveTorque = impulse:crossed(relativeContact)*-1
    local angularVelocityChange = impulsiveTorque

    velocityAccumulator = velocityAccumulator + velocityChange
    angularVelocityAccumulator = angularVelocityAccumulator - angularVelocityChange









end
self.velocity = self.velocity + velocityAccumulator * 1/self.mass
self.angularVelocity = self.angularVelocity +WIT*angularVelocityAccumulator



end


function events.mouse_press(button, action, modifier)
    if button == 0 and action == 1 then
        for i, object in pairs(PhysicsObjects) do
            local eyePos = transformWorldToLocal(player:getPos() + vec(0, player:getEyeHeight(), 0),object.rotMat,object.position)
            local eyeEnd = transformWorldToLocal((player:getPos() + vec(0, player:getEyeHeight(), 0))+player:getLookDir()*10,object.rotMat,object.position)
            local hitLocation = { { vec(-object.dimensions.width/2, -object.dimensions.height/2, -object.dimensions.depth/2), vec(object.dimensions.width/2, object.dimensions.height/2, object.dimensions.depth/2)} } 
            local aabb, hitPos, side, aabbHitIndex = raycast:aabb(eyePos, eyeEnd, hitLocation)
            if hitPos~= nil then
                local worldHitPos = transformLocalToWorld(hitPos,object.rotMat,object.position)
                particles:newParticle("minecraft:sonic_boom", worldHitPos)
                pings.addForceAtBodyPoint(i,player:getLookDir()*-300*physicsIterations,worldHitPos)
                
     --   drawVector(player:getLookDir()*10,nil,nil,10)
            end
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
        particles:newParticle("minecraft:bubble", at+cur)
        cur:add(step)
    end
end












function sphereMarker(pos, radius, quality)
    local pos = pos or vec(0, 0, 0)
    local r = radius or 1
    local quality = (quality or 1)*10



    -- Draw the center point
    particles:newParticle("minecraft:end_rod", pos)

    -- Draw surface points
    for i = 1, quality do
        for j = 1, quality do
            local theta = (i / quality) * 2 * math.pi
            local phi = (j / quality) * math.pi

            local x = pos.x + r * math.sin(phi) * math.cos(theta)
            local y = pos.y + r * math.sin(phi) * math.sin(theta)
            local z = pos.z + r * math.cos(phi)

            particles:newParticle("minecraft:bubble", x,y,z)
        end
    end
end




function events.key_press(key, action, modifier)
    if key == 75 and action == 1 then 
        pings.create(player:getPos())
    end    
end

function pings.create(pos)
    local mass = 1 
    local cuboidInertiaTensor = matrices.mat3()
    cuboidInertiaTensor[1] = vec((1/12)*mass*(cuboidHeight*cuboidHeight+cuboidDepth*cuboidDepth),0,0)
    cuboidInertiaTensor[2] = vec(0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidDepth*cuboidDepth),0)
    cuboidInertiaTensor[3] = vec(0,0,(1/12)*mass*(cuboidWidth*cuboidWidth+cuboidHeight*cuboidHeight))




    createRigidBody(mass,pos+vec(0,0,0),vec(0.0,0,0),quaternions.new(0,0,0,1),vec(0,0,math.rad(0)),models.model.cuboid,cuboidInertiaTensor)
end
