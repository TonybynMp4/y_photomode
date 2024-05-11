fx_version 'cerulean'
game 'gta5'

author 'Tonybyn_Mp4'
description 'Photo mode for the Qbox Framework'
repository 'https://github.com/TonybynMp4/y_photomode'
version '1.0.1'

ox_lib 'locale'

ui_page 'html/index.html'
files {
    'html/*',
    'config/client.lua',
    'locales/*'
}

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'