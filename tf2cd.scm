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
(define arialine
  (conc
    "--show-console-readout=false "
    "-x 16 "
    "-UTF2CDownloadergui2024-04-24 "
    "--allow-piece-length-change=true "
    "-j 16 "
    "--optimize-concurrent-downloads=true "
    "--check-certificate=false "
    "-V "
    "--auto-file-renaming=false "
    "-c "
    "--allow-overwrite=true "
    "--console-log-level=error "
    "--summary-interval=0 "
    "--bt-hash-check-seed=false "
    "--seed-time=0 "
    "-l aria.log "
    "-d "
    tempdir
    "http://fastdl.tildas.org/pub/1Mio.dat"))

; we need some procedures
(define installproc
  (delay
    (let ((proc (process (conc downloader arialine))))
      (let ((output (read-list proc)))
	(begin
	  (statusbox 'insert 'end output))))))
(define disablebuttons
  (lambda ()
    (button1 'state 'disabled)
    (button2 'state 'disabled)
    (button3 'state 'disabled)
    (button0 'state 'disabled)))
(define enablebuttons
  (lambda ()
      (button1 'configure
	       'state: 'normal)
      (button2 'configure
	       'state: 'normal)
      (button3 'configure
	       'state: 'normal)
      (button0 'configure
	       'state: 'normal)))
(define clearstatus
  (lambda ()
    (statusbox 'delete '1.0 'end)))

; init
(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; for some reason we must 'initialize' tk vars like so
(tk-var 'userdir)

; widget definitions
(define label0 (tk 'create-widget 'label 'text: "sourcemods directory:"))
(define label1 (tk 'create-widget 'label 'text: "tf2c detected:"))

(define entry (tk 'create-widget 'entry
		  'textvariable: (tk-var 'userdir)
		  'width: 55))

; we can probably get a boilerplate button definition
(define button0 (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ((cd (tk/choose-directory 'initialdir: "/tmp" 'mustexist: 'true)))
				 (tk-set-var! 'userdir cd)))))
(define button1 (tk 'create-widget 'button
		    'text: "Install"
		    'command: (lambda ()
				(begin
				  (disablebuttons)
				  (clearstatus)
				  (statusbox 'insert 'end "Download starting... \n\n")
				  (force installproc)
				  (enablebuttons)))))
(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'command: (lambda ()
				(begin
				  (disablebuttons)
				  (clearstatus)
				  (statusbox 'insert 'end "Clicked Upgrade.. \n\n")
				  (enablebuttons)))))
(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'command: (lambda ()
				(display "clicked verify"))))
(define statusbox (tk 'create-widget 'text
		      'height: 5
		      'undo: 'false
		      'relief: 'sunken
		      'wrap: 'word))

; actually drawing the window and placing positions
; for readability, keep the same order as definitions
(tk/grid label0 'row: 0 'column: 0 'pady: 10)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'padx: 10)
(tk/grid button0 'row: 1 'column: 3 'padx: 10)	; browse
(tk/grid button1 'row: 4 'column: 0 'pady: 10)	; install
(tk/grid button2 'row: 4 'column: 1)	; upgrade
(tk/grid button3 'row: 4 'column: 2)	; verify
(tk/grid statusbox 'row: 6 'column: 0 'columnspan: 4)

(entry 'insert 0 "Steam/steamapps/sourcemods")  ; we cant put this in the initialization

(tk-event-loop)
