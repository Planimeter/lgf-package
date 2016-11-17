--=========== Copyright © 2016, Planimeter, All rights reserved. =============--
--
-- Purpose: Extends the package library
--
--============================================================================--

require( "package" )
require( "ffi" )

if ( love.system.getOS() == "Windows" ) then
	ffi.cdef[[
		typedef void          VOID;
		typedef VOID         *HANDLE;
		typedef char          CHAR;
		typedef const CHAR   *LPCTSTR;
		typedef int           BOOL;
		typedef unsigned long DWORD;

		HANDLE FindFirstChangeNotificationA(
			LPCTSTR lpPathName,
			BOOL    bWatchSubtree,
			DWORD   dwNotifyFilter
		);

		DWORD WaitForSingleObject(
			HANDLE hHandle,
			DWORD  dwMilliseconds
		);

		BOOL FindNextChangeNotification(
			HANDLE hChangeHandle
		);
	]]
end

local weakmt = {
	__mode = 'v'
}
local Watcher
do
	local _class_0
	local _base_0 = {
		register = function(self, filename, obj)
			if self.files[filename] then
				return table.insert(self.files[filename], obj)
			else
				print("listening to changes for " .. tostring(filename) .. "...")
				self.files[filename] = setmetatable({
					obj,
					modified = love.filesystem.getLastModified(filename)
				}, weakmt)
			end
		end,
		update = function(self)
			local changes
			local _exp_0 = love.system.getOS()
			if "Windows" == _exp_0 then
				changes = 0 == ffi.C.WaitForSingleObject(self.handle, 0)
			elseif "Linux" == _exp_0 then
				changes = #self.handle:read() > 0
			end
			if changes then
				for name, objs in pairs(self.files) do
					local modified = love.filesystem.getLastModified(name)
					if objs.modified < modified then
						print("modified " .. tostring(name))
						objs.modified = modified
						for _, obj in pairs(objs) do
							if "number" == type(_) then
								obj:reload(name)
							end
						end
					end
				end
				if love.system.getOS() == "Windows" then
					return ffi.C.FindNextChangeNotification(self.handle)
				end
			end
		end
	}
	_base_0.__index = _base_0
	_class_0 = setmetatable({
		__init = function(self)
			self.files = { }
			local _exp_0 = love.system.getOS()
			if "Windows" == _exp_0 then
				self.handle = ffi.C.FindFirstChangeNotificationA(".", true, 0x00000010)
			elseif "Linux" == _exp_0 then
				local inotify = require("inotify")
				self.handle = inotify.init({
					blocking = false
				})
				return self.handle:addwatch(".", inotify.IN_MODIFY, inotify.IN_ACCESS)
			end
		end,
		__base = _base_0,
		__name = "Watcher"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({}, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	Watcher = _class_0
end
return {
	Watcher = Watcher
}
