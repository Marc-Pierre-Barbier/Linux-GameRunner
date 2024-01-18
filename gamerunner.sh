#!/bin/bash

# Gamerunner a hook for gamemode and nvidia prime render offload to avoid crashed with optimus-manager

function preload() {
	export LD_PRELOAD="${LD_PRELOAD}${LD_PRELOAD:+:}$1"
}


MAIN_VENDOR=$(glxinfo | grep "OpenGL vendor string")
VULKAN_VENDOR=$(vulkaninfo --summary  | grep "driverName" | grep -v llvm)
NVK_ICD="/usr/share/vulkan/icd.d/nouveau_icd.i686.json:/usr/share/vulkan/icd.d/nouveau_icd.x86_64.json"
NVKTEST=$(VK_ICD_FILENAMES=$NVK_ICD vulkaninfo --summary)

if [ "$MAIN_VENDOR" == "OpenGL vendor string: MESA" ]
then
	MODE="nvk"
else
	if [ "$MAIN_VENDOR" == "OpenGL vendor string: NVIDIA Corporation" ]
	then
		MODE="nvidia"
		export GAMESCOPE=0
	else
		if [[ "$VULKAN_VENDOR" =~ "NVIDIA" ]]
		then
			MODE="hybrid"
		else
			if [[ ! -z "$NVKTEST" ]]
			then
				MODE="hybridnvk"
			else
				MODE="integrated"
			fi
		fi
	fi
fi

if [ ! -z "${GR_SWITCH_ONLY}" ] && (( $GR_SWITCH_ONLY == 1 ))
then
	echo "Skipping env variables"
else
	USE_GAMEMODE=0
	MANGOHUD=0
	GAMESCOPE=0

	#if the config doesn't exist load /etc/gamerunner.cfg instead of ~/.config/gamerunner.cfg
	if [ -f "$HOME/.config/gamerunner.cfg" ]
	then
		echo "Loading user config"
		source ~/.config/gamerunner.cfg
	else
		echo "Loading system config"
		if [ -f "/app/etc/gamerunner.cfg" ]
		then
			source /app/etc/gamerunner.cfg
		else
			source /etc/gamerunner.cfg
		fi
	fi



	#Export the config
	export VKD3D_CONFIG
	export PROTON_ENABLE_NVAPI
	export __GL_THREADED_OPTIMIZATIONS
	export mesa_glthread
	export RADV_PERFTEST
	export __GL_MaxFramesAllowed
	export PROTON_HIDE_NVIDIA_GPU
	export PROTON_ENABLE_NGX_UPDATER
	export MANGOHUD

	if [ "$#" -eq 0 ]; then
		programname=`basename "$0"`
		echo "ERROR: No program supplied"
		echo
		echo "Usage: $programname <program>"
		exit 1
	fi

	if [ "$GR_SAFE" == "1" ]
	then
		echo "Safe mode"
		GAMESCOPE=0
		export MANGOHUD=0
	fi


	if (( $USE_GAMEMODE == 1 ))
	then
		preload "libgamemodeauto.so.0"
	fi

	if [ "$MODE" = "nvidia" ] || [ "$MODE" = "hybrid" ]
	then
		echo "Disabling gamescope"
		GAMESCOPE=0
	fi

	if (( $GAMESCOPE == 1 ))
	then
		echo "Disabling mangohud for safety with gamescope"
		export MANGOHUD=0
	fi

	if (( $MANGOHUD == 2 ))
	then
		echo force loading mangohud
		#on load la lib mango
		preload "libMangoHud.so"
		if (( "$USE_DLSYM" == 1 ))
		then
			export MANGOHUD_DLSYM=1
			preload "libMangoHud_dlsym.so"
		fi
		export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/\$LIB:/usr/\$LIB/mangohud"
		export MANGOHUD=1
	fi

	if (( $OBSCAP == 1 ))
	then
		echo loading obs vulkan capture
		preload "/usr/\$LIB/obs_glcapture/libobs_glcapture.so"
		export OBS_VKCAPTURE=1
		
	fi
fi

if [ "$MODE" == "nvidia" ]
then
	# Do nothing
	echo "nvidia"
	export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
	export __GLX_VENDOR_LIBRARY_NAME=nvidia
else
	if [ "$MODE" == "hybridnvk" ]
	then
		export DRI_PRIME=1
		#All nvk specific should by compatible with hybrid
		MODE="nvk"
		echo "Hybrid-nvk"
	fi

	if [ "$MODE" == "nvk" ]
	then
		echo "NVK"
		export VK_DRIVER_FILES=$NVK_ICD
	else
		if [ "$MODE" == "hybrid" ]
		then
			echo "hybrid"
			export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
			if [ "$XDG_SESSION_TYPE" == 1 ]
			then
				export __NV_PRIME_RENDER_OFFLOAD=1
			fi
			export __VK_LAYER_NV_optimus=NVIDIA_only
			export __GLX_VENDOR_LIBRARY_NAME=nvidia
		else
			if [ -n "$MESA_ICD" ]
			then
				export VK_DRIVER_FILES=$MESA_ICD
			fi
			echo "integrated"
		fi
	fi
fi

# if gamescope is not present this will return an empty string
GAMESCOPE_PATH=$(command -v gamescope)
if [ "$GAMESCOPE" == "1" ] && [ ! "GAMESCOPE_PATH" == "" ]
then
	export AMD_VULKAN_ICD=RADV
	echo hud $MANGOHUD
	echo "Warning: this is still experimental"
	echo "$GAMESCOPE_PATH" -f -b "$@"
	"$GAMESCOPE_PATH" -f -b "$@"
else
	"$@"
fi
