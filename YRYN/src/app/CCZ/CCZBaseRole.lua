local CCZBaseRole = class("CCZBaseRole")

function CCZBaseRole:ctor()
	self._animation = {
		move = {
			up    = nil,
			down  = nil,
			left  = nil,
			right = nil
		},
		attack = {
			up    = nil,
			down  = nil,
			left  = nil,
			right = nil
		},
		low_hp = nil,
		parry = {
			up    = nil,
			down  = nil,
			left  = nil,
			right = nil
		}
	}
end

return CCZBaseRole