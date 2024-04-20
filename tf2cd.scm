(import (chicken port))
(import pstk)

; parse libraryfolders.vdf to autocomplete sourcemods dir?
; maybe quicker to simply hardcode - check python version

(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; only initialize
(tk-set-var! 'userdir "")

; widget definitions
(define label (tk 'create-widget 'label
		  'text: "sourcemods dir:"))

(define entry (tk 'create-widget 'entry
		  'text: (tk-get-var 'userdir)
		  'textvariable: (tk-var 'userdir)))

(define button (tk 'create-widget 'button
		   'text: "button"
		   'command: (lambda ()
			       (let ((cd (tk/choose-directory 'initialdir: "/tmp" 'mustexist: 'true)))
				 (call-with-input-string
				   cd
				   (lambda (input-port)
				     (tk-set-var! 'userdir input-port)))))))

(define spacerx (tk 'create-widget 'frame
		   'width: 400))
(define spacery (tk 'create-widget 'frame
		    'height: 400))

; actually drawing the window and placing positions
(tk/grid label 'row: 0 'column: 0 'columnspan: 4 'padx: 10)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 7 'sticky: 'ew 'padx: 10 'pady: 10)
(entry 'insert 0 "...steamapps/sourcemods")
(tk/grid button 'row: 1 'column: 8 'padx: 10)
(tk/grid spacerx 'row: 2 'column: 0 'columnspan: 8)	; force the width

(tk-event-loop)
