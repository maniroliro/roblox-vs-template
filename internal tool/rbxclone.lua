--[[

cd PATH lune run "internal tool/rbxclone.lua"

]]

--!nocheck
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

--==========SETTINGS===========--
local FILE_TO_READ = "BMF.rbxl"

local parsedFile = fs.readFile(FILE_TO_READ)
local game = roblox.deserializePlace(parsedFile)

local outputFolder = "BMF"

-- Se true, exporta apenas scripts; se false, exporta tudo
local COPY_ONLY_SCRIPTS = true

-- Sanitiza nomes para filesystem Windows (remove caracteres inválidos e reserva palavras)
local function sanitizeName(name: string): string
	-- Substitui caracteres inválidos por '_'
	local cleaned = name:gsub('[<>:"/\\|%?%*]', "_")
	-- Remove controles
	cleaned = cleaned:gsub("%c", "")
	-- Trim espaços finais e pontos (inválidos no fim em Windows)
	cleaned = cleaned:gsub("[%. ]+$", "")
	if cleaned == "" then
		cleaned = "_"
	end
	-- Palavras reservadas no Windows
	local upper = cleaned:upper()
	local reserved = {
		CON = true,
		PRN = true,
		AUX = true,
		NUL = true,
		COM1 = true,
		COM2 = true,
		COM3 = true,
		COM4 = true,
		COM5 = true,
		COM6 = true,
		COM7 = true,
		COM8 = true,
		COM9 = true,
		LPT1 = true,
		LPT2 = true,
		LPT3 = true,
		LPT4 = true,
		LPT5 = true,
		LPT6 = true,
		LPT7 = true,
		LPT8 = true,
		LPT9 = true,
	}
	if reserved[upper] then
		cleaned = cleaned .. "_"
	end
	return cleaned
end

local FileTypeByInstanceClassName = {
	["ModuleScript"] = ".luau",
	["Script"] = ".server.luau",
	["LocalScript"] = ".client.luau",
	--["Model"] = ".model",
	--["Frame"] = ".frame",
}

local ScriptClassNames = {
	["ModuleScript"] = true,
	["Script"] = true,
	["LocalScript"] = true,
}

-- Rastreador para lidar com nomes duplicados dentro do mesmo diretório de saída
local usedNamesByPath = {}

local function getUniqueName(parentPath: string, baseName: string): string
	local key = parentPath or ""
	usedNamesByPath[key] = usedNamesByPath[key] or {}
	local count = (usedNamesByPath[key][baseName] or 0) + 1
	usedNamesByPath[key][baseName] = count
	if count == 1 then
		return baseName
	end
	return string.format("%s (%d)", baseName, count)
end

--===============================--

local function CreateFolderByPath(path: string)
	fs.writeDir(path)
end

local function IsInstanceInteresting(instance: Instance): boolean
	if COPY_ONLY_SCRIPTS then
		return ScriptClassNames[instance.ClassName] == true
	end
	return true
end

local function RemoveGarbageFromXMLScriptFile(scriptFile: string, startConstant: string, endConstant: string)
	local startIndex = scriptFile:find(startConstant)

	if not startIndex then
		return scriptFile
	end
	startIndex += startConstant:len()

	scriptFile = scriptFile:sub(startIndex, -1)

	local endIndex = scriptFile:find(endConstant) or -1
	scriptFile = scriptFile:sub(1, endIndex - 1)

	return scriptFile
end

-- Função para decodificar entidades HTML
local function decodeHTMLEntities(text: string): string
	-- Decodifica as entidades HTML mais comuns
	text = text:gsub("&lt;", "<")
	text = text:gsub("&gt;", ">")
	text = text:gsub("&amp;", "&")
	text = text:gsub("&quot;", '"')
	text = text:gsub("&#39;", "'")
	text = text:gsub("&apos;", "'")
	return text
end

local function OutputFileFromInstanceByPath(instance, path: string, forcedBaseName: string?)
	if IsInstanceInteresting(instance) == false then
		return
	end

	local className = instance.ClassName

	local baseName = forcedBaseName or sanitizeName(instance.Name)
	local fileType = FileTypeByInstanceClassName[className]
	local fileName
	local ext = fileType or ("." .. className)
	fileName = ScriptClassNames[className] and ("init" .. ext) or (baseName .. ext)

	local hasChildren = #instance:GetChildren() > 0

	-- clona e remove filhos para evitar duplicação em cada nó
	local instanceClone = instance:Clone()
	for _, child in instanceClone:GetChildren() do
		child:Destroy()
	end

	local file = roblox.serializeModel({ instanceClone }, true)
	if ScriptClassNames[className] == true then
		file = RemoveGarbageFromXMLScriptFile(file, '<string name="Source">', "</string>")
		file = RemoveGarbageFromXMLScriptFile(file, "<!%[CDATA", "%]%]>")
		-- Decodifica entidades HTML no código do script
		file = decodeHTMLEntities(file)
	end

	instanceClone:Destroy()

	if path:sub(-1, -1) ~= "/" then
		path = path .. "/"
	end

	-- Scripts sempre em pasta; outros entram em pasta se tiverem filhos
	if ScriptClassNames[className] == true or hasChildren then
		local folderPath = path .. baseName .. "/"
		fs.writeDir(folderPath)
		local innerName = ScriptClassNames[className] and fileName or ("init" .. ext)
		fs.writeFile(folderPath .. innerName, file)
	else
		fs.writeFile(path .. fileName, file)
	end
end

local function ParseAllDescendants(startingFolder: Folder, outputPath: string)
	if outputPath:find("/") == nil then
		outputPath = outputFolder .. "/" .. outputPath
	end

	CreateFolderByPath(outputPath)

	--print("starting folder: " .. startingFolder.Name)
	--print("current outputPath: " .. outputPath)

	for _, child in startingFolder:GetChildren() do
		local safeName = sanitizeName(child.Name)
		local uniqueName = getUniqueName(outputPath, safeName)
		local childPath = outputPath .. "/" .. uniqueName

		OutputFileFromInstanceByPath(child, outputPath, uniqueName)

		if #child:GetChildren() > 0 then
			CreateFolderByPath(childPath)
			ParseAllDescendants(child, childPath)
		end
	end
end

local function CreateAllFoldersInsideFolderWithStartingPath(startingFolder: Folder, outputPath: string)
	if outputPath:find("/") == nil then
		outputPath = outputFolder .. "/" .. outputPath
	end

	if startingFolder.ClassName == "Folder" then
		fs.writeDir(outputPath)
	end

	for _, child in startingFolder:GetChildren() do
		if child.ClassName == "Folder" then
			local safe = sanitizeName(child.Name)
			fs.writeDir(outputPath .. "/" .. safe .. "/")
			CreateAllFoldersInsideFolderWithStartingPath(child, outputPath .. "/" .. safe .. "/")
		end
	end
end

local function CreateAndParseFolderWithStartingPath(startingFolder: Folder, outputPath: string)
	ParseAllDescendants(startingFolder, outputPath)
end

CreateAndParseFolderWithStartingPath(game:GetService("Workspace"), "Workspace")
CreateAndParseFolderWithStartingPath(game:GetService("StarterGui"), "StarterGui")
CreateAndParseFolderWithStartingPath(game:GetService("ServerScriptService"), "ServerScriptService")
CreateAndParseFolderWithStartingPath(game:GetService("ServerStorage"), "ServerStorage")
CreateAndParseFolderWithStartingPath(game:GetService("ReplicatedFirst"), "ReplicatedFirst")
CreateAndParseFolderWithStartingPath(game:GetService("ReplicatedStorage"), "ReplicatedStorage")
CreateAndParseFolderWithStartingPath(game:GetService("StarterPlayer"), "StarterPlayer")

print("Done!")
