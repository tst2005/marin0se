portalgun = class('portalgun', weapon)
function portalgun:init(parent)
	weapon.init(self,parent)
end

function portalgun:update(dt)
	weapon.update(self,dt)
	-- nothin'
end

function portalgun:draw()
	weapon.draw(self)
	
	-- @TODO: We could probably internalize a lot of these properties.
	local ply = self.parent
	if ply and ply.controlsenabled and ply.activeweapon == self and not ply.vine and table.contains(ply.portalsavailable, true) then
		local sourcex, sourcey = ply.x+6/16, ply.y+6/16
		--@DEV: commented out because stuff
		local cox, coy, side, tend, x, y = 0, 0, 1, 1, 0, 0
		--local cox, coy, side, tend, x, y = traceline(sourcex, sourcey, ply.pointingangle)
		local portalpossible = true
		if cox == false or getportalposition(1, cox, coy, side, tend) == false then
			portalpossible = false
		end
		
		-- DRAW THE DOTS
		love.graphics.setColor(255, 255, 255, 255)
		local dist = math.sqrt(((x-xscroll)*16*scale - (sourcex-xscroll)*16*scale)^2 + ((y-.5-yscroll)*16*scale - (sourcey-.5-yscroll)*16*scale)^2)/16/scale
		for i = 1, dist/portaldotsdistance+1 do
			if((i-1+portaldotstimer/portaldotstime)/(dist/portaldotsdistance)) < 1 then
				local xplus = ((x-xscroll)*16*scale - (sourcex-xscroll)*16*scale)*((i-1+portaldotstimer/portaldotstime)/(dist/portaldotsdistance))
				local yplus = ((y-.5-yscroll)*16*scale - (sourcey-.5-yscroll)*16*scale)*((i-1+portaldotstimer/portaldotstime)/(dist/portaldotsdistance))
				
				local dotx = (sourcex-xscroll)*16*scale + xplus
				local doty = (sourcey-.5-yscroll)*16*scale + yplus
				
				local radius = math.sqrt(xplus^2 + yplus^2)/scale
				
				local alpha = 255
				if radius < portaldotsouter then
					alpha = (radius-portaldotsinner) * (255/(portaldotsouter-portaldotsinner))
					if alpha < 0 then
						alpha = 0
					end
				end
				
				
				if portalpossible == false then
					love.graphics.setColor(255, 0, 0, alpha)
				else
					love.graphics.setColor(0, 255, 0, alpha)
				end
				
				love.graphics.draw(portaldotimg, math.floor(dotx-0.25*scale), math.floor(doty-0.25*scale), 0, scale, scale)
			end
		end
		
		-- DRAW CROSSHAIR
		love.graphics.setColor(255, 255, 255, 255)
		if cox ~= false then
			if portalpossible == false then
				love.graphics.setColor(255, 0, 0)
			else
				love.graphics.setColor(0, 255, 0)
			end
			
			local rotation = 0
			if side == "right" then
				rotation = math.pi/2
			elseif side == "down" then
				rotation = math.pi
			elseif side == "left" then
				rotation = math.pi/2*3
			end
			love.graphics.draw(portalcrosshairimg, math.floor((x-xscroll)*16*scale), math.floor((y-.5-yscroll)*16*scale), rotation, scale, scale, 4, 8)
		end
	end
end

function portalgun:shootPortal(i)
	shootportal(self.parent.playernumber, i, self.parent.x+6/16, self.parent.y+6/16, self.parent.pointingangle, false)
	if objects["player"][plnumber].portalgundisabled then
		return
	end
	
	--check if available
	if not objects["player"][plnumber].portalsavailable[i] then
		return
	end
	
	--box
	if objects["player"][plnumber].pickup then
		return
	end
	--portalgun delay
	if portaldelay[plnumber] > 0 then
		return
	else
		portaldelay[plnumber] = portalgundelay
	end
	
	local otheri = 1
	local color = objects["player"][plnumber].portal2color
	if i == 1 then
		otheri = 2
		color = objects["player"][plnumber].portal1color
	end
	
	if not mirrored then
		objects["player"][plnumber].lastportal = i
	end
	local mirror = false
	local cox, coy, side, tendency, x, y = traceline(sourcex, sourcey, direction)
	if cox then
		mirror = tilequads[map[cox][coy][1]]:getproperty("mirror", cox, coy)
		if map[cox][coy]["gels"] and map[cox][coy]["gels"][side] then
			local gelstat = map[cox][coy]["gels"][side]
			if mirror and table.contains(gelsthattarnishmirrors, enum_gels[gelstat]) then
				mirror = false
			end
		--	elseif mirror and enum_gels[gelstat] == "white" then
		--		mirror = false
		--	end
		end
	end
	
	objects["player"][plnumber].lastportal = i
	
	table.insert(portalprojectiles, portalprojectile:new(sourcex, sourcey, x, y, color, true, {objects["player"][plnumber].portal, i, cox, coy, side, tendency, x, y}, mirror, mirrored))
	if not mirrored and portalknockback then
		local xadd = math.sin(objects["player"][plnumber].pointingangle)*30
		local yadd = math.cos(objects["player"][plnumber].pointingangle)*30
		objects["player"][plnumber].speedx = objects["player"][plnumber].speedx + xadd
		objects["player"][plnumber].speedy = objects["player"][plnumber].speedy + yadd
		objects["player"][plnumber].falling = true
		objects["player"][plnumber].animationstate = "falling"
		objects["player"][plnumber]:setquad()
	end
end

function portalgun:primaryFire()
	if self.parent and weapon.primaryFire(self) then
		self:shootPortal(1)
	else
		print("DEBUG: Tried to shoot portal1 with orphaned weapon?!")
	end
end

function portalgun:secondaryFire()
	if self.parent and weapon.secondaryFire(self) then
		self:shootPortal(2)
	else
		print("DEBUG: Tried to shoot portal with orphaned weapon?!")
	end
end

function portalgun:oldShootPortal(i)
	if self.parent.portalgundisabled then
		return
	end
	
	--check if available
	if not self.parent.portalsavailable[i] then
		return
	end
	
	--box
	if self.parent.pickup then
		return
	end
	--portalgun delay
	if self.parent.portaldelay > 0 then
		return
	else
		self.parent.portaldelay = portalgundelay
	end
	
	local otheri = 1
	local color = self.parent.portal2color
	if i == 1 then
		otheri = 2
		color = self.parent.portal1color
	end
	
	if not mirrored then
		self.parent.lastportal = i
	end
	local mirror = false
	local cox, coy, side, tendency, x, y = traceline(sourcex, sourcey, direction)
	if cox then
		mirror = tilequads[map[cox][coy][1]]:getproperty("mirror", cox, coy)
		if map[cox][coy]["gels"] and map[cox][coy]["gels"][side] then
			local gelstat = map[cox][coy]["gels"][side]
			if mirror and table.contains(gelsthattarnishmirrors, enum_gels[gelstat]) then
				mirror = false
			end
		--	elseif mirror and enum_gels[gelstat] == "white" then
		--		mirror = false
		--	end
		end
	end
	
	objects["player"][plnumber].lastportal = i
	
	table.insert(portalprojectiles, portalprojectile:new(sourcex, sourcey, x, y, color, true, {objects["player"][plnumber].portal, i, cox, coy, side, tendency, x, y}, mirror, mirrored))
	if not mirrored and portalknockback then
		local xadd = math.sin(objects["player"][plnumber].pointingangle)*30
		local yadd = math.cos(objects["player"][plnumber].pointingangle)*30
		objects["player"][plnumber].speedx = objects["player"][plnumber].speedx + xadd
		objects["player"][plnumber].speedy = objects["player"][plnumber].speedy + yadd
		objects["player"][plnumber].falling = true
		objects["player"][plnumber].animationstate = "falling"
		objects["player"][plnumber]:setquad()
	end
end