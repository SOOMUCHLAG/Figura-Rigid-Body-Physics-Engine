PhysicsObjects = {}
--TO DO test these functions
--Added in this commit:
--All the functions you see here
--transforms a quaternion into a rotation matrix
local function quaternionToMatrix3(quaternion)

local newMat = matrices.mat3()

newMat[1] = vec(1-(2*quaternion.y*quaternion.y+2*quaternion.z*quaternion.z), 2*quaternion.x*quaternion.y + 2*quaternion.z*quaternion.w, 2*quaternion.x*quaternion.z-2*quaternion.y*quaternion.w)
newMat[2] = vec(2*quaternion.x*quaternion.y - 2*quaternion.z*quaternion.w, 1 - (2*quaternion.x*quaternion.x+2*quaternion.z*quaternion.z),2*quaternion.y*quaternion.z+2*quaternion.x*quaternion.w)
newMat[3] = vec(2*quaternion.x*quaternion.z+2*quaternion.y*quaternion.w,2*quaternion.y*quaternion.z-2*quaternion.x*quaternion.w,1 - (2*quaternion.x*quaternion.x+2*quaternion.y*quaternion.y))
end  

--transforms a quaternion into a rotation matrix with an added column for translation
local function quaternionToMatrix4(quaternion,pos)

    local newMat = matrices.mat4()
    
    newMat[1] = vec(1-(2*quaternion.y*quaternion.y+2*quaternion.z*quaternion.z), 2*quaternion.x*quaternion.y + 2*quaternion.z*quaternion.w, 2*quaternion.x*quaternion.z-2*quaternion.y*quaternion.w,pos.x)
    newMat[2] = vec(2*quaternion.x*quaternion.y - 2*quaternion.z*quaternion.w, 1 - (2*quaternion.x*quaternion.x+2*quaternion.z*quaternion.z),2*quaternion.y*quaternion.z+2*quaternion.x*quaternion.w,pos.y)
    newMat[3] = vec(2*quaternion.x*quaternion.z+2*quaternion.y*quaternion.w,2*quaternion.y*quaternion.z-2*quaternion.x*quaternion.w,1 - (2*quaternion.x*quaternion.x+2*quaternion.y*quaternion.y),pos.z)
end  

--transforms local coordinates into world coordinates using the objects transform matrix
local function transformLocalToWorld(vector3, transformMatrix)
local tempVec = vec(vector3.x,vector3.y,vector3.z,1)
return tempVec * transformMatrix
end

local function transformWorldToLocal(vector3, transformMatrix)
local tempVec = vec(vector3.x,vector3.y,vector3.z,1)
return tempVec * transformMatrix:inverted()
end

local function transformLocalDirToWorld(vector3, transformMatrix)
return vec(vector3.x*transformMatrix[1].x+vector3.y*transformMatrix[1].y+vector3.z*transformMatrix[1].z,vector3.x*transformMatrix[2].x+vector3.y*transformMatrix[2].y+vector3.z*transformMatrix[2].z,vector3.x*transformMatrix[3].x+vector3.y*transformMatrix[3].y+vector3.z*transformMatrix[3].z)
end    

local function transformWorldDirToLocal(vector3, transformMatrix)
local invertedTransformMatrix = transformMatrix:inverted()
return vec(vector3.x*invertedTransformMatrix[1].x+vector3.y*invertedTransformMatrix[1].y+vector3.z*invertedTransformMatrix[1].z,vector3.x*invertedTransformMatrix[2].x+vector3.y*invertedTransformMatrix[2].y+vector3.z*invertedTransformMatrix[2].z,vector3.x*invertedTransformMatrix[3].x+vector3.y*invertedTransformMatrix[3].y+vector3.z*invertedTransformMatrix[3].z)
end    

local function multiplyQuaternions(quaternion1,quaternion2)
return vec(quaternion1.w*quaternion2.w-quaternion1.x*quaternion2.x-quaternion1.y*quaternion2.y-quaternion1.z*quaternion2.z,    quaternion1.w*quaternion2.x+quaternion1.x*quaternion2.w+quaternion1.y*quaternion2.z-quaternion1.z*quaternion2.y,   quaternion1.w*quaternion2.y-quaternion1.x*quaternion2.z+quaternion1.y*quaternion2.w+quaternion1.z*quaternion2.x,   quaternion1.w*quaternion2.z+quaternion1.x*quaternion2.y-quaternion1.y*quaternion2.x+quaternion1.z*quaternion2.w)
end

function events.entity_init()

end









function events.tick()

end











function events.render(delta, context)

end
