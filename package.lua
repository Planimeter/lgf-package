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

	package.handle = ffi.C.FindFirstChangeNotificationA( ".", true, 0x00000010 )
end

package.watched = package.watched or {}

local function reload( modname, filename )
	unload( modname )
	print( "Updating " .. modname .. "..." )

	local status, err = pcall( require, modname )
	if ( status ) then return end

	print( err )

	local modtime, errormsg = love.filesystem.getLastModified( filename )
	package.watched[ modname ] = modtime
end

function package.update( dt )
	if ( love.system.getOS() == "Windows" ) then
		local signaled = ffi.C.WaitForSingleObject( package.handle, 0 ) == 0
		if ( not signaled ) then return end
	end

	for k, v in pairs( package.watched ) do
		local filename = getModuleFilename( k )
		local modtime, errormsg = love.filesystem.getLastModified( filename )
		if ( not errormsg and modtime ~= v ) then
			reload( k, filename )
		end
	end

	if ( love.system.getOS() == "Windows" ) then
		ffi.C.FindNextChangeNotification( package.handle )
	end
end
