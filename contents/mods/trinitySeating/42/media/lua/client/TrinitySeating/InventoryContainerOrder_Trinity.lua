require "ISUI/ISInventoryPage"

local trinityOriginalRefreshBackpacks = ISInventoryPage.refreshBackpacks

local function isTrinityDebugEnabled()
    return isDebugEnabled and isDebugEnabled()
end

local function trinityLog(message)
    if isTrinityDebugEnabled() then
        print("[TrinitySeating] " .. tostring(message))
    end
end

trinityLog("InventoryContainerOrder_Trinity.lua loaded")

local vehicleContainerOrder = {
    SeatFrontLeft = 10,
    SeatFrontMiddle = 11,
    SeatFrontRight = 12,
    GloveBox = 20,
}

local function getVehicleContainerOrder(button)
    if not button or not button.inventory then
        return nil
    end

    return vehicleContainerOrder[button.inventory:getType()]
end

local function reflowContainerButtons(page)
    for index, button in ipairs(page.backpacks) do
        button:setY(((index - 1) * page.buttonSize) - 1)
        button.trinitySortedOrder = index
    end

    if #page.backpacks > 0 then
        page.containerButtonPanel:setScrollHeight(page.backpacks[#page.backpacks]:getBottom())
    end
end

local function snapshotButton(button)
    return {
        inventory = button.inventory,
        image = button.image,
        name = button.name,
        tooltip = button.tooltip,
        capacity = button.capacity,
        textureOverride = button.textureOverride,
        textureColor = {
            r = button.textureColor.r,
            g = button.textureColor.g,
            b = button.textureColor.b,
            a = button.textureColor.a,
        },
        originalOrder = button.trinityOriginalOrder,
    }
end

local function applySnapshot(button, snapshot)
    button.inventory = snapshot.inventory
    button:setImage(snapshot.image)
    button.name = snapshot.name
    button.tooltip = snapshot.tooltip
    button.capacity = snapshot.capacity
    button.textureOverride = snapshot.textureOverride
    button:setTextureRGBA(snapshot.textureColor.r, snapshot.textureColor.g, snapshot.textureColor.b, snapshot.textureColor.a)
    button.trinityOriginalOrder = snapshot.originalOrder
end

local function applySortedContainerData(page, sortedSnapshots)
    for index, button in ipairs(page.backpacks) do
        applySnapshot(button, sortedSnapshots[index])
        button.trinitySortedOrder = index
    end
end

local function refreshSelectedContainerState(page)
    page.selectedButton = nil
    page.title = nil

    for index, button in ipairs(page.backpacks) do
        if button.inventory == page.inventoryPane.inventory then
            page.selectedButton = button
            page.backpackChoice = index
            page.capacity = button.capacity
            page.title = button.name
            button:setBackgroundRGBA(0.7, 0.7, 0.7, 1.0)
        else
            button:setBackgroundRGBA(0.0, 0.0, 0.0, 0.0)
        end
    end
end

local function describeContainerButtons(page)
    local descriptions = {}

    for index, button in ipairs(page.backpacks) do
        local inventoryType = "nil"
        local order = "nil"

        if button and button.inventory then
            inventoryType = tostring(button.inventory:getType())
            order = tostring(getVehicleContainerOrder(button))
        end

        table.insert(descriptions, tostring(index) .. ":" .. inventoryType .. "(" .. order .. ")")
    end

    return table.concat(descriptions, ", ")
end

function ISInventoryPage:refreshBackpacks()
    trinityOriginalRefreshBackpacks(self)

    local playerObj = getSpecificPlayer(self.player)
    if not playerObj or not playerObj:getVehicle() then
        trinityLog("refresh skipped: player is not in a vehicle")
        return
    end

    trinityLog("refresh in vehicle, before sort: " .. describeContainerButtons(self))

    local hasVehicleContainerToSort = false
    for index, button in ipairs(self.backpacks) do
        button.trinityOriginalOrder = index
        if getVehicleContainerOrder(button) then
            hasVehicleContainerToSort = true
        end
    end

    if not hasVehicleContainerToSort then
        trinityLog("refresh skipped: no known vehicle container types found")
        return
    end

    local sortedSnapshots = {}
    for _, button in ipairs(self.backpacks) do
        table.insert(sortedSnapshots, snapshotButton(button))
    end

    table.sort(sortedSnapshots, function(a, b)
        local orderA = vehicleContainerOrder[a.inventory:getType()]
        local orderB = vehicleContainerOrder[b.inventory:getType()]

        if orderA and orderB then
            return orderA < orderB
        end

        if orderA then
            return true
        end

        if orderB then
            return false
        end

        return (a.originalOrder or 0) < (b.originalOrder or 0)
    end)

    applySortedContainerData(self, sortedSnapshots)
    reflowContainerButtons(self)
    refreshSelectedContainerState(self)

    trinityLog("refresh in vehicle, after sort: " .. describeContainerButtons(self))
end
