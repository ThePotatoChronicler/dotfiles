" No newline at end of file
" set noeol
" set nofixendofline

set list
set smartindent
set number relativenumber
set cinkeys-=0#
set notimeout " Stops the timeout on unfinished key combinations
set tabstop=4
set shiftwidth=4
set undofile

nnoremap <SPACE> <Nop>
let mapleader=" "

" Makes clipboard be shared with system
" set clipboard+=unnamedplus

let g:polyglot_disabled = ['zig']

call plug#begin('~/.vim/plugged')
" Sensible defaults
Plug 'tpope/vim-sensible'
" Secure modelines
Plug 'ciaranm/securemodelines'
" C#
Plug 'OmniSharp/omnisharp-vim'
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
Plug 'sheerun/vim-polyglot'
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
" R lang support
Plug 'jalvesaq/Nvim-R', {'branch': 'stable'}
" southernlights theme
Plug 'jalvesaq/southernlights'
" Rainbow brackets for different levels
Plug 'luochen1990/rainbow'
" Lightline
Plug 'itchyny/lightline.vim'
" Changing colors
Plug 'felixhummel/setcolors.vim'
" Partial Astro support
Plug 'wuelnerdotexe/vim-astro'
" Same-word highlighting for CoC
Plug 'IngoMeyer441/coc_current_word'
" Nightfox theme
Plug 'EdenEast/nightfox.nvim'
" For editing gdscript files
Plug 'habamax/vim-godot'
" For bazel
Plug 'google/vim-maktaba'
Plug 'bazelbuild/vim-bazel'
" For searching through project
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.1' }
" Undo trees
Plug 'mbbill/undotree'
call plug#end()

let g:coc_global_extensions = [
			\'coc-json', 'coc-git', 'coc-tsserver', 'coc-clangd',
			\'coc-html', 'coc-htmlhint', 'coc-html-css-support',
			\'coc-css', 'coc-cssmodules', 'coc-stylelintplus',
			\'coc-jedi', 'coc-lua', 'coc-yaml', 'coc-eslint',
			\'coc-styled-components', 'coc-angular', 'coc-svelte',
			\'coc-psalm', 'coc-xml', 'coc-java', 'coc-kotlin',
			\'coc-groovy', 'coc-tailwindcss', 'coc-yank',
			\'coc-vetur', 'coc-julia', '@yaegassy/coc-ansible',
			\'coc-rust-analyzer', 'coc-docker', 'coc-perl',
			\'@yaegassy/coc-nginx', 'coc-sql', 'coc-solargraph',
			\'coc-dlang', 'coc-snippets', 'coc-powershell',
			\'coc-texlab', 'coc-highlight', 'coc-explorer',
			\'coc-deno', 'coc-calc', 'coc-discord-rpc',
			\'coc-haxe', 'coc-ltex', 'coc-glslx',
			\'coc-omnisharp',
			\]

colorscheme nightfox

let g:python_highlight_all = 1

" To get rid of checkhealth warning
let g:python3_host_prog = '/bin/python'

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
let g:indentLine_setConceal = 0

" Rainbow leveled brackets
let g:rainbow_active = 1

" Disable zig autofmt on save
let g:zig_fmt_autosave = 0

" Lightline config
let g:lightline = {
			\'colorscheme': 'wombat',
			\'active': {
			\	'left': [['mode', 'paste'], ['readonly', 'relativepath', 'modified']],
			\	}
			\}

" Coc stuff
" Fix current line
nmap <leader>qf  <Plug>(coc-fix-current)
" Jump to definitin
nmap <leader>d :call CocAction('jumpDefinition', 'tabe')<CR>
" Open file explorer
nmap <leader>e <Cmd>CocCommand explorer<CR>
" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

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

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Manipulating tabs
nnoremap <leader>tn <cmd>tabnew<cr>

" Treesitter conf
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "lua", "vim", "query", "javascript", "typescript", "astro", "zig" },

  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
EOF

nnoremap <leader>u :UndotreeToggle<CR>
