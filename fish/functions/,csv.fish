function ,csv
    column -s, -t < $argv[1] | less -#2 -N -S
end
