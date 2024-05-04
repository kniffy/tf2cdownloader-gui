(import (chicken io)
	(chicken process)
	(chicken platform)
	(chicken string)
	(srfi-34))

(import pstk
	simple-loops)


; set some platform-specific stuff
(cond-expand
  (windows
    (define tempdir "C:\\TEMP ")
    (define downloader "bin\\aria2c.exe ")
    (define butler "bin\\butler.exe "))
  (linux
    (define tempdir "/var/tmp ")
    (define downloader "bin/aria2c ")
    (define butler "bin/butler ")))

; maybe get rid of a lot of these
;(define arialine
;  (conc
;    "-x 16 "
;    "-UTF2CDownloadergui2024-04-24 "
;    "--allow-piece-length-change=true "
;    "-j 16 "
;    "--optimize-concurrent-downloads=true "
;    "--check-certificate=false "
;    "-V "
;    "--auto-file-renaming=false "
;    "-c "
;    "--allow-overwrite=true "
;    "--console-log-level=error "
;    "--summary-interval=0 "
;    "--bt-hash-check-seed=false "
;    "--seed-time=0 "
;    "-d "
;    tempdir))
(define arialine
  (conc
    "-l aria.log "
    "--log-level=info "
    "-d "
    tempdir
    "http://check.ovh.com/files/1Mio.dat"))

(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; for some reason we must 'initialize' tk vars like so
(tk-var 'userdir)
;(tk-var 'progbar)

; widget definitions
;(define spacerx (tk 'create-widget 'frame 'width: 400))
;(define spacery (tk 'create-widget 'frame 'height: 400))
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
				(let ((porg "100"))
				  (button1 'state "disabled")
				  (system (conc downloader arialine))
				  (statusbox 'insert 'end "uhh")))))
;				  (tk-set-var! 'progbar porg)))))
(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'command: (lambda ()
				(display "clicked upgrade"))))
(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'command: (lambda ()
				(display "clicked verify"))))
;(define progress (tk 'create-widget 'progressbar
;		     'length: 400
;		     'variable: (tk-var 'progbar)))
(define statusbox (tk 'create-widget 'text
		   'height: 5
		   'undo: 'false
		   'relief: 'sunken))

; actually drawing the window and placing positions
; for readability, keep the same order as definitions
(tk/grid label0 'row: 0 'column: 0 'pady: 10)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'padx: 10)
(tk/grid button0 'row: 1 'column: 3 'padx: 10)	; browse
(tk/grid button1 'row: 4 'column: 0 'pady: 10)	; install
(tk/grid button2 'row: 4 'column: 1)	; upgrade
(tk/grid button3 'row: 4 'column: 2)	; verify
;(tk/grid progress 'row: 5 'column: 0 'columnspan: 3)
(tk/grid statusbox 'row: 6 'column: 0 'columnspan: 4)

(entry 'insert 0 "Steam/steamapps/sourcemods")  ; we cant put this in the initialization
(statusbox 'insert 'end "uhh")

(tk-event-loop)
