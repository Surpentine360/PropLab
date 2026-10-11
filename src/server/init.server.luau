local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Session = require(script.Session)
Players.CharacterAutoLoads = false
local remote = Instance.new("RemoteFunction")
remote.Name = "PropLabSession"
remote.Parent = ReplicatedStorage
local sessions, buckets = {}, {}
remote.OnServerInvoke = function(player, request)
    local now = os.clock()
    local bucket = buckets[player] or { tokens = 12, time = now }
    bucket.tokens = math.min(12, bucket.tokens + (now - bucket.time) * 8)
    bucket.time = now
    buckets[player] = bucket
    if bucket.tokens < 1 then return { ok = false, message = "Slow down a moment." } end
    bucket.tokens -= 1
    local session = sessions[player]
    if not session then session = Session.new(); sessions[player] = session end
    local ok, message = session:dispatch(request)
    return { ok = ok, message = message, state = session:snapshot() }
end
Players.PlayerRemoving:Connect(function(player)
    sessions[player], buckets[player] = nil, nil
end)
