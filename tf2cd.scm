(import pstk)

; parse libraryfolders.vdf to autocomplete sourcemods dir?
; maybe quicker to simply hardcode - check python version

(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; only initialize
(tk-set-var! 'userdir "")

(define label (tk 'create-widget 'label
		  'text: "sourcemods dir:"))

(define entry (tk 'create-widget 'entry
		  'text: (tk-get-var 'userdir)
		  'textvariable: (tk-var 'userdir)))

(define button (tk 'create-widget 'button
		   'text: "button"))

(tk/grid label 'row: 0 'column: 0 'columnspan: 3)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'sticky: 'ew 'padx: 10 'pady: 10)
(entry 'insert 0 "...steamapps/sourcemods")
(tk/grid button 'row: 1 'column: 4 'padx: 10)

(tk-event-loop)
