fx_version 'bodacious'
lua54 'yes'
game 'gta5'

shared_script '@ox_lib/init.lua'
server_scripts {
	'@mysql-async/lib/MySQL.lua',

	'config.lua',
	'server/main.lua'
}

client_scripts {
	'config.lua',
	'client/main.lua'
}

version '1.2'


