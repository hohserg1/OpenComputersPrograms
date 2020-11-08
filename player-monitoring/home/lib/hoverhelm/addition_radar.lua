local gistId = "" -- create new secret gist and insert id here
local githubToken = "" -- visit https://github.com/settings/tokens for create and copy OAuth token for Gist
local programLocation = "/home/lib/hoverhelm/addition_radar.lua" -- it file vill be removed when otusiderplayer will closer to main device
local internet = require("component").internet

return {
    handlers={
        hh_gist_log = function(card, sender, content)
            internet.request(
                "https://api.github.com/gists/"..gistId.."/comments", 
                '{"body":"'..content..'"}', 
                {Authorization="token "..githubToken, Accept="application/vnd.github.v3+json"},
                "POST"
            )
        end,
        hh_destroy_github_token = function(card, sender)
            filesystem.remove(programLocation)
        end
    }
}
