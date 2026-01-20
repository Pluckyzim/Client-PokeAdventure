-- local OPCODE = 10
bottombarWindow = nil

backgroundLife = nil
backgroundLevel = nil
backgroundFish = nil
backgroundSpeed = nil
experienceTooltip = 'You have %d%% to advance to level %d.'

-- Estilos dos slots quando vazios, iguais ao game_inventory
local BottomInventorySlotStyles = {
  [InventorySlotLeg] = 'LegSlot',
  [InventorySlotNeck] = 'NeckSlot',
  [InventorySlotExt2] = 'OrderSlot'
}

local function getOrderItem(player)
  if not player then return nil end
  local item = player:getInventoryItem(InventorySlotExt2)
  if item then return item end
  -- Fallback: alguns clientes usam Finger como ORDER
  return player:getInventoryItem(InventorySlotFinger)
end

function init()
  bottombarWindow = g_ui.loadUI('bottombar', modules.game_interface.getBottomActionPanel())
  
  connect(LocalPlayer, { 
	onHealthChange = onHealthChange,
    onExperienceChange = onExperienceChange,
	onLevelChange = onLevelChange,
    onStaminaChange = onStaminaChange,
    onSkillChange = onSkillChange,
    onSpeedChange = onSpeedChange,
    onInventoryChange = onInventoryChangeBottomSlots,
    onBlessingsChange = onBlessingsChangeBottomSlots,
  })
  connect(g_game, {
  	onGameStart = online,
  	onGameEnd = offline,
  })
	
  backgroundInfos = bottombarWindow.backgroundInfos
  
  backgroundLife = backgroundInfos.backgroundLife
  backgroundLevel = backgroundInfos.backgroundLevel
  backgroundFish = backgroundInfos.backgroundFish
  backgroundSpeed = backgroundInfos.backgroundSpeed
  
  slotDex = bottombarWindow.slotDex
  slotFish = bottombarWindow.slotFish
  slotOrder = bottombarWindow.slotOrder
  
  if g_game.isOnline() then
    local player = g_game.getLocalPlayer()
    onHealthChange(player, player:getHealth(), player:getMaxHealth())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
    onExperienceChange(player, player:getExperience())
	onStaminaChange(player, player:getStamina())
    onSpeedChange(player, player:getSpeed())
	
    local hasAdditionalSkills = g_game.getFeature(GameAdditionalSkills)
    for i = Skill.Fist, Skill.ManaLeechAmount do
	  if i == Skill.Fishing then
		onSkillChange(player, i, player:getSkillLevel(i), player:getSkillLevelPercent(i))
	  end
    end
  end
end

function online()
  local player = g_game.getLocalPlayer()
  -- Não sobrescrever o comportamento: deixar igual ao inventário

  -- Estado inicial dos slots conforme inventário
  if player then
    updateBottomSlotFromInventory(player, InventorySlotLeg, slotDex)
    updateBottomSlotFromInventory(player, InventorySlotNeck, slotFish)
    local orderItem = getOrderItem(player)
    if orderItem then
      slotOrder:setStyle('InventoryItem')
      slotOrder:setItem(orderItem)
    else
      slotOrder:setStyle(BottomInventorySlotStyles[InventorySlotExt2])
      slotOrder:setItem(nil)
    end

    -- Estilo Adventurer (On) igual ao inventário
    local hasAdventurerBlessing = Bit.hasBit(player:getBlessings(), Blessings.Adventurer)
    if slotDex then slotDex:setOn(hasAdventurerBlessing) end
    if slotFish then slotFish:setOn(hasAdventurerBlessing) end
    if slotOrder then slotOrder:setOn(hasAdventurerBlessing) end
  end
end
function offline()
end

-- Atualiza visual de um slot da bottombar
-- Atualiza um slot aplicando estilos iguais ao inventário
function updateBottomSlotFromInventory(player, slotConst, widget)
  if not widget or not player then return end
  local item = player:getInventoryItem(slotConst)
  if item then
    widget:setStyle('InventoryItem')
    widget:setItem(item)
  else
    widget:setStyle(BottomInventorySlotStyles[slotConst])
    widget:setItem(nil)
  end
end

-- Listener de mudanças de inventário para atualizar slots da bottombar
function onInventoryChangeBottomSlots(localPlayer, slot, item, oldItem)
  if not bottombarWindow then return end
  if slot == InventorySlotLeg then
    updateBottomSlotFromInventory(localPlayer, InventorySlotLeg, slotDex)
  elseif slot == InventorySlotNeck then
    updateBottomSlotFromInventory(localPlayer, InventorySlotNeck, slotFish)
  elseif slot == InventorySlotExt2 or slot == InventorySlotFinger then
    local orderItem = getOrderItem(localPlayer)
    if orderItem then
      slotOrder:setStyle('InventoryItem')
      slotOrder:setItem(orderItem)
    else
      slotOrder:setStyle(BottomInventorySlotStyles[InventorySlotExt2])
      slotOrder:setItem(nil)
    end
  end
end

-- Replica o comportamento de alternar o estilo Adventurer no inventário
function onBlessingsChangeBottomSlots(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if slotDex then slotDex:setOn(hasAdventurerBlessing) end
  if slotFish then slotFish:setOn(hasAdventurerBlessing) end
  if slotOrder then slotOrder:setOn(hasAdventurerBlessing) end
end

  function toggleOrder()
	currentSlot = 1 -- Slot da mão direita (mais provável de ter um item)
	if not currentSlot or currentSlot <= 0 then
		currentSlot = 1
	end
	modules.game_textmessage.displayGameMessage("Clique em um item ou criatura para usar com o item da mão direita.")
	startChooseItem(onClickWithMouse)
end

function startChooseItem(releaseCallback)
	if g_ui.isMouseGrabbed() then return end
	if not releaseCallback then
		error("No mouse release callback parameter set.")
	end
	local mouseGrabberWidget = g_ui.createWidget('UIWidget')
	mouseGrabberWidget:setVisible(false)
	mouseGrabberWidget:setFocusable(false)

	connect(mouseGrabberWidget, { onMouseRelease = releaseCallback })

	mouseGrabberWidget:grabMouse()
	g_mouse.pushCursor('target')
end

function onClickWithMouse(self, mousePosition, mouseButton)
	-- Safety check for currentSlot
	if not currentSlot or currentSlot <= 0 or currentSlot > 20 then
		modules.game_textmessage.displayFailureMessage("Slot de inventário inválido: " .. tostring(currentSlot))
		g_mouse.popCursor('target')
		self:ungrabMouse()
		return false
	end
	
	local item = nil
	if mouseButton == MouseLeftButton then
		local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
		if clickedWidget then
			if clickedWidget:getClassName() == 'UIGameMap' then
				local tile = clickedWidget:getTile(mousePosition)
				if tile then
					if currentSlot == 1 then
						item = tile:getGround()
					else
						local thing = tile:getTopMoveThing()
						if thing and thing:isItem() then
							item = thing
						else
							item = tile:getTopCreature()
						end
					end
				end
			elseif clickedWidget:getClassName() == 'UICreatureButton' then
				item = clickedWidget:getCreature()
			end
		end
	elseif mouseButton == MouseMidButton then
		local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
		if clickedWidget then
			if clickedWidget:getClassName() == 'UIGameMap' then
				local tile = clickedWidget:getTile(mousePosition)
				if tile then
					if currentSlot == 1 then
						item = tile:getGround()
					else
						local thing = tile:getTopMoveThing()
						if thing and thing:isItem() then
							item = thing
						else
							item = tile:getTopCreature()
						end
					end
				end
			elseif clickedWidget:getClassName() == 'UICreatureButton' then
				item = clickedWidget:getCreature()
			end
		end
	end

	if item then
		local player = g_game.getLocalPlayer()
		if player then
			if currentSlot and currentSlot > 0 and currentSlot <= 20 then
				local inventoryItem = player:getInventoryItem(currentSlot)
				if inventoryItem then
					g_game.useInventoryItemWith(inventoryItem:getId(), item)
				else
					modules.game_textmessage.displayFailureMessage("Nenhum item equipado no slot " .. currentSlot .. "!")
				end
			else
				modules.game_textmessage.displayFailureMessage("Slot inválido: " .. tostring(currentSlot))
			end
		else
			modules.game_textmessage.displayFailureMessage("Jogador não encontrado!")
		end
	else
		modules.game_textmessage.displayFailureMessage("Nenhum item ou criatura selecionada!")
	end

	g_mouse.popCursor('target')
	self:ungrabMouse()
	return true
end

function terminate()
  bottombarWindow:destroy()
  disconnect(g_game, {
  	onGameStart = online,
  	onGameEnd = offline,
  })
  disconnect(LocalPlayer, { 
	onHealthChange = onHealthChange,
    onLevelChange = onLevelChange,
    onStaminaChange = onStaminaChange,
    onExperienceChange = onExperienceChange,
    onSkillChange = onSkillChange,
    onSpeedChange = onSpeedChange,
  })
end

function onSpeedChange(localPlayer, speed)
  backgroundSpeed.value:setText(formatNumber(speed))
end

function onSkillChange(localPlayer, id, level, percent)
  if id == 6 then
    local levelPercent = math.floor(percent)
    local Yhppc = math.floor(53 * (1 - (levelPercent / 100)))
    local rect = { x = 0, y = 0, width = 53 - Yhppc + 1, height = 6 }
    backgroundFish.progress:setImageClip(rect)
    backgroundFish.progress:setImageRect(rect)
    
    backgroundFish.value:setText(level)
    backgroundFish.base_progress:setTooltip('You still need '..(100 - percent)..'% of experience to move up to the level '..(level+1)..'.')
  end
end

function onStaminaChange(localPlayer, stamina)
  local hours = math.floor(stamina / 60)
  local minutes = string.format("%02d", stamina % 60)
  local percent = math.floor(100 * stamina / (42 * 60)) -- max is 42 hours --TODO not in all client versions

  local levelPercent = math.floor(percent)
  local Yhppc = math.floor(53 * (1 - (levelPercent / 100)))
  local rect = { x = 0, y = 0, width = 53 - Yhppc + 1, height = 6 }

  local isPremium = localPlayer:isPremium()
  local clientVersion = g_game.getClientVersion()
  local text = tr("You have %s hours and %s minutes left", hours, minutes)

  if stamina > 2400 then
    if clientVersion >= 1038 then
      if isPremium then
        text = text .. '\n' .. "You will now gain 50% more experience"
      else
        text = text .. '\n' .. "You will not get 50% more experience because you are not a VIP player."
      end
    else
      text = text .. '\n' .. "If you are a VIP player, you will earn 50% more experience"
    end
  elseif stamina <= 840 and stamina > 0 then
    text = text .. "\n" .. "You only gain 50% Experience and cannot receive Loot from Monsters."
  elseif stamina == 0 then
    text = text .. "\n" .. "You will no longer receive loot or experience."
  end
end

function onExperienceChange(localPlayer, value)
  local postFix = ""
  if value > 10000000 then
	postFix = "B"
  elseif value > 1000000 then
	postFix = "M"
  elseif value > 1000 then
	postFix = "K"
  end
  
  backgroundLevel.value:setText(formatNewNumber(value))
end

function formatNewNumber(value)
  local formattedValue = string.format("%.0f", value)
  formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d)$", "%1.%2")
  formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d)(%.%d%d)$", "%1.%2%3")
  return formattedValue
end

function onHealthChange(localPlayer, health, maxHealth)
  if health > maxHealth then
    maxHealth = health
  end

  backgroundLife.value:setText(formatNumber(health))
  backgroundLife.base_progress:setTooltip('Your characters health is '..formatNumber(health)..' of '..formatNumber(maxHealth)..'.')

  local healthPercent = math.floor(g_game.getLocalPlayer():getHealthPercent())
  local Yhppc = math.floor(85 * (1 - (healthPercent / 100)))
  local rect = { x = 0, y = 0, width = 85 - Yhppc + 1, height = 6 }
  backgroundLife.progress:setImageClip(rect)
  backgroundLife.progress:setImageRect(rect)
end

function formatNumber(value)
  local formattedValue = string.format("%.0f", value)
  formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d)$", "%1.%2")
  formattedValue = string.gsub(formattedValue, "(%d)(%d%d%d)(%.%d%d)$", "%1.%2%3")
  return formattedValue
end

function onLevelChange(localPlayer, value, percent)
  local text = 'You have '..(100 - percent)..'% to level up missing '..formatNumber(expToAdvance(localPlayer:getLevel(), localPlayer:getExperience()))..' of experience.'

  local levelPercent = math.floor(percent)
  local Yhppc = math.floor(187 * (1 - (levelPercent / 100)))
  local rect = { x = 0, y = 0, width = 187 - Yhppc + 1, height = 6 }
  backgroundLevel.progress:setImageClip(rect)
  backgroundLevel.progress:setImageRect(rect)
  
  backgroundLevel.valueLevel:setText('Lv.'..localPlayer:getLevel())

  if localPlayer.expSpeed ~= nil then
     local expPerHour = math.floor(localPlayer.expSpeed * 3600)
     if expPerHour > 0 then
        local nextLevelExp = expForLevel(localPlayer:getLevel()+1)
        local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
        local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft))*60)
        hoursLeft = math.floor(hoursLeft)
        text = text .. '\n' .. formatNumber(expPerHour) .. ' per hour'
        text = text .. '\n' .. tr('Next level in %d hours and %d minutes', hoursLeft, minutesLeft)
     end
  end
  
  backgroundLevel.base_progress:setTooltip(text)
end

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel+1) - currentExp
end

function hide()
  bottombarWindow:hide()
end

function show()
  bottombarWindow:show()
end

function toggle()
  if bottombarWindow:isVisible() then
    g_effects.fadeOut(bottombarWindow, 350)
    scheduleEvent(function() 
      bottombarWindow:hide()
    end, 400)
  else
    bottombarWindow:show()
    g_effects.fadeIn(bottombarWindow, 350)
  end
end

function doGetBottombarButtonWind()
  return bottombarWindow.backgroundButtons
end
function doGetBottombar()
  return bottombarWindow
end

function getbackgroundInfos()
	return backgroundInfos
end
-------------------------------------------------(!)