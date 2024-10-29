build: game.asm
	nasm -f bin -o bin/game.com game.asm

run: build
	dosbox -conf dosbox.conf -c 'game.com' -c 'exit'

dbg: build
	dosbox-debug -conf dosbox.conf -c 'debug game.com' -c 'exit'
