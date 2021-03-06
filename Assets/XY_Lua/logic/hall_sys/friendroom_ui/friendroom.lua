--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

require("logic/open_room/open_room_data")


friendroom = ui_base.New()
local this = friendroom

local record_data = {}

local mGrid = nil
local mScrollView = nil
local transform
local mWrapContent 
local mWrapContentHis 
local open_roomRecordSimpleData ={}
local maxCount 
local open_roomHistorySimpleData = {}
this.gameObject=nil
function this.Show()
    hall_ui.OpenOther("firendroom") 
	if not IsNil(this.gameObject) then
		require ("logic/hall_sys/friendroom_ui/friendroom") 
		this.gameObject=newNormalUI("Prefabs/UI/Friendroom/panel_friendroom")
	else
		this.gameObject:SetActive(true) 
	end
end


function this.Hide()
    if this.gameObject==nil then
		return
	else
		GameObject.Destroy(this.gameObject)
        this.gameObject=nil
	end 
end

function this.UpdateRoomRecordSimpleData(data)
	open_roomRecordSimpleData = {}
	log("UpdateRoomRecordSimpleData")
	for i,v in ipairs(data["data"]) do
		if v ~= nil then 
			PrintTable(v)
			table.insert(open_roomRecordSimpleData,v)
		end
	end
	maxCount = table.getn(open_roomRecordSimpleData)
	this.InitPanelRecord(maxCount)
end
function this.UpdateRoomHistorySimpleData(data)
	open_roomHistorySimpleData = {}
	log("UpdateRoomHistorySimpleData")
	for i,v in ipairs(data["data"]) do
		if v ~= nil then 
			table.insert(open_roomHistorySimpleData,v)
		end
	end
	maxCount = table.getn(open_roomHistorySimpleData)
	log(maxCount.."===========")
	this.InitPanelHistory(maxCount)
	
end

function this.Start()
	this:RegistUSRelation()
   	this.RegistEvents()
   	mGrid = subComponentGet(this.transform,"Panel_group/PanelRecord/Grid","UIGrid")
   	mScrollView = subComponentGet(this.transform, "Panel_group/PanelRecord","UIScrollView")
   	mWrapContent = subComponentGet(this.transform, "Panel_group/PanelRecord/WrapContent","UIWrapContent")
   	if mWrapContent ~= nil then
   		mWrapContent.onInitializeItem = this.OnUpdateItem
   	end
   	mWrapContentHis =subComponentGet(this.transform, "Panel_group/PanelHistory/WrapContent","UIWrapContent")
   		if mWrapContentHis ~= nil then
   		mWrapContentHis.onInitializeItem = this.OnUpdateItem2
   	end

end
function this.OnUpdateItem2(go,index,realindex)
	
end

function this.RegistEvents(  )
	 local btn_getroom=child(this.transform, "btn_getroom")
    if btn_getroom~=nil then
        addClickCallbackSelf(btn_getroom.gameObject, this.OnClickOGetInRoom, this)
    end   


    local btn_joinroom=child(this.transform, "btn_joinroom")
    if btn_joinroom~=nil then
        addClickCallbackSelf(btn_joinroom.gameObject, this.OnClickOpenRoom, this)
    end   

    local btn_back = child(this.transform, "Back")
    if btn_back ~= nil then
    	addClickCallbackSelf(btn_back.gameObject, this.OnClickBack, this)
    end
    local toggleHistory = child(this.transform, "Panel_group/Title/History")
    if toggleHistory ~=nil then 
    	addClickCallbackSelf(toggleHistory.gameObject, this.OnToggleHistoryClick, this)
    end

    local toggleRecord = child(this.transform, "Panel_group/Title/record")
    if toggleRecord  ~=nil then 
    	addClickCallbackSelf(toggleRecord.gameObject, this.OnToggleRecordClick, this)
    end
end
    
function this.OnDestroy()
	this:UnRegistUSRelation()
	this.gameObject = nil
end
 
function this.OnClickOpenRoom()

	require("logic/open_room/get_in_ui")
	get_in_ui.Show() 
    
    ui_sound_mgr.PlaySoundClip("common/audio_button_click")
end

function this.OnToggleHistoryClick()
	open_room_data.RequestHistoryRecord()
    
    ui_sound_mgr.PlaySoundClip("common/audio_button_click")

end
function this.OnToggleRecordClick()
	open_room_data.RequestOpenRoomRecord()
    ui_sound_mgr.PlaySoundClip("common/audio_button_click")

end

function this.ClearItem()
	destroyAllChild(mGrid.transform)
end

function this.OnClickOGetInRoom()
	require("logic/open_room/open_room_ui")
	open_room_ui.Show() 
    
    ui_sound_mgr.PlaySoundClip("common/audio_button_click")
end

function this.OnClickBack()
	this.Hide()

end

function this.InitPanelHistory(count)
	if mWrapContentHis.transform.childCount >=6 then
		return
	end
	log("InitPanelHistory")
	if count >=0 and count <=6 then
		mWrapContentHis.enabled = false
		for i=0, count-1 do
			this.InitItem(open_roomHistorySimpleData[i+1],i,1)
		end
	else
		for a=0,5 do
			this.InitItem(open_roomHistorySimpleData[a+1],a,1)
		end
		mWrapContentHis.enabled = true
		mWrapContentHis.minIndex = -count+1
		mWrapContentHis.maxIndex = 0
	end
end

function this.InitPanelRecord(count)
	if mWrapContent.transform.childCount >=6 then
		return
	end
	log("InitPanelRecord")
	if count >=0 and count <=6 then
		mWrapContent.enabled = false
		for i=0, count-1 do
			this.InitItem(open_roomRecordSimpleData[i+1],i,2)
		end
	else
		for a=0,5 do
			this.InitItem(open_roomRecordSimpleData[a+1],a,2)
		end
		mWrapContent.enabled = true
		mWrapContent.minIndex = -count+1
		mWrapContent.maxIndex = 0
	end
end

function this.InitItem(data,i,code)
	if code ==1 then
	local tmpItem = NGUITools.AddChild(mWrapContentHis.gameObject,newNormalUI("Prefabs/UI/Friendroom/record_item"))
		  tmpItem.localPosition = Vector3.New(0,-i*82,0)
		  tmpItem.gameObject:SetActive(true)
	else
	local tmpItem = NGUITools.AddChild(mWrapContent.gameObject,newNormalUI("Prefabs/UI/Friendroom/record_item"))
		  tmpItem.localPosition = Vector3.New(0,-i*82,0)
		  tmpItem.gameObject:SetActive(true)
	end
     
end

function this.OnUpdateItem(go,index,realindex)
	log(realindex)
	if	go ~=nil then

		tmpIcon = subComponentGet(go.transform,"Icon","UISprite")
		tmpStatusSprite = subComponentGet(go.transform,"SpriteStaus","UISprite")
		tmpStatusLabel = subComponentGet(go.transform,"SpriteStaus/Label","UILabel")
		tmpRnoLabel = subComponentGet(go.transform,"LabelRno","UILabel")
		tmpLabelExpTime = subComponentGet(go.transform,"LabelExpTime","UILabel")
		tmpLabelCrtTime = subComponentGet(go.transform,"LabelCrtTime","UILabel")
		tmpHistoryInfo = child(go.transform,"HistoryInfo")
		tmpLabelGold = subComponentGet(go.transform,"tmpHistoryInfo/Label","UILabel")

	end
		local tmpData = open_roomRecordSimpleData[math.abs(realindex)+1]
		if  tmpData ~= nil then
			tmpHistoryInfo.gameObject:SetActive(false)
			tmpRnoLabel.text = string.format("房号:%d", tmpData["rno"])
			tmpLabelExpTime.text = os.date("%H:%M",math.floor(tonumber(tmpData["ctime"])))
			tmpLabelCrtTime.text = os.date("%Y-%m-%d",math.floor(tonumber(tmpData["ctime"])))
			if tmpData["status"] == 0 then
				tmpIcon.spriteName = "buddy_14"
				tmpStatusSprite.spriteName = "buddy_17"
				tmpIcon:MakePixelPerfect()
				tmpStatusLabel.color = Color.New(2/255,183/255,11/255,255/255)
				tmpStatusLabel.text = "未开始"
			elseif tmpData["status"] == 1 then
				tmpIcon.spriteName = "buddy_15"
				tmpStatusSprite.spriteName = "buddy_18"
				tmpIcon:MakePixelPerfect()
				tmpStatusLabel.color = Color.New(93/255,65/255,42/255,255/255)
				tmpStatusLabel.text = "已开局"
			else
				tmpIcon.spriteName = "buddy_16"
				tmpStatusSprite.spriteName = "buddy_19"
				tmpIcon:MakePixelPerfect()
				tmpStatusLabel.color = Color.New(152/255,124/255,103/255,255/255)
				tmpStatusLabel.text = "已结束"
			end
		end
		
	-- else
	-- 	tmpLabelGold.gameObject:SetActive(true)
	-- 	tmpHistoryInfo.gameObject:SetActive(true)
	-- 	tmpRnoLabel.gameObject:SetActive(false)
	-- 	tmpIcon.spriteName = "buddy_12"
	-- 	tmpStatusSprite.gameObject:SetActive(false)
	-- 	tmpLabelExpTime.text = os.date("%H:%M",math.floor(tonumber(tb1["ts"])))
	-- 	tmpLabelCrtTime.text = os.date("%Y-%m-%d",math.floor(tonumber(tb1["ts"])))
	-- 	tmpLabelGold.text = tb1["all_score"]
	-- end
	-- mGrid:Reposition()
end
