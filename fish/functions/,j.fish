function ,j
    set -l file $HOME/Documents/journal/(date +%Y/%m/%d).dj
    mkdir -p (path dirname $file)
    pushd $HOME/Documents/journal
    $EDITOR $file
    popd
end
