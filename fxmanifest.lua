fx_version 'cerulean'
game 'gta5'

author 'Tonybyn_Mp4'
description 'Photo mode for the Qbox Framework'
repository 'https://github.com/TonybynMp4/qbx_photomode'
version '1.0.0'

ox_lib 'locale'

ui_page 'html/index.html'
files {
    'html/*',
    'locales/*'
}

client_scripts {
    '@ox_lib/init.lua',
    'client/*.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'