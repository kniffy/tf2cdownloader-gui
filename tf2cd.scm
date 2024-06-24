(import (chicken file)
	(chicken file posix)
	(chicken format)
	(chicken io)
	(chicken pathname)
	(chicken port)
	(chicken process)
	(chicken process-context)
	(chicken platform)
	(chicken string)
	(chicken time))

(import (pstk))

; NOTE our variable definitions generally go up here,
; but for cursed reasons some of them are below, under
; the tk gui block, tk is a bitch with passing vars

(define *downloader* (make-pathname "bin" "aria2c"))
(define *butler* (make-pathname "bin" "butler"))
(define *ttccll* (make-pathname "bin" "tclkit"))
(define *df* (make-pathname "bin" "df" "exe"))
(define *tar* (make-pathname "bin" "tar" "exe"))
(define *zstd* (make-pathname "bin" "zstd" "exe"))

; set some platform-specific stuff
; TODO switch paths to more sane choices, build up with make-pathname
(cond-expand
  (windows
   (set! *downloader* (pathname-replace-extension *downloader* "exe"))
   (set! *butler* (pathname-replace-extension *butler* "exe"))
   (set! *ttccll* (pathname-replace-extension *ttccll* "exe"))

   (define *tempdir* "C:\\TEMP")
   (define *defaultdir* "c:\\program files (x86)\\steam\\steamapps\\sourcemods"))

  (linux
    (define *tempdir* "/var/tmp")
    (define *defaultdir*
      (let ([user (get-environment-variable "USER")])
	(conc "/home/" user "/.local/share/Steam/steamapps/sourcemods")))))

; returns size in kb
; we define a list and not a bigass string so as to not call
; a whole shell for the subprocess; we dont want to touch shell quotations
(define *freespaceline* (list "--output=avail"))

(define *arialine*
  (list
    "--enable-color=false"
    "-x 16"
    "-UTF2CDownloadergui2024-06-24"
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
    *tempdir*))

(define *ariaversionline*
  (list "--enable-color=false"
        "-UTF2CDownloadergui2024-06-24"
        "--allow-overwrite=true"
        "-d"
        *tempdir*))

; we append multiple args to some of these later
(define *unpackline* (list "-kxv" "-I" *zstd* "-f"))

(define *butlerpatchline*
  (list "apply"
	(conc "--staging-dir=" (conc *tempdir* "/staging"))))

; this is evaluated out below in the verify procedure
;(define butlerverifyline)

(define *partialurl* "http://fastdl.tildas.org/pub/downloader")
(define *fulltarballurl* 0)
(define *revtxt* "current")

(define *masterurl* "https://wiki.tf2classic.com/kachemak/")

; we set this later in the version detection procedure
(define *patchfile* 0)
(define *healfile* 0)

; tk init
(tk-start *ttccll*)
(ttk-map-widgets 'all) ; use the ttk widget set
(ttk/set-theme "clam")
(tk/wm 'title tk "tf2cdownloader")
(tk/wm 'resizable tk 0 0)

; we must initialize tk vars like so
(tk-var 'userdir)
(tk-var 'selectedversion)

; widget definitions
(define label0 (tk 'create-widget 'label 'text: "sourcemods directory:"))

(define entry (tk 'create-widget 'entry
		  'textvariable: (tk-var 'userdir)
		  'width: 55))

(define button0 (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ([cd (tk/choose-directory 'initialdir: *defaultdir* 'mustexist: 'true)])
				 (begin
				   (tk-set-var! 'userdir cd)
				   (freespaceproc (tk-get-var 'userdir))
				   (findlatestversion)
				   (versiondetectproc))))))

(define button1 (tk 'create-widget 'button
		    'text: "New Install"
		    'command: (lambda () (installproc))))

(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'state: 'disabled
		    'command: (lambda () (upgradeproc))))

(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'state: 'disabled
		    'command: (lambda () (verifyproc))))

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

(entry 'insert 0 "pick a dir :^)")		; we cant put this in the initialization

; we need some definitions down here to get around delayed-eval gremlins
; tk is a fuck with touching its precious variables, so we call tk-get-var
(define *currentver*)
(define *latestver*)
(define *dotlatestver*)

(define findlatestversion
  (lambda ()
    (let ([foo (conc *tempdir* "/" *revtxt*)])
      (if (file-exists? foo)
	(begin    ; true case
	  (let* ([filetime (file-modification-time foo)] [differ (- (current-seconds) filetime)])
	    (if (> differ 3600)
	      (findlatestversion-get))))
	(findlatestversion-get))  ; false case of outer if

      (let ([ver (string->number (read-line (open-input-file (conc *tempdir* "/" *revtxt*))))])
	(set! *latestver* ver)))))

(define findlatestversion-get
  (lambda ()
    (let-values ([(a b c) (process *downloader* (append *ariaversionline* (list (conc *partialurl* "/" *revtxt*))))])
      (begin
	(display->status a) ; we need to clear the port to close it but we dont want to display it
	(close-input-port a)
	(close-output-port b)))))

; this is fucking cursed, but we must account for malformed or
; erroneous rev.txt entries
(define versiondetectproc
  (lambda ()
    (let ([dir (tk-get-var 'userdir)]
	  [file "/tf2classic/rev.txt"] [full ""]
	  [dotlatestver (string-intersperse (string-chop (number->string *latestver*) 1) ".")])

      ; we gotta set this to global var to work around glob gremlins in the unpack proc
      (set! *dotlatestver* dotlatestver)

      (if (file-exists? (conc dir file))
	(let* ([ver (string->number (read-line (open-input-file (conc dir file))))]
	       [dotver (string-intersperse (string-chop (number->string ver) 1) ".")])

	  (set! *currentver* ver)
	  (set! *healfile* (conc "tf2classic-" dotver "-heal.zip"))

	  (unless (= ver *latestver*)
	    (set! *patchfile* (conc "tf2classic-patch" "-" ver "-" *latestver* ".pwr"))
	    (set! *fulltarballurl* (conc *masterurl* "tf2classic-" dotlatestver ".meta4"))  ; metalink, not the literal tarball
	    (set! full *patchfile*))

	  (begin
	    (statusstate 1)
	    (statusbox 'insert 'end "tf2c installation: found\n")
	    (statusbox 'insert 'end (conc "version " ver " detected\n"))

	    (if [or (< ver 203) (> ver 230)]
	      (begin  ; true case
		(statusbox 'insert 'end "malformed version number?\n")))

	    (button2 'configure 'state: 'normal)
	    (button3 'configure 'state: 'normal)
	    (statusstate 0)))

	(begin	; else case
	  (statusstate 1)
	  (button2 'state 'disabled)
	  (button3 'state 'disabled)
	  (set! *fulltarballurl* (conc *masterurl* "tf2classic-" dotlatestver ".meta4"))
	  (statusbox 'insert 'end "tf2c installation: not found\n")
	  (statusstate 0))))))

(define installproc
  (lambda ()
    (let*-values ([(rid) (tk-get-var 'userdir)] [(a b c) (process *downloader* (append *arialine* (list *fulltarballurl*)))])
      (begin
	(buttonstate 0)
	(statusstate 1)
	(statusstate 2)
	(display->status a)   ; print the process's console
	(close-input-port a)
	(close-output-port b)	; we must close ports to exit subprocess

	(sleep 5)

	; fuck it we ball (unpack)
	(statusbox 'insert 'end "Unpacking.. \n")

	; we know the latest version already, so just append to the args list
	; no need to worry about users cleaning up first :^)
	(set! *unpackline* (append *unpackline* (list (conc *tempdir* "/tf2classic-" *dotlatestver* ".tar.zst"))))

	(let-values ([(d e f g) (process* *tar* (append *unpackline* (list "-C" rid)))])
	  (display->status d)
	  (statusbox 'insert 'end "\n")
	  (sleep 2)
	  (display->status g)
	  (close-input-port d)
	  (close-output-port e)
	  (close-input-port g)
	  (statusbox 'insert 'end "\n Unpacked!\n")
	  (statusbox 'see 'end))

	(statusstate 0)))))

(define upgradeproc
  (lambda ()
    (if (not (= *currentver* *latestver*))
      (if (string? *patchfile*)
	(let*-values ([(rid) (tk-get-var 'userdir)]
		      [(a b c) (process *downloader* (append *arialine* (list (conc *masterurl* *patchfile*))))])
	  (begin
	    (buttonstate 0)
	    (statusstate 1)
	    (statusstate 2)
	    (display->status a)
	    (close-input-port a)
	    (close-output-port b)

	    (statusbox 'insert 'end "verifying before patching..\n")
	    (sleep 5)
	    (verifyproc)
	    (buttonstate 0) ; verify proc sets these off, we still need it here
	    (statusstate 1)

	    ; now we set up wot butler will do
	    (create-directory (conc *tempdir* "/staging"))  ; does butler need this? we copy reference behavior

	    (let*-values ([(tf2cdir) (conc rid "/tf2classic")]
			  [(patchpath) (conc *tempdir* "/" *patchfile*)]
			  [(x y z e) (process* *butler* (append *butlerpatchline* (list patchpath tf2cdir)))])
	      (begin
		(statusbox 'insert 'end "applying patch..\n")
		(display->status x)
		(display->status e)
		(close-input-port x)
		(close-output-port y)
		(close-input-port e)
		(statusbox 'insert 'end "patched?\n")))

	    (statusstate 0)
	    (buttonstate 1)))

	(begin
	  (statusstate 1)
	  (statusbox 'insert 'end "patchfile is null?\n")
	  (statusstate 0)))

      (begin	; outermost if, when at latest version
	(statusstate 1)
	(statusbox 'insert 'end "tf2c at latest version!\n")
	(statusstate 0)))))

; butler verify cli is fairly simple,
; we simply pass in URLs to the master
; sig+heal files
; eg bin/butler verify https://wiki.tf2classic.com/kachemak/tf2classic214.sig /var/tmp/Q/tf2classic
; --heal=archive,https://wiki.tf2classic.com/kachemak/tf2classic-2.1.4-heal.zip
(define verifyproc
  (lambda ()
    (let*-values ([(rid) (tk-get-var 'userdir)]
		  [(butlerverifyline) (list "verify"
					    (conc *masterurl* "tf2classic" *currentver* ".sig")
					    (conc rid "/tf2classic")
					    (conc "--heal=archive," *masterurl* *healfile*))])

      (let-values ([(a b c d) (process* *butler* butlerverifyline)])
	(begin
	  (buttonstate 0)
	  (statusstate 1)
	  (display->status a)
	  (close-input-port a)
	  (close-output-port b)
	  (display->status d)
	  (close-input-port d)

	  (statusbox 'insert 'end "verified?\n")
	  (statusstate 0)
	  (buttonstate 1))))))

(define freespaceproc
  (lambda (dir)
    (let-values ([(x y z a) (process* *df* (append *freespaceline* (list dir)))])
      (with-input-from-port x (lambda ()
        (port-for-each (lambda (word)
          (if (string->number word)
            (let ([p (string->number word)])
	      (if (< p 20000000)
		(begin	; true case
		  (statusstate 1)
		  (statusbox 'insert 'end "Free space check: Failed?\n at least 20gb needed!\n")
		  (statusstate 0))
		(begin	; else case
		  (statusstate 1)
		  (statusbox 'insert 'end "Free space check: Passed\n")
		  (statusstate 0))))))
		       read-line)))
      (close-input-port x)
      (close-output-port y)
      (close-input-port a))))

; input is a port, iterates and prints the lines to the status box widget
; until it hits EOF - dont forget setting the box's state before/after use
(define display->status
  (lambda (port)
    (with-input-from-port port
		  (lambda ()
        (port-for-each (lambda (word)
                         (statusbox 'insert 'end (conc word "\n"))
                         (statusbox 'see 'end))
                       read-line)))))

; we simplify some of the management of state
(define buttonstate
  (let ([dis "state disabled"])
    (lambda (z)
      (if (zero? z)
	(begin
	  (button0 dis)
	  (button1 dis)
	  (button2 dis)
	  (button3 dis))
	(begin	; for some fucking reason we cant boilerplate this bit?
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
