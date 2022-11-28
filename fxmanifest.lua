fx_version 'cerulean'
game 'gta5'

shared_script 'config.lua'

server_script 'server/main.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

lua54 'yes'