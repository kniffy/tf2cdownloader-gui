(import pstk)

; parse libraryfolders.vdf to autocomplete sourcemods dir?
; maybe quicker to simply hardcode - check python version

(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; for some reason we must 'initialize' tk vars like so
(tk-set-var! 'userdir "")

; widget definitions
(define spacerx (tk 'create-widget 'frame 'width: 400))
(define spacery (tk 'create-widget 'frame 'height: 400))
(define label0 (tk 'create-widget 'label 'text: "sourcemods directory:"))
(define label1 (tk 'create-widget 'label 'text: "tf2c detected:"))

(define entry (tk 'create-widget 'entry
		  'text: (tk-get-var 'userdir)
		  'textvariable: (tk-var 'userdir)
		  'width: 50))

(define button (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ((cd (tk/choose-directory 'initialdir: "/tmp" 'mustexist: 'true)))
				 (tk-set-var! 'userdir cd)))))

; actually drawing the window and placing positions
; spacers first, we want at least 1 x at the lowest row
; for readability, keep the same order as definitions
(tk/grid spacerx 'row: 3 'column: 0 'pady: 5)	; mind the row number
(tk/grid label0 'row: 0 'column: 0 'pady: 10)
(tk/grid label1 'row: 2 'column: 0)
(tk/grid entry 'row: 1 'column: 0 'sticky: 'ew 'padx: 10)
(entry 'insert 0 "Steam/steamapps/sourcemods") ; we cant put this in the initialization
(tk/grid button 'row: 1 'column: 2 'padx: 10)


(tk-event-loop)
