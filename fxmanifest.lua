fx_version 'cerulean'
game 'gta5'

author 'TropicGalxy'
description 'time trial system with creator system'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua',
    'client/creator_cl.lua'
}

server_scripts {
   '@oxmysql/lib/MySQL.lua', 
   'server/server.lua',
   'server/creator_sv.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}