# fzy.nvim
[fzy][] is a very simple and **really** fast fuzzy text selector finder for 
the terminal. It's a great tool to use with [rg][] and [ag][]. 
This plugin allows us to use *fzy* integrated with [Neovim][].

**ATENTION: only tested with `NVIM v0.3.7` on [`Arch Linux`][]**

## Long subject
[fzf][] it's my first daily fuzzy finder until now. But [fzy][] gives me a second best choice at all. In some cases I really prefer use *fzy* rather than *fzf* because it returns the best and fast results on my screen. Thinking about it I look for a great Vim plugin that provide not all features of [fzf.vim][] but just the basics to use on Neovim. I found some ones but I don't really like it in terms of configuration, simplicity and beauty. So I decided hack the *fzf* Vim plugin from the official repository and make my own *fzy* Vim plugin. And here is my results.

## Dependencies
- [Neovim][] >= v0.3.7
- [fzy][] >= 1.0
- [rg][] >= 11.0.1 or [ag][] >= 2.2.0 - This plugin uses `rg` as default 
    one.

## Installation
Use your favorite plugin manager, and add to your `.vimrc`: 

### [dein.vim][] 
```vim
call dein#add('sinetoami/fzy.nvim')
```
Run `:so %` and `:call dein#install()`.

## `:Fzy`
It's really looks like `:FZF` command. So, you can do something like:
```vim
" Look for files under current directory
:Fzy

" Look for files under your Projects at your home directory
:Fzy ~/Projects

" With options - see fzy man page for more options
:Fzy --show-score --query .zsh ~/Git
```

You can open a selected file in a new tab, in horizontal split or in vertical split using the predefined shortcuts `CTRL-T`, `CTRL-X` and `CTRL-V` respectivaly.

## Configuration
### `g:fzy_default_command` 
Defines `path`, `options` and `ignores` to a source.
- `path`: just `rg` or `ag`.
- `options`: options that `rg` or `ag` provides. Can passed as a *string* 
    or as a *list*.
- `ignores`: list of files/directories to be ignored by the 
    source.

### `g:fzy_layout`
Defines the size and position of fzy window.

#### Examples
```vim
"" This is the default g:fzy_command_command
let g:fzy_default_command = {
  \ 'path': 'rg',
  \ 'ignores': ['*.git'],
  \ 'options': [
  \ '--files', '--hidden', '--smart-case', 
  \ '--color=never', '--fixed-strings'
  \ ] }

"" Default options can be ovirride by new ones just doing this:
let g:fzy_default_command = {
\ 'options': '--files --hidden'
\ }

"" Or define the source to ignores nothing:
let g:fzy_default_command = { 'ignores': [] }

"" Or you can override the entiry source to uses ag:
let g:fzy_default_command = {
\ 'path': 'ag',
\ 'ignores': ['.git', 'node_modules'],
\ 'options': '--hidden --smart-case'
\ }


"" Default fzy layout
"" - Just above / below
let g:fzy_layout = { 'below': '~40%' }

"" You can set up fzy window
let g:fzy_layout = { 'above': '~100%' }
```

### `g:loaded_fzy`
Set this variable if you want to disable this plugin. Default is `1`.

## TODO
- enhance fzy layout settings: *left* and *right* options
- allow `:Fzy` to use `!` for fullscreen layout
- fzy statusline customizable
- multi files selections like `:FZF` using `TAB`

## Contributing
- To ask about the contents of the configuration, send me a feedback, 
    request features or report bugs, please open a GitHub issue.
- Open a pull-request if you want to improve this plugin. 
    I will glad to see your idea.

## Self-Promotion
Do you like this plugin? Come on:
- Star and follow the repository on [GitHub](https://github.com/sinetoami/fzy.nvim).
- Follow me on
  - [GitHub](https://github.com/sinetoami)

## Many thanks to
- [John Hawthorn][] for the great [fzy][] fuzzy finder
- [Junegunn Choi][] for the great [fzf][] Vim plugin which I hack to make 
    this fzy.nvim plugin

## License
[MIT License](LICENSE)

[fzy]: https://github.com/jhawthorn/fzy
[fzf]: https://github.com/junegunn/fzy
[rg]: https://github.com/BurntSushi/ripgrep
[ag]: http://geoff.greer.fm/ag/
[Neovim]: https://neovim.io
[`ArchLinux`]: https://archlinux.org
[fzf.vim]: https://github.com/junegunn/fzf.vim
[dein.vim]: https://github.com/Shougo/dein.vim
