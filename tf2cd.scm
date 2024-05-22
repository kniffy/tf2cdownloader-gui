(import (r7rs)
	(chicken file)
	(chicken io)
	(chicken port)
	(chicken process)
	(chicken process-context)
	(chicken platform)
	(chicken string))

(import (pstk))

; TODO boilerplate the subprocess procedures
; we need to call it multiple times, its too complex
; to type every time

; set some platform-specific stuff
(cond-expand
  (windows
    (define tempdir "C:\\TEMP")
    (define downloader "bin\\aria2c.exe")
    (define butler "bin\\butler.exe")
    (define defaultdir "c:\\program files (x86)\\steam\\steamapps\\sourcemods")
    (define zstd "bin\\zstd.exe"))
  (linux
    (define tempdir "/var/tmp")
    (define downloader "bin/aria2c")
    (define butler "bin/butler")
    (define defaultdir
      (let ((user (get-environment-variable "USER")))
	(conc "/home/" user "/.local/share/Steam/steamapps/sourcemods")))
    (define zstd "zstd")))

; returns size in kb
; we define a list and not a bigass string so as to not call
; a whole shell for the subprocess; we dont want to touch shell quotations
(define freespaceline	; todo check windows output
  (list "--output=avail" tempdir))

; todo generalize a bit, when called we'll add the file to leech to the end of
; the list
(define arialine
  (list
    "--enable-color=false"
    "-x 16"
    "-UTF2CDownloadergui2024-05-10"
    "--allow-piece-length-change=true"
    "-j 16"
    "--optimize-concurrent-downloads=true"
    "--check-certificate=false"
    "-V"
    "--auto-file-renaming=false"
    "-c"
    "--allow-overwrite=true"
    "--console-log-level=error"
    "--summary-interval=5"
    "--bt-hash-check-seed=false"
    "--seed-time=0"
    "-d"
    tempdir
    "http://fastdl.tildas.org/pub/downloader/tf2classic-latest.meta4"))

(define butlerline
  (list))

; init
(tk-start "tclsh8.6") ; default calls tclsh8.6 - we will use tclkit
(ttk-map-widgets 'all) ; use the ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

; for some reason we must 'initialize' tk vars like so
(tk-var 'userdir)

; widget definitions
(define label0 (tk 'create-widget 'label 'text: "sourcemods directory:"))
;(define label1 (tk 'create-widget 'label 'text: "tf2c detected:"))

(define entry (tk 'create-widget 'entry
		  'textvariable: (tk-var 'userdir)
		  'width: 55))

(define button0 (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ((cd (tk/choose-directory 'initialdir: defaultdir 'mustexist: 'true)))
				 (begin
				   (tk-set-var! 'userdir cd)
				   (freespaceproc (tk-get-var 'userdir))
				   (patchfile))))))

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
		      'height: 12
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

(entry 'insert 0 defaultdir)		; we cant put this in the initialization

; we need some definitions down here to get around delayed-eval gremlins
; tk is a fuck with touching its precious variables, so we call tk-get-var
; todo check for file existence first
(define patchfile
  (lambda ()
    (let ([dir (tk-get-var 'userdir)] [file "/tf2classic/rev.txt"])
      (if (file-exists? (conc dir file))
	(let ([ver (string->number (read-line (open-input-file (conc dir file))))])
	  (define full (conc "tf2classic-patch" (- 1 ver) "-" ver ".pwr"))
	  (begin
	    (statusstate 1)
	    (statusbox 'insert 'end "tf2c install found?")
	    (statusstate 0)))
	(begin	; else case
	  (statusstate 1)
	  (statusbox 'insert 'end "tf2c installation not found\n")
	  (statusstate 0))))))

; our button click procedures etc below
; mind the parentheses, this bit is a mess
(define installproc
  (lambda ()
    (let-values (((a b c) (process downloader arialine)))
      (begin
	(buttonstate 0)
	(statusstate 1)
	(statusstate 2)
	(statusbox 'insert 'end "Download starting.. \n")

	(with-input-from-port a (lambda ()
		(port-for-each (lambda (word)
				 (statusbox 'insert 'end (conc word "\n" ))
				 (statusbox 'see 'end))
			       read-line)))
; ===== this is an empty line ================================================
	(close-input-port a)
	(close-output-port b)	; we must close ports to exit aria2

	(statusbox 'insert 'end "\n Preparing to unpack..\n")
	(sleep 5)

	; fuck it we ball (unpack)
	(statusbox 'insert 'end "Unpacking.. \n")
	(let-values (((d e f g) (process* (conc "bin/tar -kxv -I bin/zstd -f " tempdir "/tf2classic-?.?.?.tar.zst -C " (tk-get-var 'userdir)))))
	  (with-input-from-port d (lambda ()
		(port-for-each (lambda (word)
				 (statusbox 'insert 'end (conc word "\n"))
				 (statusbox 'see 'end))
			       read-line)))
	  (statusbox 'insert 'end "\n checking for error output..\n")
	  (statusbox 'see 'end)
	  (sleep 2)
; ===== this is an empty line ================================================
	  (with-input-from-port g (lambda()
		(port-for-each (lambda (word)
				 (statusbox 'insert 'end (conc word "\n"))
				 (statusbox 'see 'end))
			       read-line)))
; ===== this is an empty line ================================================
	  (close-input-port d)
	  (close-output-port e)
	  (close-input-port g)
	  (statusbox 'insert 'end "\n Unpacked!")
	  (statusbox 'see 'end))

	(statusstate 0)
	(buttonstate 1)))))

(define upgradeproc
  (lambda ()
    (let-values (((a b c) (process (conc butler butlerline))))
      (begin
	(buttonstate 0)
	(statusstate 1)
	(statusstate 2)
	(statusbox 'insert 'end "Upgrading.. \n")))))

(define verifyproc
  (lambda ()
    (display "clicked verify")))

; todo make this macro
;(define subproc
;  (lambda (cmd . args)))

(define freespaceproc
  (lambda (dir)
    (let-values (((x y z a) (process* "bin/df" (list "--output=avail" dir))))
      (with-input-from-port x (lambda ()
	(port-for-each (lambda (word)
			 (if (string->number word)
			   (let ((p (string->number word)))
			     (if (< p 20000000)
			       (begin	;if
				 (statusstate 1)
				 (statusbox 'insert 'end "Free space check: Failed?\n at least 20gb needed!\n")
				 (statusstate 0))
			       (begin	;else
				 (statusstate 1)
				 (statusbox 'insert 'end "Free space check: Passed\n")
				 (statusstate 0))))))
		       read-line)))
      (close-input-port x)
      (close-output-port y)
      (close-input-port a))))

(define buttonstate
  (let ((dis "state disabled"))
    (lambda (z)
      (if (zero? z)
	(begin
	  (button0 dis)
	  (button1 dis)
	  (button2 dis)
	  (button3 dis))
	(begin	; for some fucking reason we cant boilerplate this bit
	  (button0 'configure 'state: 'normal)
	  (button1 'configure 'state: 'normal)
	  (button2 'configure 'state: 'normal)
	  (button3 'configure 'state: 'normal))))))

; 0, 1, 2 - disable, enable, clear
(define statusstate
  (lambda (z)
    (cond
      ((zero? z) (statusbox 'configure 'state: 'disabled))
      ((= 1 z) (statusbox 'configure 'state: 'normal))
      ((= 2 z) (statusbox 'delete '1.0 'end)))))

(tk-event-loop)
