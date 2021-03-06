require "logic/hall_sys/openroom/comp/panel_base"
require "logic/hall_sys/openroom/comp/toggle_base" 
require "logic/hall_sys/openroom/comp/menu_base"
require "logic/hall_sys/openroom/comp/menu_base"
require "logic/game_sys/GameModel"

openroom_model = class("openroom_model")

local gameListCostPath = Application.persistentDataPath.."/games"
local gameListCostName = "gamelistcost"
local OPENROOM_CONST = 
{
	HEIGHT = 232
}

local GameModel

function openroom_model:Init()
	GameModel = GameModel

	self.costlist = nil -- PHP返回的整个结构体
	-- self.roomgame = nil -- data.gameinfo.roomgame
	-- self.gidList = nil -- 游戏列表数组
	-- self.gidMap = nil -- 游戏信息字典
	-- self.typeList = nil -- 按类型分类的二维数组openroom_model
	-- self.updateUrl = nil -- json下载地址前缀

	self.gidCostMap = nil

	-- json相关
	self.gamePanelTableList = {}
	self.clubGamePanelTableList = {}

	-- 房卡圈数相关
	self.roomCardArray = {}
	self.clubRoomCardArray = {}
	self.customRoomCardArray = {}
	self.roundsList = {}

	Notifier.regist(HttpCmdName.GetCardGameCost, self.OnResGetCardGameCost, self)
end

function openroom_model:Clear()
	Notifier.remove(HttpCmdName.GetCardGameCost, self.OnResGetCardGameCost, self)
end

function openroom_model:OnResGetCardGameCost(param)
	if param then
		if param.costlist then
			self:SaveGameListCost(param)
		else
			self:LoadGameListCost()
		end
	end
end

function openroom_model:UpdateGidCostMap()
	local list = {}
	for i,v in ipairs(self.costlist) do
		list[v.gid] = v
	end
	return list
end

function openroom_model:ReqGetCardGameCost(isForce,callback)
	local param = {}
	param.appid = global_define.appConfig.appId
	param.checksum = self:GetCheckSum(isForce)
	param.siteid = http_request_interface.GetTable().siteid
	param.clientver =  data_center.GetVerCommInfo().versionNum
	param.devicetype = tonumber(data_center.GetLoginUserInfo().deviceid)

	HttpProxy.SendGlobalRequest("/gamecost.json", HttpCmdName.GetCardGameCost, param, callback)
end

function openroom_model:SaveGameListCost(param)
	if param.costlist then
		self.costlist = param.costlist
		local context = CombinJsonStr(param)
		NetWorkManage.Instance:CreateFile(gameListCostPath,gameListCostName,context)
		self.gidCostMap = self:UpdateGidCostMap()
	end
end

function openroom_model:LoadGameListCost()
	local filePath = gameListCostPath.."/"..gameListCostName
	local isSucceed = false
	local data = openroom_model:GetlocalFileData()
	if data and data.costlist then
		self.costlist = data.costlist
		self.gidCostMap = self:UpdateGidCostMap()
		isSucceed = true
	end

	if not isSucceed then
		self:ReqGetCardGameList(true)
	end
end

function openroom_model:GetlocalFileData()
	if self.localData then
		return self.localData
	end
	local filePath = gameListCostPath.."/"..gameListCostName
	if FileReader.IsFileExists(filePath) then
		local context = FileReader.ReadFile(filePath)
		if context then
			local data = ParseJsonStr(context)
			if data then
				self.localData = data
				return data
			end
		end
	end
end

function openroom_model:GetOpenRoomClubList()
	local clubModel = ClubModel
	local clubList = {}
	for i,v in ipairs(clubModel.clubList) do
		if v.ctype == 1 then
			local data = v
			data.cname = "大厅"
			table.insert(clubList,1,data)
		else
			table.insert(clubList,v)
		end
	end
	return clubList
end

function openroom_model:GetCheckSum(isForce)
	if isForce then
		return nil
	end
	local data = openroom_model:GetlocalFileData()
	if data and data.checksum then
		return data.checksum
	end
end

--[[--
 * @Description: 返回PHP配置房卡数
 ]]
function openroom_model:GetRoomCardValue(gid,pnum,round,costTypes,isClub)
	local config = self:GetRoomCardArrayByNum(gid,pnum,isClub,costTypes)
	for _,v in ipairs(config or {}) do
		if tonumber(v.round) == tonumber(round) then
			if costTypes == 0 then
				return v.roomhost
			elseif costTypes == 1 then
				return v.AA
			elseif costTypes == 2 then
				return v.winner
			elseif costTypes == 3 then -- TODO
				return v.roomhost
			else
				logError(costTypes)
			end
	 	end
	end 
end

--[[--
 * @Description: 返回自定义配置房卡数
 ]]
function openroom_model:GetCustomRoomCardValue(gid,pnum,round,costTypes)
	local roomCardArray
	local model = model_manager:GetModel("ClubModel") 
	local cid = model.currentClubInfo.cid
	if self.customRoomCardArray[cid] == nil then
		self.customRoomCardArray[cid] = {}
	end
	if self.customRoomCardArray[cid][gid] == nil then
		local costcfg = model.currentClubInfo.costcfg or {}
		local nomal = costcfg[tostring(gid)]

		if nomal == nil then
			return 
		end
		roomCardArray = self:AnalyzeRoomCardArray(nomal)

		self.customRoomCardArray[cid][gid] = roomCardArray
	else
		roomCardArray = self.customRoomCardArray[cid][gid]
	end

	local config
	if roomCardArray then
		if roomCardArray[tostring(pnum)] then
			config = roomCardArray[tostring(pnum)]
		elseif roomCardArray[tonumber(pnum)] then
			config = roomCardArray[tonumber(pnum)]
		elseif roomCardArray[tostring(0)] then
			config = roomCardArray[tostring(0)]
		elseif roomCardArray[0] then
			config = roomCardArray[0]
		else
			logError(gid,pnum,isClub,GetTblData(roomCardArray))
		end
	end

	for _,v in ipairs(config or {}) do
		if tonumber(v.round) == tonumber(round) then
			if costTypes == 0 then
				return v.roomhost
			elseif costTypes == 1 then
				return v.AA
			elseif costTypes == 2 then
				return v.winner
			elseif costTypes == 3 then -- TODO
				return v.roomhost
			else
				logError(costTypes)
			end
	 	end
	end 
end

--[[--
 * @Description: 获取开房界面table  
 ]]
function openroom_model:GetPanelTableByGid(gid,isClub)
	local panelTable

	-- 读缓存
	if isClub then
		panelTable = self.clubGamePanelTableList[gid]
	else
		panelTable = self.gamePanelTableList[gid]
	end
	if panelTable then
		return panelTable
	end

	-- 读持久化
	if panelTable == nil then
		local prefs_str
		if isClub then
		 	prefs_str = global_define.ClubCreateRoomPlayerPrefs
		else
			prefs_str = global_define.CreateRoomPlayerPrefs
		end

		if PlayerPrefs.HasKey(prefs_str..gid) then
	        local str = PlayerPrefs.GetString(prefs_str..gid)  
	        if str ~= nil then
		        str = string.gsub(str,"'"," ")
		        local t = ParseJsonStr(str)
		        panelTable = {}
		        for k,v in pairs(t) do 
		            panelTable[k]=v
		        end
		        --return panelTable
		    end
	    end
	end

	-- 读配置
	if panelTable == nil then
	    panelTable = self:LoadPanelTable(gid,isClub)
	end

	if panelTable then
	    if isClub then
	    	self.clubGamePanelTableList[gid] = panelTable
	    else
	    	self.gamePanelTableList[gid] = panelTable
	    end
	end
	return panelTable
end

function openroom_model:LoadPanelTable(gid,isClub)
	local panelTable = nil
	local roomConfData = self:ReadJsonByGid(gid)
	if roomConfData and type(roomConfData) == "table" and table.getn(roomConfData) > 0 then
		panelTable = self:AnalyzeJson(roomConfData,gid,isClub)
	end
	return panelTable
end

function openroom_model:ReadJsonByGid(gid)
	local cfgData
	local str = FileReader.ReadFile(global_define.appConfig.jsonurl.."/"..GameModel:GetJsonName(gid))
  	if nil ~= str and "" ~= str then
    	cfgData = ParseJsonStr(str)
  	else
    	logError("json文件不存在，"..GameModel:GetJsonName(gid))
    	GameModel:CheckJsonLegal()
  	end
  	return cfgData
end

function openroom_model:AnalyzeJson(roomConfData,gid,isClub)
	local panelTable = {}
	for i=1,#roomConfData do
       local panel = panel_base.New()
       local tables=roomConfData[i][1]
       panel.title=tables.title
       --panel.height=-100
       --panel.itemWidth=200 
       panel.id=tables.id
       panel.selectIndex=tables.selectIndex 
       --if tables.itemWidth~=nil then
       panel.itemWidth=tables.itemWidth or OPENROOM_CONST.HEIGHT
       --end
       -- if tables.itemHeight~=nil then
       --    panel.height=tables.itemHeight
       -- end
       -- if tables.distance~=nil then
       --    panel.itemHeight=tables.distance
       -- end
	   panel.tipsList = tables["tipsList"]
       if tables.maxPerLine~=nil then
          panel.maxperLine=tables.maxPerLine
       end
       if tables.type~=nil then
          panel.type=tables.type
       end 

       if tables.type==0 or tables.type==1 then 
            for m=1,#tables.data do
                local tt=toggle_base.New()
                tt.text=tables.data[m]
                tt.type=tables.type
                tt.Group=tables.group
                if tables.exData~=nil then
                    tt.exData=tables.exData[m] 
                end
                if tables.type==0 then
                    tt.selectIndex=tables.id[m]
                else
                	if type(tables.id) ~= "table" then
                    	tt.selectIndex=tables.id
                    else
                    	tt.selectIndex=tables.id[m]
                    end
                end   
                if tables.iosdata~=nil then 
                   tt.iosdata=tables.iosdata[m]
                end
                if tables.connecttype~=nil then 
                    tt.connecttype=tables.connecttype  
                    for s=1,#tables.connect do  
                       local ctable=tables.connect[s]
                       local vtable=tables.Isconnect[s]
                       if ctable[tt.selectIndex]~=nil then  
                          table.insert(tt.connect,ctable[tt.selectIndex])   
                          table.insert(tt.isconnect,vtable[tt.selectIndex]) 
                          if tables.iosconnect~=nil then 
                            local itable=tables.iosconnect[s]
                            table.insert(tt.iosconnect,itable[tt.selectIndex]) 
                          end
                       end 
                       if ctable[tostring(tt.exData)]~=nil then   
                          table.insert(tt.connect,ctable[tostring(tt.exData)])  
                          table.insert(tt.isconnect,vtable[tostring(tt.exData)])   
                          if tables.iosconnect~=nil and tables.iosconnect[s]~=nil then 
                            local itable=tables.iosconnect[s]
                            table.insert(tt.iosconnect,itable[tostring(tt.exData)]) 
                          end
                       end  
                    end 
                   panel.connect=1  
                end 

                -- 添加 房卡刷新
             --    if tt.selectIndex == "pnum" then
             --    	if tt.connecttype == nil then
             --    		tt.connecttype = {}
             --    	end
	            --     table.insert(tt.connecttype,2)
	            --     table.insert(tt.connect,{{rounds = self:GetPHPRoomCardConfig(gid,tt.exData,isClub)}})
	            --     table.insert(tt.isconnect,{})
	            -- end

	            if tt.selectIndex == "rounds" then
	            	local _,roundsList
	            	if isClub then
	            		_,roundsList = self:GetClubRoomCardArray(gid)
	            	else
	            		_,roundsList = self:GetRoomCardArray(gid)
	            	end
	            	if roundsList and roundsList[m] then
	            		tt.exData = roundsList[m]
	            		if roundsList[m] == 0 then
	            			tt.text = "打课"
	            		else
	            			tt.text = roundsList[m].."局"
	            		end
	            	else
	            		logError("更新 配置 圈数 错误",gid,m,GetTblData(roundsList))
	            	end
	            end

                table.insert(panel.ToggleTable,tt)
            end
       end
       if tables.type==2 then
          local tt=menu_base.New()
          tt.type=tables.type
          tt.Group=tables.group
          tt.text=tables.data
          tt.selectIndex=tables.id 
          tt.itemWidth = tables.itemWidth
          tt.maxPerLine = tables.maxPerLine
          tt.id=tables.id
          if tables.exData~=nil then
             tt.exData=tables.exData 
          end
          table.insert(panel.ToggleTable,tt)
          panel.connect=1
       end
       table.insert(panelTable,panel)
   end  
   return panelTable
end

function openroom_model:GetCostByGid(gid)
	if self.gidCostMap then
		if self.gidCostMap[gid] then
			return self.gidCostMap[gid]
		end
	end
	return {}
end

function openroom_model:GetRoomCardArray(gid)
	if self.roomCardArray[gid] == nil then
		local data = self:GetCostByGid(gid)
		local costcfg = data.costcfg or {}
		local officer = costcfg.officer or {}

		local roomCard,roundsList = self:AnalyzeRoomCardArray(officer)

		self.roomCardArray[gid] = roomCard
		self.roundsList[gid] = roundsList
	end

	return self.roomCardArray[gid],self.roundsList[gid]
end

function openroom_model:GetClubRoomCardArray(gid)
	if self.clubRoomCardArray[gid] == nil then
		local data = self:GetCostByGid(gid)
		local costcfg = data.costcfg or {}
		local nomal = costcfg.nomal or {}

		local roomCard,roundsList = self:AnalyzeRoomCardArray(nomal)

		self.clubRoomCardArray[gid] = roomCard
		self.roundsList[gid] = roundsList
	end

	return self.clubRoomCardArray[gid],self.roundsList[gid]
end

function openroom_model:AnalyzeRoomCardArray(addtional)
	local roomCardArray = {}
	for _,v in ipairs(addtional) do
		if roomCardArray[v.pnum] == nil then
			roomCardArray[v.pnum] = {}
		end
		table.insert(roomCardArray[v.pnum],{round = v.round,roomhost = v.roomhost,AA = v.AA,winner = v.winner,clubhost = v.roomhost})
	end

	if roomCardArray["0"] then
		for _,zeroArr in ipairs(roomCardArray["0"]) do
			for k,pnumArr in pairs(roomCardArray) do
				if k~="0" then
					local needAdd = true
					for _,v in ipairs(pnumArr) do
						if v.round == zeroArr.round then
							needAdd = false
							break
						end
					end
					if needAdd then
						table.insert(pnumArr,{round = zeroArr.round,roomhost = v.roomhost,AA = v.AA,winner = v.winner,clubhost = v.roomhost})
					end
				end
			end
		end
	end

	local roundsList = nil
	for _,pnumArr in pairs(roomCardArray) do
		table.sort(pnumArr, function (a, b)
  			return ((tonumber(a.round) < tonumber(b.round)) and tonumber(a.round)~=0) or tonumber(b.round)==0
  		end)
  		if roundsList == nil then
  			roundsList = {}
  			for _,v in ipairs(pnumArr) do
  				table.insert(roundsList,tonumber(v.round))
  			end
  		end
	end
	return roomCardArray,roundsList
end

-- function openroom_model:GetPHPRoomCardConfig(gid,pnum,isClub)
-- 	local rounds = {}
-- 	for i=0,2 do
-- 		local config = {}
-- 		for _,v in ipairs(self:GetRoomCardArrayByNum(gid,pnum,isClub,i) or {}) do
-- 			if v.round == "0" then
-- 				table.insert(config,"打课(x"..v.cost..")")
-- 			else
-- 		 		table.insert(config,v.round.."局(x"..v.cost..")")
-- 		 	end
-- 		end 
-- 		rounds[i] = config
-- 	end
-- 	return rounds[0]
-- end

function openroom_model:GetRoomCardArrayByNum(gid,pnum,isClub,costType)
	local roomCardArray
	if isClub then
		roomCardArray = self:GetClubRoomCardArray(gid)
	else
		roomCardArray = self:GetRoomCardArray(gid)
	end

	if roomCardArray then
		if roomCardArray[tostring(pnum)] then
			return roomCardArray[tostring(pnum)]
		elseif roomCardArray[tostring(0)] then
			return roomCardArray[tostring(0)]
		else
			logError(gid,pnum,isClub,GetTblData(roomCardArray))
		end
	end
end

return openroom_model
