@echo off
@if not defined DevEnvDir (
    set "InstalledVSPath="
    set "VsWherePath="

    setlocal enabledelayedexpansion

    @if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VsWherePath=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    )

    @if exist "C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VsWherePath=C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe"
    )

    if not defined VsWherePath (
        echo.
        echo #############################################################
        echo No Visual-Studio or VS-Build-Tools installation was detected.
        echo #############################################################
        exit /b 1
    )

    for /f "usebackq tokens=*" %%i in (
        `"!VsWherePath!" -products * -latest -property installationPath`
    ) do set "InstalledVSPath=%%i"

    if defined InstalledVSPath (
        if exist "!InstalledVSPath!\VC\Auxiliary\Build\vcvarsall.bat" (
            call "!InstalledVSPath!\VC\Auxiliary\Build\vcvarsall.bat" x64
        ) else (
            echo.
            echo ################################
            echo Error: vcvarsall.bat not found.
            echo ################################
            exit /b 1
        )
    ) else (
        echo.
        echo #############################################################
        echo No Visual-Studio or VS-Build-Tools installation was detected.
        echo #############################################################
        exit /b 1
    )
)

@echo off
where git >nul 2>&1
if %errorlevel% equ 1 (
    echo.
    echo Git is not installed.
    echo Git is required to download the source code for Vulkan libraries in this script.
    echo.
    echo To install Git on Windows, visit the link below and download it:
    echo Download Link: https://git-scm.com/downloads
    echo Quitting.
    echo.
    exit /b 1
) else (
    for /f "delims=" %%i in ('where git') do (
        set "git_path=%%i"
        goto :git_done
    )
    :git_done
    echo Git is already installed. Installation dir: "%git_path%"
)

echo.

@if not exist "%cd%\SPIRV-Headers" (
    git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Headers.git --recursive
) else (
    echo SPIRV-Headers folder already exists.
)

@if not exist "%cd%\SPIRV-Tools" (
    git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Tools.git --recursive
) else (
    echo SPIRV-Tools folder already exists.
)

@if not exist "%cd%\glslang" (
    git clone --depth 1 https://github.com/KhronosGroup/glslang.git --recursive
) else (
    echo glslang folder already exists.
)

@if not exist "%cd%\shaderc" (
    git clone --depth 1 https://github.com/google/shaderc.git --recursive
) else (
    echo shaderc folder already exists.
)

@if not exist "%cd%\Vulkan-Headers" (
    git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Headers.git --recursive
) else (
    echo Vulkan-Headers folder already exists.
)

@if not exist "%cd%\Vulkan-Loader" (
    git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Loader.git --recursive
) else (
    echo Vulkan-Loader folder already exists.
)

@if not exist "%cd%\Vulkan-Utility-Libraries" (
    git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Utility-Libraries --recursive
) else (
    echo Vulkan-Utility-Libraries folder already exists.
)

@if not exist "%cd%\valijson" (
    git clone --depth 1 https://github.com/tristanpenman/valijson.git --recursive
) else (
    echo valijson folder already exists.
)

@if not exist "%cd%\VulkanTools" (
    git clone --depth 1 https://github.com/LunarG/VulkanTools.git --recursive
) else (
    echo VulkanTools folder already exists.
)

@if not exist "%cd%\Vulkan-ValidationLayers" (
    git clone --depth 1 https://github.com/KhronosGroup/Vulkan-ValidationLayers.git --recursive
) else (
    echo Vulkan-ValidationLayers folder already exists.
)

@echo.
@echo off
set /P cmake_generator_type="Choose Cmake Generator -- 1 for Ninja(Recommended), 2 for Visual Studio Native : "
if "%cmake_generator_type%"=="1" (
    set CMAKE_GENERATOR=Ninja
) else if "%cmake_generator_type%"=="2" (

    setlocal EnableDelayedExpansion

    set "VS_VERSION_MAJOR="
    set "VS_YEAR="

    :: Get full installationVersion and extract first 2 characters (major version)
    for /f "usebackq tokens=*" %%i in (
        `"!VsWherePath!" -products * -latest -property installationVersion`
    ) do set "VS_VERSION_MAJOR=%%i"
    set "VS_VERSION_MAJOR=!VS_VERSION_MAJOR:~0,2!"

    :: Get full displayName and extract last 4 characters (year)
    for /f "usebackq tokens=*" %%i in (
        `"!VsWherePath!" -products * -latest -property displayName`
    ) do set "VS_YEAR=%%i"
    set "VS_YEAR=!VS_YEAR:~-4!"

    :: Construct the CMake generator string
    set "CMAKE_GENERATOR=Visual Studio !VS_VERSION_MAJOR! !VS_YEAR!"
) else (
    echo Invalid Cmake Generator. Please enter 1 or 2.
    exit /b 1
)
@echo.
echo Selected Cmake Generator: !CMAKE_GENERATOR!
@echo.

@echo.
@echo off
set /P build_choice=Choose build type (1 for Release, 2 for Debug):
if "%build_choice%"=="1" (
    set BUILD_TYPE=Release
    set COMPILE_FLAGS="/MP /O2 /arch:SSE4.2 /DWIN32 /EHsc"
) else if "%build_choice%"=="2" (
    set BUILD_TYPE=Debug
    set COMPILE_FLAGS="/MP /Od"
) else (
    echo Invalid build_choice. Please enter 1 or 2.
    exit /b 1
)
@echo.
echo Selected build type: %BUILD_TYPE%
@echo.

set /P "=Press any key to start compilation..." <nul & pause >nul & echo(

set /a NUM_THREADS=%NUMBER_OF_PROCESSORS% - 2

if %NUM_THREADS% LEQ 0 (
    set /a NUM_THREADS=1
)

set BUILD_DIR=%cd%\__build_dir__\%BUILD_TYPE%
set BUILD_DIR_VULKAN_SPIRV_Headers=%BUILD_DIR%\__SPIRVHeaders__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_SPIRV_Tools=%BUILD_DIR%\__SPIRVTools__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_GLSLANG=%BUILD_DIR%\__glslang__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_SHADERC=%BUILD_DIR%\__shaderc__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_HEADERS=%BUILD_DIR%\__VulkanHeaders__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_LOADER=%BUILD_DIR%\__VulkanLoader__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_UTILITY_LIBRARIES=%BUILD_DIR%\__VulkanUtilityLibraries__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VALIJSON=%BUILD_DIR%\__valijson__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_TOOLS=%BUILD_DIR%\__VulkanTools__\%BUILD_TYPE%\%LINK_TYPE%
set BUILD_DIR_VULKAN_ValidationLayers=%BUILD_DIR%\__VulkanValidationLayers__\%BUILD_TYPE%\%LINK_TYPE%

set BUILD_OUT_DIR=%cd%\__build_out__\%BUILD_TYPE%

rmdir /s /q %BUILD_DIR%

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D SPIRV_HEADERS_ENABLE_TESTS=OFF ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__SPIRVHeaders__ ^
    -S .\SPIRV-Headers ^
    -B %BUILD_DIR_VULKAN_SPIRV_Headers%

cmake --build %BUILD_DIR_VULKAN_SPIRV_Headers% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set SPIRV-Headers_DIR=%BUILD_OUT_DIR%\__SPIRVHeaders__\share\cmake

@echo off
setlocal enabledelayedexpansion
set SPIRV_Headers_SOURCE_DIR=%cd%\SPIRV-Headers
set "SPIRV_Headers_SOURCE_DIR=!SPIRV_Headers_SOURCE_DIR:\=/!"
cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D SPIRV-Headers_SOURCE_DIR=%SPIRV_Headers_SOURCE_DIR% ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__SPIRVTools__ ^
    -S .\SPIRV-Tools ^
    -B %BUILD_DIR_VULKAN_SPIRV_Tools%

cmake --build %BUILD_DIR_VULKAN_SPIRV_Tools% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set SPIRV-Tools_DIR=%BUILD_OUT_DIR%\__SPIRVTools__\SPIRV-Tools\cmake
set SPIRV-Tools-opt_DIR=%BUILD_OUT_DIR%\__SPIRVTools__\SPIRV-Tools-opt\cmake

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D ENABLE_GLSLANG_JS=OFF ^
    -D ALLOW_EXTERNAL_SPIRV_TOOLS=ON ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__glslang__ ^
    -S .\glslang ^
    -B %BUILD_DIR_VULKAN_GLSLANG%

cmake --build %BUILD_DIR_VULKAN_GLSLANG% --config %BUILD_TYPE% --target install -j%NUM_THREADS%


set glslang_SOURCE_DIR=%cd%\glslang
set "glslang_SOURCE_DIR=!glslang_SOURCE_DIR:\=/!"
set SPIRV_Tools_SOURCE_DIR=%cd%\SPIRV-Tools
set "SPIRV_Tools_SOURCE_DIR=!SPIRV_Tools_SOURCE_DIR:\=/!"
cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D SHADERC_SKIP_TESTS=ON ^
    -D SHADERC_SKIP_EXAMPLES=ON ^
    -D SHADERC_ENABLE_WGSL_OUTPUT=OFF ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__shaderc__ ^
    -D SHADERC_SPIRV_TOOLS_DIR=%SPIRV_Tools_SOURCE_DIR% ^
    -D SHADERC_SPIRV_HEADERS_DIR=%SPIRV_Headers_SOURCE_DIR% ^
    -D SHADERC_GLSLANG_DIR=%glslang_SOURCE_DIR% ^
    -S .\shaderc ^
    -B %BUILD_DIR_VULKAN_SHADERC%

cmake --build %BUILD_DIR_VULKAN_SHADERC% --config %BUILD_TYPE% --target install -j%NUM_THREADS%


cmake -G "!CMAKE_GENERATOR!" ^
    -D VULKAN_HEADERS_ENABLE_TESTS=OFF ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__VulkanHeaders__ ^
    -S .\Vulkan-Headers ^
    -B %BUILD_DIR_VULKAN_HEADERS%

cmake --build %BUILD_DIR_VULKAN_HEADERS% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set VulkanHeaders_DIR=%BUILD_OUT_DIR%\__VulkanHeaders__\share\cmake

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D CMAKE_C_FLAGS=%COMPILE_FLAGS% ^
    -D BUILD_TESTS=OFF ^
    -D BUILD_WERROR=OFF ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__VulkanLoader__ ^
    -S .\Vulkan-Loader ^
    -B %BUILD_DIR_VULKAN_LOADER%

cmake --build %BUILD_DIR_VULKAN_LOADER% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set VulkanLoader_DIR=%BUILD_OUT_DIR%\__VulkanLoader__\lib\cmake

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__VulkanUtilityLibraries__ ^
    -S .\Vulkan-Utility-Libraries ^
    -B %BUILD_DIR_VULKAN_UTILITY_LIBRARIES%

cmake --build %BUILD_DIR_VULKAN_UTILITY_LIBRARIES% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set VulkanUtilityLibraries_DIR=%BUILD_OUT_DIR%\__VulkanUtilityLibraries__\lib\cmake

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__valijson__ ^
    -S .\valijson ^
    -B %BUILD_DIR_VALIJSON%

cmake --build %BUILD_DIR_VALIJSON% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
set valijson_DIR=%BUILD_OUT_DIR%\__valijson__\lib\cmake

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D BUILD_LAYERMGR=OFF ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__VulkanTools__ ^
    -S .\VulkanTools ^
    -B %BUILD_DIR_VULKAN_TOOLS%

cmake --build %BUILD_DIR_VULKAN_TOOLS% --config %BUILD_TYPE% --target install -j%NUM_THREADS%

cmake -G "!CMAKE_GENERATOR!" ^
    -D CMAKE_BUILD_TYPE=%BUILD_TYPE% ^
    -D CMAKE_CXX_FLAGS=%COMPILE_FLAGS% ^
    -D WIN32="ON" ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR%\__VulkanValidationLayers__ ^
    -S .\Vulkan-ValidationLayers ^
    -B %BUILD_DIR_VULKAN_ValidationLayers%

cmake --build %BUILD_DIR_VULKAN_ValidationLayers% --config %BUILD_TYPE% --target install -j%NUM_THREADS%
