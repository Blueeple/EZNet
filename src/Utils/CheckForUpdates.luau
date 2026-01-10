--!strict
-- Services
local HttpService = game:GetService("HttpService")

-- Modules
local Types = require(script.Parent.Types)

-- Variables
local HttpFail = 0
local MaxFails = 4
local HttpPingDelay = 1

return function(UserName: string, RepoName: string): Types.GithubRelease_Latest
	local ResolvedHttp = {} :: Types.GithubRelease_Latest

	local GithubId = UserName .. "/" .. RepoName
	local GithubLatestRelease = `https://api.github.com/repos/{GithubId}/releases/latest`

	repeat
		task.wait(HttpPingDelay * HttpFail)
		local HttpRequest = pcall(function()
			local Request = HttpService:GetAsync(GithubLatestRelease)
			local DecodedRequest = HttpService:JSONDecode(Request) :: Types.GithubRelease_Latest

			ResolvedHttp.name = DecodedRequest.name
			ResolvedHttp.published_at = DecodedRequest.published_at
		end)

		if HttpRequest then
			break
		else
			warn(
				"[EZNet-Updater][Http] - Network failure, retrying in... "
					.. string.format("%.1f", (HttpPingDelay * HttpFail) + HttpPingDelay)
			)
		end

		HttpFail += 1
	until HttpFail >= (MaxFails + 1)

	task.wait(HttpPingDelay)

	if not ResolvedHttp.name or not ResolvedHttp.published_at then
		warn("[EZNet-Updater][Http] - Failed to resolve lastest version on Github.")
	end

	return ResolvedHttp
end
