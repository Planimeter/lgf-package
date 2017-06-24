--=========== Copyright © 2017, Planimeter, All rights reserved. ===========--
--
-- Purpose: Extends the package library
--
--==========================================================================--

require( "package" )

if ( not rawrequire ) then
	rawrequire = require
end

local function getModuleFilename( modname )
	local module = string.gsub( modname, "%.", "/" )
	for _, paths in ipairs( {
		string.gmatch( package.path .. ";", "(.-);" ),
		string.gmatch( love.filesystem.getRequirePath() .. ";", "(.-);" )
	} ) do
		for path in paths do
			path = string.gsub( path, "%.[\\/]", "" )
			local filename = string.gsub( path, "?", module )
			if ( love.filesystem.exists( filename ) ) then
				return filename
			end
		end
	end
end

function require( modname )
	if ( package.watched[ modname ] ) then
		return rawrequire( modname )
	end

	local status, ret = pcall( rawrequire, modname )
	if ( status == false ) then
		error( ret, 2 )
	end

	local filename = getModuleFilename( modname )
	if ( filename ) then
		local modtime, errormsg = love.filesystem.getLastModified( filename )
		package.watched[ modname ] = modtime
	end

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
	if ( status ) then
		return
	end

	print( err )

	local modtime, errormsg = love.filesystem.getLastModified( filename )
	package.watched[ modname ] = modtime
end

local function update( k, v )
	local filename = getModuleFilename( k )
	if ( not filename ) then
		return
	end

	local modtime, errormsg = love.filesystem.getLastModified( filename )
	if ( not errormsg and modtime ~= v ) then
		reload( k, filename )
	end
end

function package.update( dt )
	for k, v in pairs( package.watched ) do
		update( k, v )
	end
end
