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

function package.init(self)
	self.files = { }
	local _exp_0 = love.system.getOS()
	if "Windows" == _exp_0 then
		self.handle = ffi.C.FindFirstChangeNotificationA(".", true, 0x00000010)
	end
end

function package.watch(self, filename, obj)
	if self.files[filename] then
		return table.insert(self.files[filename], obj)
	else
		print("listening to changes for " .. tostring(filename) .. "...")
		self.files[filename] = setmetatable({
			obj,
			modified = love.filesystem.getLastModified(filename)
		}, weakmt)
	end
end

function package.update(self)
	local changes
	local _exp_0 = love.system.getOS()
	if "Windows" == _exp_0 then
		changes = 0 == ffi.C.WaitForSingleObject(self.handle, 0)
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
