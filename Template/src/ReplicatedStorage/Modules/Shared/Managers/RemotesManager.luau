local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local remotesData = require(replicatedStorage.Modules.Shared.Data.RemotesData)

local RemotesManager = {}
RemotesManager.Remotes = {}

function CreateRemotes()
	for remoteName, remoteType in pairs(remotesData) do
		local remote = Instance.new("Remote" .. remoteType)
		remote.Name = remoteName
		remote.Parent = replicatedStorage.Remotes
		RemotesManager.Remotes[remoteName] = remote
	end
end

function CatalogRemotes()
	local remotesFolder = replicatedStorage:WaitForChild("Remotes")
	for _, remote in pairs(remotesFolder:GetChildren()) do
		RemotesManager.Remotes[remote.Name] = remote
	end
end

function RemotesManager:GetRemote(remoteName)
	return RemotesManager.Remotes[remoteName]
end

function RemotesManager.FireClient(player, remoteName, ...)
	local remote = RemotesManager.Remotes[remoteName]
	if remote then
		remote:FireClient(player, ...)
	end
end

function RemotesManager.FireAllClients(remoteName, ...)
	local remote = RemotesManager.Remotes[remoteName]
	if remote then
		remote:FireAllClients(...)
	end
end

function RemotesManager.FireServer(remoteName, ...)
	local remote = RemotesManager.Remotes[remoteName]
	if remote then
		remote:FireServer(...)
	end
end

function RemotesManager.OnEvent(remoteName, callback)
	local remote = RemotesManager.Remotes[remoteName]
	if not remote then
		warn("[RemotesManager] Remote not found:", remoteName)
		return
	end

	if runService:IsServer() then
		remote.OnServerEvent:Connect(callback)
	else
		remote.OnClientEvent:Connect(callback)
	end
end

function RemotesManager.Init()
	if runService:IsServer() then
		Instance.new("Folder", replicatedStorage).Name = "Remotes"
		CreateRemotes()
	else
		CatalogRemotes()
	end
end

return RemotesManager
