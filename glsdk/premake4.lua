solution "glsdk"
	configurations {"Debug", "Release"}
	defines {"_CRT_SECURE_NO_WARNINGS", "_SCL_SECURE_NO_WARNINGS"}


local libPremakes = 
{
	"glload/glload.lua",
	"glimg/glimg.lua",
	"glfw/glfw.lua",
	"freeglut/freeglut.lua",
	"glutil/glutil.lua",
	"glmesh/glmesh.lua",
}

for i, luaPremake in ipairs(libPremakes) do
	if(#os.matchfiles(luaPremake) ~= 0) then
		dofile(luaPremake)
	end
end
	

