function ,m
    set tempname "$(mktemp /tmp/scratch-mail.XXXXXX)"
    echo "$tempname"
    nvim "$tempname" -c "set ft=mail"
end
