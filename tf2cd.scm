(import (chicken condition)
	(chicken file)
	(chicken io)
	(chicken pathname)
	(chicken port)
	(chicken process)
	(chicken process-context)
	(chicken string)
	(srfi-18))

(import (json-abnf)
	(pstk))

; NOTE our variable definitions generally go up here,
; but for cursed reasons some of them are below, under
; the tk gui block, tk is a bitch with passing vars

(define *downloader* (make-pathname "bin" "aria2c"))
(define *butler* (make-pathname "bin" "butler"))
(define *curl* (make-pathname "bin" "curl")) ; vendored curl for http3
(define *tar* "tar")
(define *ttccll* (make-pathname "bin" "tclkit"))
(define *zstd* "zstd")

; set some platform-specific stuff
(cond-expand
  (windows
   (set! *downloader* (pathname-replace-extension *downloader* "exe"))
   (set! *butler* (pathname-replace-extension *butler* "exe"))
   (set! *curl* (pathname-replace-extension *curl* "exe"))
   (set! *tar* (make-pathname "bin" "tar.exe"))
   (set! *ttccll* (pathname-replace-extension *ttccll* "exe"))
   (set! *zstd* (make-pathname "bin" "zstd.exe"))

   (define *tempdir* (get-environment-variable "TEMP"))
   (define *defaultdir* "c:\\program files (x86)\\steam\\steamapps\\sourcemods")

   (define *theme* "xpnative")
   (define *progbarsize* 644)

   (display "starting..\n you didnt use the launcher to run this :^)\n"
	    (current-error-port))
   (display "error output will display in this window\n" (current-error-port)))

  (linux
    (define *tempdir* (make-absolute-pathname "var" "tmp"))
    (define *defaultdir*
      (let ([user (get-environment-variable "USER")])
	(make-absolute-pathname (list "home" user ".local" "share" "Steam" "steamapps") "sourcemods")))

    (define *theme* "clam")
    (define *progbarsize* 566)))

(define *ariaargs*
  (list
    "--enable-color=false"
    "-x 16"
    "-UTF2CDownloadergui2025-01-30"
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

; we append multiple args to some of these later
(define *unpackargs* (list "-I" *zstd* "-xvf"))

(define *butlerpatchargs*
  (list "apply" (conc "--staging-dir=" *tempdir* "/staging")))

; TODO generalize; support open fortress etc
; '() means null, resist the urge to touch them
(define *masterurl* "https://wiki.tf2classic.com/kachemak/")
;(define *slaveurl* "https://file.tildas.org/pub/tf2classic/") ; needed any more?
(define *fulltarballurl* '())
(define *patchfile* '())
(define *patchfileurl* '())
(define *healfile* '())
(define *currentver* '())
(define *latestver* '())
(define *dotlatestver* '())

(define *sex* '()) ; whole parsed versions.json

; tk init
(tk-start *ttccll*)
(ttk-map-widgets 'all) ; use the ttk widget set
(ttk/set-theme *theme*)
(tk/wm 'title tk "tf2classic downloader")
(tk/wm 'resizable tk 0 0) ; dont let user resize window
(tk-eval "fconfigure stdin -encoding utf-8") ; ensure utf8 mode
(tk-eval "fconfigure stdout -encoding utf-8")

; TK VARS! we gotta define them like this
(tk-var 'userdir)
(tk-var 'progress)

; widget definitions
(define entry (tk 'create-widget 'entry
		  'textvariable: (tk-var 'userdir)
		  'width: 55))

(define button0 (tk 'create-widget 'button
		   'text: "Browse"
		   'command: (lambda ()
			       (let ([cd (tk/choose-directory 'initialdir: *defaultdir* 'mustexist: 'true)])
				 (begin
				   (prog 'configure 'length: (tk/winfo 'width statusbox)) ; bug workaround
				   (tk-set-var! 'userdir cd)
				   (findlatestversion)
				   (versiondetectproc))))))

(define button1 (tk 'create-widget 'button
		    'text: "New Install"
		    'state: 'disabled
		    'command: (lambda () (installproc))))

(define button2 (tk 'create-widget 'button
		    'text: "Upgrade"
		    'state: 'disabled
		    'command: (lambda () (upgradeproc))))

(define button3 (tk 'create-widget 'button
		    'text: "Verify"
		    'state: 'disabled
		    'command: (lambda () (verifyproc))))

(define prog (tk 'create-widget 'progressbar
		 'length:
		 *progbarsize*
		 'maximum: 1
		 'mode: 'determinate
		 'orient: 'horizontal
		 'variable: (tk-var 'progress)))

(define statusbox (tk 'create-widget 'text
		      'height: 12
		      'undo: 'false
		      'relief: 'sunken
		      'wrap: 'word
		      'state: 'disabled))

; actually drawing the window and placing positions
; for readability, keep the same order as definitions
(tk/grid entry 'row: 1 'column: 0 'columnspan: 3 'padx: 20 'pady: 20)
(tk/grid button0 'row: 1 'column: 3 'padx: 10)		; browse
(tk/grid button1 'row: 4 'column: 0 'pady: 10)		; install
(tk/grid button2 'row: 4 'column: 1)			; upgrade
(tk/grid button3 'row: 4 'column: 2)			; verify
(tk/grid prog 'row: 5 'column: 0 'columnspan: 4)
(tk/grid statusbox 'row: 6 'column: 0 'columnspan: 4)

(entry 'insert 0 "pick sourcemods dir :^)")			; we cant put this in the initialization

; our special shit to make sure subprocesses die
(tk/wm 'protocol "." "WM_DELETE_WINDOW"
       (cond-expand
	 (windows
	   (lambda ()
	     (tk-eval "exec taskkill /IM tclkit.exe /IM aria2c.exe /IM butler.exe /IM curl.exe /IM tar.exe /IM zstd.exe /T /F")
	     (exit)))

	 (linux
	   (lambda ()
	     (tk-eval "exec pkill -TERM -f \"bin/tclkit|bin/butler|bin/curl|bin/aria2c\"")
	     (exit)))))

; PROCEDURES!!

(define (findlatestversion)
  (if (null? *sex*)
    (let*-values ([(a b c) (process *curl* (list "-s" (conc *masterurl* "versions.json")))])
      (set! *sex* (parser (read-string #f a)))
      (set! *latestver* (string->number (caar (reverse (cdar *sex*)))))
      (set! *fulltarballurl*
	(conc *masterurl*
	      (cdr (assoc "url" (cdr (assoc (number->string *latestver*) (cdr (cdar *sex*))))))))
      (close-input-port a)
      (close-output-port b))))

; this is fucking cursed.
; we didnt exactly simplify this..
(define (versiondetectproc)
  ; if the user doesnt select a dir, the userdir var is the empty string
  (if (not (zero? (string-length (tk-get-var 'userdir))))
    (let ([dotlatestver (string-intersperse (string-chop (number->string *latestver*) 1) ".")]
	  [file "/tf2classic/rev.txt"] [full ""]
	  [dir (tk-get-var 'userdir)])

      ; we gotta set this to global var to work around glob gremlins in the unpack proc
      ; do we still need to set this? 20240926
      (set! *dotlatestver* dotlatestver)

      (if (file-exists? (conc dir file))
	(let* ([ver (string->number (read-line (open-input-file (conc dir file))))]
	       [dotver (string-intersperse (string-chop (number->string ver) 1) ".")])

	  (set! *currentver* ver)
	  (set! *healfile* (cdr (assoc "heal" (cdr (assoc (number->string ver) (cddar *sex*))))))

	  (unless (= ver *latestver*)
	    (set! *patchfileurl* (cdr (assoc "url"  (cdr (assoc (number->string ver) (cdadr *sex*))))))
	    (set! *patchfile*    (cdr (assoc "file" (cdr (assoc (number->string ver) (cdadr *sex*)))))))

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
	  (statusbox 'insert 'end "tf2c installation: not found\n")

	  (button1 'configure 'state: 'normal)
	  (statusstate 0))))))

(define (installproc)
  (let-values ([(a b c) (process *downloader* (append *ariaargs* (list *fulltarballurl*)))]
	       [(rid) (tk-get-var 'userdir)])
    (begin
      (buttonstate 0)
      (statusstate 1)
      (statusstate 2)
      (zprint a)   ; print the process's console
      (close-input-port a)
      (close-output-port b)	; we must close ports to exit subprocess

      (sleep 5)

      ; fuck it we ball (unpack)
      (statusbox 'insert 'end "Unpacking.. \n")

      ; we know the latest version already, so just append to the args list
      ; no need to worry about users cleaning up first :^)
      (set! *unpackargs* (append *unpackargs* (list (conc *tempdir* "/tf2classic-" *dotlatestver* ".tar.zst"))))

      (let-values ([(d e f g) (process* *tar* (append *unpackargs* (list "-C" rid)))])
	(zprint d)
	(zprint g)

	(close-input-port d)
	(close-output-port e)
	(close-input-port g)
	(statusbox 'insert 'end "\n Unpacked!\n")
	(statusbox 'insert 'end "\ndone installing!\n")
	(statusbox 'see 'end))

      (statusstate 0))))

(define (upgradeproc)
  (if (not (= *currentver* *latestver*))
    (if (not (null? *patchfile*))
      (let-values ([(a b c) (process *downloader* (append *ariaargs* (list (conc *masterurl* *patchfileurl*))))]
		   [(rid) (tk-get-var 'userdir)])
	(begin
	  (buttonstate 0)
	  (statusstate 1)
	  (statusstate 2)
	  (zprint a)
	  (close-input-port a)
	  (close-output-port b)

	  (statusbox 'insert 'end "verifying before patching..\n")
	  (statusbox 'see 'end)

	  (verifyproc)

	  (buttonstate 0) ; verify proc sets these off, we still need it here
	  (statusstate 1)

	  ; now we set up wot butler will do
	  (create-directory (conc *tempdir* "/staging"))

	  (let*-values ([(tf2cdir) (conc rid "/tf2classic")]
			[(patchpath) (conc *tempdir* "/" *patchfile*)]
			[(x y z e) (process* *butler* (append *butlerpatchargs*
							      (list patchpath tf2cdir "--json")))])
	    (begin
	      (statusbox 'insert 'end "applying patch..\n")
	      (statusbox 'see 'end)
	      (zprogress x)
	      (close-input-port x)
	      (close-output-port y)
	      (zprint e)
	      (close-input-port e)

	      (statusbox 'insert 'end "applied?\n")
	      (statusbox 'see 'end)
	      (tk-set-var! 'progress 1.0)))

	  (statusbox 'insert 'end "cleaning up staging dir..\n")
	  (cleanproc) ; wipe the staging dir - does this always happen instantly?
	  (statusbox 'insert 'end "cleaned up!\n")
	  (statusbox 'insert 'end "\ndone upgrading!\n")
	  (statusbox 'see 'end)
	  (statusstate 0)))

      (begin
	(statusstate 1)
	(statusbox 'insert 'end "patchfile is null?\n")
	(statusstate 0)))

    (begin	; outermost if, when at latest version
      (statusstate 1)
      (statusbox 'insert 'end "tf2c at latest version!\n")
      (statusstate 0))))

; butler verify cli is fairly simple,
; we simply pass in URLs to the master
; sig+heal files
; eg bin/butler verify https://wiki.tf2classic.com/kachemak/tf2classic214.sig /var/tmp/Q/tf2classic
; --heal=archive,https://wiki.tf2classic.com/kachemak/tf2classic-2.1.4-heal.zip
(define (verifyproc)
  (let*-values ([(rid) (tk-get-var 'userdir)]
		[(butlerverifyargs)
		 (list "verify"
		       (conc *masterurl* "tf2classic" *currentver* ".sig")
		       (conc rid "/tf2classic")
		       (conc "--heal=archive," *masterurl* *healfile*)
		       "--json")])

    (let-values ([(a b c d) (process* *butler* butlerverifyargs)])
      (begin
	(buttonstate 0)
	(statusstate 1)
	(zprogress a)
	(close-input-port a)
	(close-output-port b)
	(zprint d)
	(close-input-port d)

	(statusbox 'insert 'end "verified?\n")
	(statusbox 'see 'end)
	(tk-set-var! 'progress 1.0)
	(statusstate 0)
	(buttonstate 1)))))

(define (cleanproc)
  (let ([stagingtmp (conc *tempdir* "/staging")])
    (if (directory-exists? stagingtmp)
      (delete-directory stagingtmp #t))))

; input is a port, iterates and prints the lines to the status box widget
; until it hits EOF - dont forget setting the box's state before/after use
(define (zprint p)
  (with-input-from-port p
    (lambda ()
      (port-for-each
	(lambda (word)
	  (statusbox 'insert 'end (conc word "\n"))
	  (statusbox 'see 'end))

	read-line))))

; we hate json in this house
(define (zprogress p)
  (with-input-from-port p
    (lambda ()
      (port-for-each
       (lambda (word)
         (let ([json-foo (parser word)])
           (when (assoc "progress" json-foo)
             (zprogress-set! json-foo))))

       read-line))))

; helper for zprogress, not a general procedure
(define (zprogress-set! z)
  (when (assoc "progress" z)
    (tk-set-var! 'progress (cdr (assoc "progress" z)))))

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

; main tk loop
(begin
  (let ((gui-thread (make-thread tk-event-loop)))
    (handle-exceptions
      exn
      (if (uncaught-exception? exn)
	(abort (uncaught-exception-reason exn))
	(abort exn))
      (thread-start! gui-thread)
      (thread-join! gui-thread))))
