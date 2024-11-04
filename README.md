# DOS Game

### Dependencies
- [GNU Make](https://www.gnu.org/software/make/)
- [Netwide Assembler](https://nasm.us/)
- [DOSBox](https://www.dosbox.com/)

### Building the Game
```sh
make build
```
> This is automatically ran for both the `run` and `dbg` targets.

### Running the Game
```sh
make run
```

### Debugging the game
```sh
make dbg
```
> This requires debug.exe to be present within DOSBox.

### Game Controls
Your player character `☺` can be moved with the `W` `A` `S` `D` keys.\
The obstacles `◄` move from right to left that you need to avoid.\
You can exit the game by pressing `Esc`.
