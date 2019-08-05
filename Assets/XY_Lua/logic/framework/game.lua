--[[--
 * @Description: main会调用过来
 * @Author:      shine
 * @FileName:    game.lua
 * @DateTime:    2017-05-16 11:50:39
 ]]

require "logic/framework/luaclass"
require "common/functions"
require "logic/game_state/gs_mgr"
require "logic/framework/msg_dispatch_mgr"

--管理器--
GameManager = {}
local this = GameManager

local testScene = nil

--[[--
 * @Description: lua的逻辑入口  
 * @param:       testSceneflag    是否为测试场景方式运行
                 sceneTypeString  场景类型
                 levelID          场景ID
 ]]
function this.OnInitOK(testSceneflag, sceneTypeString, levelID)
	this.InitModules()	
	print("------------------------------------OnInitOK")
	if (not testSceneflag) then
		game_scene.gotoLogin()
	else
		TestMode.SetSingleMode(true)
		TestMode.SetDirectSceneTestFlag()
		testScene(sceneTypeString, levelID)
	end
	config_data_center.PreLoadConfigData()
end

--[[--
 * @Description: 初始化各个模块  
 ]]
function this.InitModules( )
	require "logic/common_ui/ui_sound_mgr"

	gs_mgr.InitGameStates()
	Time:SetTimeScale(1)
	--TestMode.Initialize()
	map_controller.Initialize()	--map
	game_scene.init()
	
	ui_sound_mgr.Init()	

	msg_dispatch_mgr.Init()
	--[[local verInfo = VersionInfoData.CurrentVersionInfo
	if verInfo ~= nil then
		if not verInfo.IsReleaseVer then
			newResidentMemoryUI("Prefabs/UI/debugui")
		end
	end]]
end

--[[--
 * @Description: 反初始化各个模块  
 ]]
function this.UnInitModules()
	gs_mgr.UninitGameStates()
	game_scene.unInit()
	ui_sound_mgr.UnInit()	
end

--[[--
 * @Description: 直接测试运行某场景  
 ]]
function testScene(sceneTypeString, levelID)
	game_scene.EnterSceneForTest(sceneTypeString, levelID)
end
