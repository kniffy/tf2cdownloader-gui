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

(tk/grid label 'row: 0 'columnspan: 3)
(tk/grid entry 'row: 1 'columnspan: 3 'sticky: 'ew 'padx: 20 'pady: 10)

(tk-event-loop)
