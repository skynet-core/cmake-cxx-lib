#!/bin/sh

cd "$1" || exit 1

rm -rf build || true
rm -rf .cache || true
rm -rf result || true

python3 -m venv .venv

# shellcheck disable=SC1091
. .venv/bin/activate

pip install -U pip
if [ -f requirements.txt ]; then
	pip install -r requirements.txt
fi

if which fish 1>/dev/null 2>&1 && [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
	fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher 1>/dev/null 2>&1'
	fish -lc 'fisher install IlanCosman/tide@v5 1>/dev/null 2>&1'
fi

for name in bash zsh; do
	if [ -e "$HOME/.${name}rc" ]; then
		# shellcheck disable=SC2016
		count=$(grep -rc "eval \"\$(direnv hook $name)\"" "$HOME/.${name}rc")
		if [ "$count" -eq 0 ]; then
			# shellcheck disable=SC2016
			echo "eval \"\$(direnv hook $name)\"" >>"$HOME/.${name}rc"
		fi
	else
		# shellcheck disable=SC2016
		echo "eval \"\$(direnv hook $name)\"" >"$HOME/.${name}rc"
	fi
done

if [ -f "$HOME/.config/fish/config.fish" ]; then
	# shellcheck disable=SC2016
	count=$(grep -rc 'direnv hook fish | source' "$HOME/.config/fish/config.fish")
	if [ "$count" -eq 0 ]; then
		# shellcheck disable=SC2016
		echo 'direnv hook fish | source' >>"$HOME/.config/fish/config.fish"
	fi
else
	mkdir -p ~/.config/fish || true
	# shellcheck disable=SC2016
	echo 'direnv hook fish | source' >"$HOME/.config/fish/config.fish"
fi
