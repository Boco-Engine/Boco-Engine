@echo off
for %%i in (src/*) do (	
	echo Compiling %%i
	glslc.exe src/%%i -o compiled/%%i.spv
)

IF %1.== no_pause. (
	exit
)

pause