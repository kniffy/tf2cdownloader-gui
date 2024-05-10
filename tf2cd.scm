(import (r7rs)
	(chicken file)
	(chicken io)
	(chicken port)
	(chicken process)
	(chicken process-context)
	(chicken platform)
	(chicken string))

(import (pstk))

; set some platform-specific stuff
(cond-expand
  (windows
    (define tempdir "C:\\TEMP ")
    (define downloader "bin\\aria2c.exe ")
    (define butler "bin\\butler.exe ")
    (define defaultdir "c:\\program files (x86)\\steam\\steamapps\\sourcemods"))
  (linux
    (define tempdir "/var/tmp ")
    (define downloader "bin/aria2c ")
    (define butler "bin/butler ")
    (define defaultdir
      (let ((user (get-environment-variable "USER")))
	(conc "/home/" user "/.local/share/Steam/steamapps/sourcemods")))))

; maybe get rid of a lot of these
(define arialine
  (conc
    " "
;    "--show-console-readout=false "
    "--enable-color=false "
    "-x 16 "
    "-UTF2CDownloadergui2024-05-10 "
    "--allow-piece-length-change=true "
    "-j 16 "
    "--optimize-concurrent-downloads=true "
    "--check-certificate=false "
    "-V "
    "--auto-file-renaming=false "
    "-c "
    "--allow-overwrite=true "
    "--console-log-level=error "
    "--summary-interval=5 "
    "--bt-hash-check-seed=false "
    "--seed-time=0 "
    "-l aria.log "
    "-d "
    tempdir
    "http://fastdl.tildas.org/pub/100Mio.dat"))

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
			       (let ((cd (tk/choose-directory 'initialdir: defaultdir 'mustexist: 'true)))
				 (tk-set-var! 'userdir cd)))))
(define button1 (tk 'create-widget 'button
		    'text: "New Install"
		    'command: (lambda ()
				(installproc))))

(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'command: (lambda ()
				(upgradeproc))))

(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'command: (lambda ()
				(verifyproc))))

(define statusbox (tk 'create-widget 'text
		      'height: 10
		      'undo: 'false
		      'relief: 'sunken
		      'wrap: 'word
		      'state: 'disabled))

; actually drawing the window and placing positions
; for readability, keep the same order as definitions
(tk/grid label0 'row: 0 'column: 0 'pady: 10)
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'padx: 10)
(tk/grid button0 'row: 1 'column: 3 'padx: 10)		; browse
(tk/grid button1 'row: 4 'column: 0 'pady: 10)		; install
(tk/grid button2 'row: 4 'column: 1)			; upgrade
(tk/grid button3 'row: 4 'column: 2)			; verify
(tk/grid statusbox 'row: 6 'column: 0 'columnspan: 4)

(entry 'insert 0 defaultdir)  ; we cant put this in the initialization

; our button click procedures etc below
(define installproc
  (lambda ()
    (let-values (((a b c) (process (conc downloader arialine))))
      (begin
	(buttonstate 0)
	(statusstate 1)
	(statusstate 2)
	(statusbox 'insert 'end "Download starting.. \n")

	(with-input-from-port a (lambda ()
				  (port-for-each (lambda (word)
						   (statusbox 'insert 'end word)
						   (statusbox 'insert 'end "\n")
						   (statusbox 'see 'end))
						 read-line)))
; this is an empty line ======================================================
	(close-input-port a)
	(close-output-port b)
	(statusstate 0)
	(buttonstate 1)))))

(define upgradeproc
  (lambda ()
    (display "clicked upgrade")))

(define verifyproc
  (lambda ()
    (display "clicked verify")))

;(define untar
  ; todo call tar as subprocess
  ; also figure out doing it on windows
;)

(define buttonstate
  (let ((dis "state disabled"))
    (lambda (z)
      (if (zero? z)
	(begin
	  (button0 dis)
	  (button1 dis)
	  (button2 dis)
	  (button3 dis))
	(begin
	  (button0 'configure 'state: 'normal)
	  (button1 'configure 'state: 'normal)
	  (button2 'configure 'state: 'normal)
	  (button3 'configure 'state: 'normal))))))

; 0 - disable text box
; 1 - enable text box
; 2 - clear text box
(define statusstate
  (lambda (z)
    (cond
      ((zero? z) (statusbox 'configure 'state: 'disabled))
      ((= 1 z) (statusbox 'configure 'state: 'normal))
      ((= 2 z) (statusbox 'delete '1.0 'end)))))

(tk-event-loop)
