function ,vm --description 'view man'
    pandoc -s -t man $argv[1] | man -l -
end
