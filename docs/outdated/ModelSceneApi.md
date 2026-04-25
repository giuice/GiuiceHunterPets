# Model Scene Frame Documentation

```lua
local FrameAPIModelSceneFrame =
{
	Name = "FrameAPIModelSceneFrame",
	Type = "ScriptObject",

	Functions =
	{
		{
			Name = "ClearFog",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "CreateActor",
			Type = "Function",

			Arguments =
			{
				{ Name = "name", Type = "cstring", Nilable = false },
				{ Name = "template", Type = "cstring", Nilable = false },
			},
		},
		{
			Name = "GetActorAtIndex",
			Type = "Function",

			Arguments =
			{
				{ Name = "index", Type = "luaIndex", Nilable = false },
			},
		},
		{
			Name = "GetCameraFarClip",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "farClip", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraFieldOfView",
			Type = "Function",
			Documentation = { "Field of view in radians" },

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "fov", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraForward",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "forwardX", Type = "number", Nilable = false },
				{ Name = "forwardY", Type = "number", Nilable = false },
				{ Name = "forwardZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraNearClip",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "nearClip", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraPosition",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraRight",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "rightX", Type = "number", Nilable = false },
				{ Name = "rightY", Type = "number", Nilable = false },
				{ Name = "rightZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetCameraUp",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "upX", Type = "number", Nilable = false },
				{ Name = "upY", Type = "number", Nilable = false },
				{ Name = "upZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetDrawLayer",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "layer", Type = "DrawLayer", Nilable = false },
				{ Name = "sublevel", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetFogColor",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetFogFar",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "far", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetFogNear",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "near", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetLightAmbientColor",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetLightDiffuseColor",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetLightDirection",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "directionX", Type = "number", Nilable = false },
				{ Name = "directionY", Type = "number", Nilable = false },
				{ Name = "directionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetLightPosition",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetLightType",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "lightType", Type = "ModelLightType", Nilable = true },
			},
		},
		{
			Name = "GetNumActors",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "numActors", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetViewInsets",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "insets", Type = "uiRect", Nilable = false },
			},
		},
		{
			Name = "GetViewTranslation",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "translationX", Type = "number", Nilable = false },
				{ Name = "translationY", Type = "number", Nilable = false },
			},
		},
		{
			Name = "IsLightVisible",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "isVisible", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "Project3DPointTo2D",
			Type = "Function",

			Arguments =
			{
				{ Name = "pointX", Type = "number", Nilable = false },
				{ Name = "pointY", Type = "number", Nilable = false },
				{ Name = "pointZ", Type = "number", Nilable = false },
			},

			Returns =
			{
				{ Name = "point2DX", Type = "number", Nilable = false },
				{ Name = "point2DY", Type = "number", Nilable = false },
				{ Name = "depth", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraFarClip",
			Type = "Function",

			Arguments =
			{
				{ Name = "farClip", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraFieldOfView",
			Type = "Function",
			Documentation = { "Field of view in radians" },

			Arguments =
			{
				{ Name = "fov", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraNearClip",
			Type = "Function",

			Arguments =
			{
				{ Name = "nearClip", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraOrientationByAxisVectors",
			Type = "Function",

			Arguments =
			{
				{ Name = "forwardX", Type = "number", Nilable = false },
				{ Name = "forwardY", Type = "number", Nilable = false },
				{ Name = "forwardZ", Type = "number", Nilable = false },
				{ Name = "rightX", Type = "number", Nilable = false },
				{ Name = "rightY", Type = "number", Nilable = false },
				{ Name = "rightZ", Type = "number", Nilable = false },
				{ Name = "upX", Type = "number", Nilable = false },
				{ Name = "upY", Type = "number", Nilable = false },
				{ Name = "upZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraOrientationByYawPitchRoll",
			Type = "Function",

			Arguments =
			{
				{ Name = "yaw", Type = "number", Nilable = false },
				{ Name = "pitch", Type = "number", Nilable = false },
				{ Name = "roll", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraPosition",
			Type = "Function",

			Arguments =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetDesaturation",
			Type = "Function",

			Arguments =
			{
				{ Name = "strength", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetDrawLayer",
			Type = "Function",

			Arguments =
			{
				{ Name = "layer", Type = "DrawLayer", Nilable = false },
			},
		},
		{
			Name = "SetFogColor",
			Type = "Function",

			Arguments =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetFogFar",
			Type = "Function",

			Arguments =
			{
				{ Name = "far", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetFogNear",
			Type = "Function",

			Arguments =
			{
				{ Name = "near", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetLightAmbientColor",
			Type = "Function",

			Arguments =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetLightDiffuseColor",
			Type = "Function",

			Arguments =
			{
				{ Name = "colorR", Type = "number", Nilable = false },
				{ Name = "colorG", Type = "number", Nilable = false },
				{ Name = "colorB", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetLightDirection",
			Type = "Function",

			Arguments =
			{
				{ Name = "directionX", Type = "number", Nilable = false },
				{ Name = "directionY", Type = "number", Nilable = false },
				{ Name = "directionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetLightPosition",
			Type = "Function",

			Arguments =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetLightType",
			Type = "Function",

			Arguments =
			{
				{ Name = "lightType", Type = "ModelLightType", Nilable = false },
			},
		},
		{
			Name = "SetLightVisible",
			Type = "Function",

			Arguments =
			{
				{ Name = "visible", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetPaused",
			Type = "Function",

			Arguments =
			{
				{ Name = "paused", Type = "bool", Nilable = false },
				{ Name = "affectsGlobalPause", Type = "bool", Nilable = false, Default = true },
			},
		},
		{
			Name = "SetViewInsets",
			Type = "Function",

			Arguments =
			{
				{ Name = "insets", Type = "uiRect", Nilable = false },
			},
		},
		{
			Name = "SetViewTranslation",
			Type = "Function",

			Arguments =
			{
				{ Name = "translationX", Type = "number", Nilable = false },
				{ Name = "translationY", Type = "number", Nilable = false },
			},
		},
		{
			Name = "TakeActor",
			Type = "Function",

			Arguments =
			{
			},
		},
	},

	Events =
	{
	},

	Tables =
	{
	},
};


local FrameAPIModelSceneFrameActorBase =
{
	Name = "FrameAPIModelSceneFrameActorBase",
	Type = "ScriptObject",

	Functions =
	{
		{
			Name = "ClearModel",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "GetActiveBoundingBox",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "boxBottom", Type = "vector3", Mixin = "Vector3DMixin", Nilable = false },
				{ Name = "boxTop", Type = "vector3", Mixin = "Vector3DMixin", Nilable = false },
			},
		},
		{
			Name = "GetAlpha",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "alpha", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetAnimation",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "animation", Type = "AnimationDataEnum", Nilable = false },
			},
		},
		{
			Name = "GetAnimationBlendOperation",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "blendOp", Type = "ModelBlendOperation", Nilable = false },
			},
		},
		{
			Name = "GetAnimationVariation",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "variation", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetDesaturation",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "strength", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetMaxBoundingBox",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "boxBottom", Type = "vector3", Mixin = "Vector3DMixin", Nilable = false },
				{ Name = "boxTop", Type = "vector3", Mixin = "Vector3DMixin", Nilable = false },
			},
		},
		{
			Name = "GetModelFileID",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "file", Type = "fileID", Nilable = false },
			},
		},
		{
			Name = "GetModelPath",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "path", Type = "string", Nilable = false },
			},
		},
		{
			Name = "GetModelUnitGUID",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "guid", Type = "WOWGUID", Nilable = false },
			},
		},
		{
			Name = "GetParticleOverrideScale",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "scale", Type = "number", Nilable = true },
			},
		},
		{
			Name = "GetPitch",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "pitch", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetPosition",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetRoll",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "roll", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetScale",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "scale", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetSpellVisualKit",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "spellVisualKitID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "GetYaw",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "yaw", Type = "number", Nilable = false },
			},
		},
		{
			Name = "Hide",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "IsLoaded",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "isLoaded", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "IsShown",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "isShown", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "IsUsingCenterForOrigin",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "x", Type = "bool", Nilable = false },
				{ Name = "y", Type = "bool", Nilable = false },
				{ Name = "z", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "IsVisible",
			Type = "Function",

			Arguments =
			{
			},

			Returns =
			{
				{ Name = "isVisible", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "PlayAnimationKit",
			Type = "Function",

			Arguments =
			{
				{ Name = "animationKit", Type = "number", Nilable = false },
				{ Name = "isLooping", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetAlpha",
			Type = "Function",

			Arguments =
			{
				{ Name = "alpha", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetAnimation",
			Type = "Function",

			Arguments =
			{
				{ Name = "animation", Type = "AnimationDataEnum", Nilable = false },
				{ Name = "variation", Type = "number", Nilable = true },
				{ Name = "animSpeed", Type = "number", Nilable = false, Default = 1 },
				{ Name = "animOffsetSeconds", Type = "number", Nilable = false, Default = 0 },
			},
		},
		{
			Name = "SetAnimationBlendOperation",
			Type = "Function",

			Arguments =
			{
				{ Name = "blendOp", Type = "ModelBlendOperation", Nilable = false },
			},
		},
		{
			Name = "SetDesaturation",
			Type = "Function",

			Arguments =
			{
				{ Name = "strength", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetModelByCreatureDisplayID",
			Type = "Function",

			Arguments =
			{
				{ Name = "creatureDisplayID", Type = "number", Nilable = false },
				{ Name = "useActivePlayerCustomizations", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "success", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "SetModelByFileID",
			Type = "Function",

			Arguments =
			{
				{ Name = "asset", Type = "FileAsset", Nilable = false },
				{ Name = "useMips", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "success", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "SetModelByPath",
			Type = "Function",

			Arguments =
			{
				{ Name = "asset", Type = "FileAsset", Nilable = false },
				{ Name = "useMips", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "success", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "SetModelByUnit",
			Type = "Function",

			Arguments =
			{
				{ Name = "unit", Type = "UnitToken", Nilable = false },
				{ Name = "sheatheWeapons", Type = "bool", Nilable = false, Default = false },
				{ Name = "autoDress", Type = "bool", Nilable = false, Default = true },
				{ Name = "hideWeapons", Type = "bool", Nilable = false, Default = false },
				{ Name = "usePlayerNativeForm", Type = "bool", Nilable = false, Default = true },
				{ Name = "holdBowString", Type = "bool", Nilable = false, Default = false },
			},

			Returns =
			{
				{ Name = "success", Type = "bool", Nilable = false },
			},
		},
		{
			Name = "SetParticleOverrideScale",
			Type = "Function",

			Arguments =
			{
				{ Name = "scale", Type = "number", Nilable = true },
			},
		},
		{
			Name = "SetPitch",
			Type = "Function",

			Arguments =
			{
				{ Name = "pitch", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetPosition",
			Type = "Function",

			Arguments =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetRoll",
			Type = "Function",

			Arguments =
			{
				{ Name = "roll", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetScale",
			Type = "Function",

			Arguments =
			{
				{ Name = "scale", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetShown",
			Type = "Function",

			Arguments =
			{
				{ Name = "show", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetSpellVisualKit",
			Type = "Function",

			Arguments =
			{
				{ Name = "spellVisualKitID", Type = "number", Nilable = false, Default = 0 },
				{ Name = "oneShot", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetUseCenterForOrigin",
			Type = "Function",

			Arguments =
			{
				{ Name = "x", Type = "bool", Nilable = false, Default = false },
				{ Name = "y", Type = "bool", Nilable = false, Default = false },
				{ Name = "z", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetYaw",
			Type = "Function",

			Arguments =
			{
				{ Name = "yaw", Type = "number", Nilable = false },
			},
		},
		{
			Name = "Show",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "StopAnimationKit",
			Type = "Function",

			Arguments =
			{
			},
		},
	},

	Events =
	{
	},

	Tables =
	{
	},
};
local FrameAPICinematicModel =
{
	Name = "FrameAPICinematicModel",
	Type = "ScriptObject",

	Functions =
	{
		{
			Name = "EquipItem",
			Type = "Function",

			Arguments =
			{
				{ Name = "itemID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "InitializeCamera",
			Type = "Function",

			Arguments =
			{
				{ Name = "scaleFactor", Type = "number", Nilable = false, Default = 0 },
			},
		},
		{
			Name = "InitializePanCamera",
			Type = "Function",

			Arguments =
			{
				{ Name = "scaleFactor", Type = "number", Nilable = false, Default = 0 },
			},
		},
		{
			Name = "RefreshCamera",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "SetAnimOffset",
			Type = "Function",

			Arguments =
			{
				{ Name = "offset", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraPosition",
			Type = "Function",

			Arguments =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCameraTarget",
			Type = "Function",

			Arguments =
			{
				{ Name = "positionX", Type = "number", Nilable = false },
				{ Name = "positionY", Type = "number", Nilable = false },
				{ Name = "positionZ", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetCreatureData",
			Type = "Function",

			Arguments =
			{
				{ Name = "creatureID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetFacingLeft",
			Type = "Function",

			Arguments =
			{
				{ Name = "isFacingLeft", Type = "bool", Nilable = false, Default = false },
			},
		},
		{
			Name = "SetFadeTimes",
			Type = "Function",

			Arguments =
			{
				{ Name = "fadeInSeconds", Type = "number", Nilable = false },
				{ Name = "fadeOutSeconds", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetHeightFactor",
			Type = "Function",

			Arguments =
			{
				{ Name = "factor", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetJumpInfo",
			Type = "Function",

			Arguments =
			{
				{ Name = "jumpLength", Type = "number", Nilable = false },
				{ Name = "jumpHeight", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetPanDistance",
			Type = "Function",

			Arguments =
			{
				{ Name = "scale", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetSpellVisualKit",
			Type = "Function",

			Arguments =
			{
				{ Name = "visualKitID", Type = "number", Nilable = false },
			},
		},
		{
			Name = "SetTargetDistance",
			Type = "Function",

			Arguments =
			{
				{ Name = "scale", Type = "number", Nilable = false },
			},
		},
		{
			Name = "StartPan",
			Type = "Function",

			Arguments =
			{
				{ Name = "panType", Type = "luaIndex", Nilable = false },
				{ Name = "durationSeconds", Type = "number", Nilable = false },
				{ Name = "doFade", Type = "bool", Nilable = false, Default = false },
				{ Name = "visKitID", Type = "number", Nilable = false, Default = 0 },
				{ Name = "startPositionScale", Type = "number", Nilable = false, Default = 0 },
				{ Name = "speedMultiplier", Type = "number", Nilable = false, Default = 1 },
			},
		},
		{
			Name = "StopPan",
			Type = "Function",

			Arguments =
			{
			},
		},
		{
			Name = "UnequipItems",
			Type = "Function",

			Arguments =
			{
			},
		},
	},

	Events =
	{
	},

	Tables =
	{
	},
};



```