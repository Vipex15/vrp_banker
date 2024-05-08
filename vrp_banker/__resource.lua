resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

dependency "vrp"

client_scripts{ 
	"@vrp/lib/utils.lua",
 	"client_vrp.lua"
}

server_scripts{ 
	"@vrp/lib/utils.lua",
	"vrp.lua"
}

files {
	"cfg.lua",
	"client.lua"
}
