function ,json
    jq '.[]' $argv[1] | bat --plain --language=json
end
