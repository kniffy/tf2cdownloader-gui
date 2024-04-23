(import pstk)

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
		  'textvariable: (tk-var 'userdir)
		  'width: 50))

; we can probably get a boilerplate button definition
(define button0 (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ((cd (tk/choose-directory 'initialdir: "/tmp" 'mustexist: 'true)))
				 (tk-set-var! 'userdir cd)))))
(define button1 (tk 'create-widget 'button
		    'text: "Install"
		    'command: (lambda ()
				(display "clicked install"))))
(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'command: (lambda ()
				(display "clicked upgrade"))))
(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'command: (lambda ()
				(display "clicked verify"))))

; actually drawing the window and placing positions
; spacers first, we want at least 1 x at the lowest row
; for readability, keep the same order as definitions
(tk/grid label0 'row: 0 'column: 0 'pady: 10)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'padx: 10)
(tk/grid button0 'row: 1 'column: 3)	; browse
(tk/grid button1 'row: 4 'column: 0)	; install
(tk/grid button2 'row: 4 'column: 1)	; upgrade
(tk/grid button3 'row: 4 'column: 2)	; verify

(entry 'insert 0 "Steam/steamapps/sourcemods")  ; we cant put this in the initialization
(tk-event-loop)
