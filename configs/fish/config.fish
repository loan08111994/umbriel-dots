if status is-interactive
    # Commands to run in interactive sessions can go here
    #
    set fish_greeting
end

starship init fish | source
if status is-login
    set -Ux GTK_IM_MODULE fcitx
    set -Ux QT_IM_MODULE fcitx
    set -Ux XMODIFIERS @im=fcitx
    set -Ux SDL_IM_MODULE fcitx
    set -Ux GLFW_IM_MODULE ibus
end

# opencode
fish_add_path /home/nevil/.opencode/bin
