fx_version 'adamant'

game 'gta5'

description ''
lua54 'yes'

version '1.1' 
legacyversion '1.9.1'

shared_scripts {
	'@es_extended/imports.lua',
	'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}


dependencies { 'es_extended' }