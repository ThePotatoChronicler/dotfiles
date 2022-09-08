filetype indent plugin on
syntax on

" No newline at end of file
" set noeol
" set nofixendofline

let g:mapleader = " "
set list
set autoindent
set smartindent
set number relativenumber
set tabstop=4
set shiftwidth=4
set title
set updatetime=300
set noshowmode " Hides the mode in bar under status line
set ruler
set mouse=a
set cinkeys-=0#
set notimeout " Stops the timeout on unfinished key combinations

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

set undodir=~/.vim/undo
set undofile

" Makes clipboard be shared with system
" set clipboard+=unnamedplus

call plug#begin('~/.vim/plugged')

" Discord status
Plug 'vimsence/vimsence'
" Rust
Plug 'rust-lang/rust.vim'
" C#
Plug 'OmniSharp/omnisharp-vim'
" Semantic Cxx highlighting (used for semantic highlighting in coc.nvim + coc-clangd)
Plug 'jackguo380/vim-lsp-cxx-highlight'
" Commenting
Plug 'preservim/nerdcommenter'
" Auto-close brackets
Plug 'jiangmiao/auto-pairs'
" Plug 'Raimondi/delimitMate'
" Auto-complete
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Indent lines
Plug 'Yggdroot/indentLine'
" Language pack
" Plug 'sheerun/vim-polyglot'
" File browser
Plug 'preservim/nerdtree'
" Themes
Plug 'flazz/vim-colorschemes'
" Color preview
Plug 'ap/vim-css-color'
" Dracula theme
Plug 'dracula/vim', { 'as': 'dracula' }
" Return cursor to last position
Plug 'farmergreg/vim-lastplace'
" Crystal lang
Plug 'vim-crystal/vim-crystal'
" R lang support
Plug 'jalvesaq/Nvim-R', {'branch': 'stable'}
" southernlights theme
Plug 'jalvesaq/southernlights'
" Mainly for retarded haskell indentation
Plug 'raichoo/haskell-vim'
" Rainbow brackets for different levels
Plug 'luochen1990/rainbow'
" Auto-detect indent
Plug 'tpope/vim-sleuth'
" Popular solarized theme
Plug 'altercation/vim-colors-solarized'
" Lightline
Plug 'itchyny/lightline.vim'
" Kotlin support
Plug 'udalov/kotlin-vim'
" Changing colors
Plug 'felixhummel/setcolors.vim'
" Fish support
Plug 'dag/vim-fish', {'for': 'fish'}
" Julia support
Plug 'JuliaEditorSupport/julia-vim'
" Better python highlighting
Plug 'vim-python/python-syntax'
" Zig support in Vim
Plug 'ziglang/zig.vim'
" Go support in Vim
Plug 'fatih/vim-go'
" Partial Astro support
Plug 'wuelnerdotexe/vim-astro'
" Ansible support
Plug 'pearofducks/ansible-vim'
" HTML syntax highlighting support
Plug 'othree/html5.vim'
" Javascript support
Plug 'pangloss/vim-javascript'
" Svelte support
Plug 'evanleck/vim-svelte', {'branch': 'main'}
" Nim support
Plug 'zah/nim.vim'
call plug#end()


let g:coc_global_extensions = [
			\'coc-json', 'coc-git', 'coc-tsserver', 'coc-clangd',
			\'coc-html', 'coc-htmlhint', 'coc-html-css-support',
			\'coc-css', 'coc-cssmodules', 'coc-stylelintplus',
			\'coc-jedi', 'coc-lua', 'coc-yaml', 'coc-eslint',
			\'coc-styled-components', 'coc-angular', 'coc-svelte'
			\]

" Sadly, outdated and breaks some stuff
" colorscheme briofita

colorscheme dracula

let g:python_highlight_all = 1

" To get rid of checkhealth warning
let g:python3_host_prog = '/bin/python'

" vimsence settings
let g:vimsence_small_text = 'neovim'
let g:vimsence_small_image = 'neovim'

" nerdcommenter settings
let g:NERDCreateDefaultMappings = 1
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 1
let g:NERDToggleCheckAllLines = 1

" auto-pairs settings
let g:AutoPairsMultilineClose = 0

" Disable autosuggestions on Coc.nvim
" let b:coc_suggest_disable = 1

" Makes .asm files filetype nasm
autocmd BufRead,BufNewFile *.asm setlocal filetype=nasm

" Makes .ll files filetype llvm
autocmd BufRead,BufNewFile *.ll setlocal filetype=llvm

" Uses spaces for indentation in Haskell
autocmd FileType haskell set expandtab

" OmniSharp will use installed mono
let g:OmniSharp_server_use_mono = 1

" Yggdroot/indentLine to NOT hide stuff in json and markdown
let g:vim_json_conceal = 0
let g:markdown_syntax_conceal=0

" Rainbow leveled brackets
let g:rainbow_active = 1

" Lightline theme
let g:lightline = { 'colorscheme': 'wombat' }

" Coc stuff
" Fix current line
nmap <leader>qf  <Plug>(coc-fix-current)
nmap <leader>d :call CocAction('jumpDefinition', 'tabe')<CR>

" No autoformatting from zig
let g:zig_fmt_autosave = 0

" No LSP
let g:go_gopls_enabled = 0
let g:go_fmt_autosave = 0

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
