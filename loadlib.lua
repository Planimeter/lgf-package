--=========== Copyright © 2017, Planimeter, All rights reserved. =============--
--
-- Purpose: Extends the package library
--
--============================================================================--

require( "package" )
local ffi = require( "ffi" )

if ( ffi.os == "Windows" ) then
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

if ( not rawrequire ) then
	rawrequire = require
end

local function getModuleFilename( modname )
	local path = string.gsub( modname, "%.", "/" )
	local filename = path .. ".lua"
	if ( not framework.filesystem.exists( filename ) ) then
		filename = path .. "/init.lua"
	end
	return filename
end

function require( modname )
	if ( package.watched[ modname ] ) then
		return rawrequire( modname )
	end

	local status, ret = pcall( rawrequire, modname )
	if ( not status ) then
		error( ret, 2 )
	end

	local filename = getModuleFilename( modname )
	package.watched[ modname ] = framework.filesystem.getLastModified( filename )
	return ret
end

local function unload( modname )
	package.loaded[ modname ] = nil
	package.watched[ modname ] = nil
end

function unrequire( modname )
	unload( modname )
	print( "Unloading " .. modname .. "..." )
end

package.watched = package.watched or {}

local function reload( modname, filename )
	unload( modname )
	print( "Updating " .. modname .. "..." )

	local status, err = pcall( require, modname )
	if ( status ) then return end

	print( err )

	local modtime, errormsg = framework.filesystem.getLastModified( filename )
	package.watched[ modname ] = modtime
end

function package.update( dt )
	if ( ffi.os == "Windows" ) then
		local signaled = ffi.C.WaitForSingleObject( package.handle, 0 ) == 0
		if ( not signaled ) then return end
	end

	for k, v in pairs( package.watched ) do
		local filename = getModuleFilename( k )
		local modtime, errormsg = framework.filesystem.getLastModified( filename )
		if ( not errormsg and modtime ~= v ) then
			reload( k, filename )
		end
	end

	if ( ffi.os == "Windows" ) then
		ffi.C.FindNextChangeNotification( package.handle )
	end
end
