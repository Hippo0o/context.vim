let s:activated     = 0
let s:ignore_update = 0

" call this on VimEnter to activate the plugin
function! context#activate() abort
    " for some reason there seems to be a race when we try to show context of
    " one buffer before another one gets opened in startup
    " to avoid that we wait for startup to be finished
    let s:activated = 1
    call context#update('activate')
endfunction

function! context#enable() abort
    let g:context.enabled = 1
    call context#update('enable')
endfunction

function! context#disable() abort
    let g:context.enabled = 0

    if g:context.presenter == 'preview'
        call context#preview#close()
    else
        call context#popup#clear()
    endif
endfunction

function! context#toggle() abort
    if g:context.enabled
        call context#disable()
    else
        call context#enable()
    endif
endfunction

function! context#update(source) abort
    if 0
                \ || !g:context.enabled
                \ || !s:activated
                \ || s:ignore_update
                \ || &previewwindow
                \ || mode() != 'n'
        return
    endif

    let winid = win_getid()

    if !exists('w:context')
        let w:context = {
                    \ 'lines_top':     [],
                    \ 'lines_bottom':  [],
                    \ 'pos_y':         0,
                    \ 'pos_x':         0,
                    \ 'size_h':        0,
                    \ 'size_w':        0,
                    \ 'cursor_offset': 0,
                    \ 'indent':        0,
                    \ 'needs_layout':  0,
                    \ 'needs_move':    0,
                    \ 'needs_update':  0,
                    \ 'padding':       0,
                    \ 'top_line':      0,
                    \ }
    endif

    call context#util#update_state()
    call context#util#update_window_state(winid)

    if w:context.needs_update || w:context.needs_layout || w:context.needs_move
        call context#util#echof()
        call context#util#echof('> context#update', a:source)
        call context#util#log_indent(2)

        if g:context.presenter == 'preview'
            let s:ignore_update = 1

            if w:context.needs_update
                let w:context.needs_update = 0
                call context#preview#update_context()
            endif

            let s:ignore_update = 0

        else " popup
            if w:context.needs_update
                let w:context.needs_update = 0
                call context#popup#update_context()
            endif

            if w:context.needs_layout
                let w:context.needs_layout = 0
                call context#popup#layout()
            endif

            if w:context.needs_move
                let w:context.needs_move = 0
                call context#popup#redraw(winid, 0)
            endif
        endif

        call context#util#log_indent(-2)
    endif
endfunction
