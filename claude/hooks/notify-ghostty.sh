#!/bin/sh
# Send a Ghostty desktop notification (OSC 777) for Claude Code Stop/Notification
# hooks. Hooks have no terminal of their own, so find one to write to:
#   - in tmux: the tmux client ttys, so it reaches Ghostty over SSH even when
#     the Claude pane isn't the visible one
#   - otherwise: the tty of the nearest ancestor process that has one (Claude)

input=$(cat)
case "$1" in
    permission)
        msg="Permission needed: $(printf '%s' "$input" | jq -r '.tool_name // "a tool"')" ;;
    question)
        msg="Question: $(printf '%s' "$input" | jq -r '.tool_input.questions[0].question // "waiting for your answer"')" ;;
    *)
        msg="Response ready" ;;
esac

title="Claude Code on $(uname -n)"

if [ -n "$TMUX_PANE" ]; then
    session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}')
    window=$(tmux display-message -p -t "$TMUX_PANE" '#{window_index}:#{window_name}')
    title="$title [$session $window]"
    ttys=$(tmux list-clients -t "$session" -F '#{client_tty}')
else
    pid=$PPID
    ttys=
    while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
        tty=$(ps -o tty= -p "$pid" | tr -d ' ')
        if [ -n "$tty" ] && [ "$tty" != "?" ]; then
            ttys=/dev/$tty
            break
        fi
        pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
    done
fi

# Strip control chars (and ';' from the title, since it delimits OSC 777 fields)
title=$(printf '%s' "$title" | tr -d '\000-\037;')
msg=$(printf '%s' "$msg" | tr -d '\000-\037')

for tty in $ttys; do
    [ -w "$tty" ] && printf '\033]777;notify;%s;%s\007' "$title" "$msg" > "$tty"
done
exit 0
