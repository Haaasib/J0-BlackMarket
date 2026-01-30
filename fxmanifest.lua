fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'mfhasib'
description 'qb-core community clash blackmarket script'

client_scripts {
    'client/**/*.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/**/*.lua'
}

shared_scripts {
    'shared/config.lua'
}

ui_page 'html/ui.html'
files {
    'html/*.html',
    'html/*.css',
    'html/*.js',
    'html/images/*.png',
}


escrow_ignore {
    'shared/*.lua',
    'shared/*.json',
    'client/fw-cl.lua',
    'server/fw-sv.lua',
}