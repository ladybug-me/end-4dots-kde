function fish_greeting
    set_color blue
    echo '    ____                         __                  '
    echo '   /  _/___ ___   ____  __  __  / / _____  ___       '
    echo '   / // __ `__ \ / __ \/ / / / / / / ___/ / _ \      '
    echo ' _/ // / / / / // /_/ / /_/ / / / (__  ) /  __/      '
    echo '/___/_/ /_/ /_// .___/\__,_/ /_/ /____/  \___/       '
    echo '              /_/                                    '
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
