#lang racket

(require racket/base
         racket/format
         racket/gui/easy
         racket/system)

(require (prefix-in gui: racket/gui))

; global vars

; we find the system bins for these, linux
; people should have them anyway
; this must happen before we mangle $PATH
(define *df* (~a (find-executable-path "df")))
(define *tar* (~a (find-executable-path "tar")))
(define *zstd* (~a (find-executable-path "zstd")))

; this is such a fucking annoying hack, find-executable-path is a shit
; ass fucking procedure and we cant get it to work to search our local
; bin unless its in $PATH - shouldnt be required on windows as it
; naturally understands we want our fucking local bin as first choice
(putenv "PATH" (~a (build-path (current-directory) "bin")))

; find-executable-path should find the .exe versions on windows
; mayb dont ship the linux bins in the dist tarball :^)
(define *aria* (~a (find-executable-path "aria2c")))
(define *butler* (~a (find-executable-path "butler")))

; we query the environment for the home dir,
; convert to string, and concatenate
; this is probably dumb, keep the old message..
(define *defaultdir* "pick a dir :^)")
;(if (string=? (~a (system-type 'os)) "unix")
;    (set! *defaultdir* (string-append
;                        (~a (find-system-path 'home-dir))
;                        ".local/share/Steam/steamapps/sourcemods"))
;    (set! *defaultdir* "c:\\program files (x86)\\steam\\steamapps\\sourcemods"))

; like the old tk version, we need to set a fancy variable
; for the text field, denoted by the @ symbol
(define @userdir (obs *defaultdir*))

; subprocess vars
(define *df-args* "--output=avail")

; procedures!!

; this is more cursed than in Chicken somehow..
; we MUST use non-star process/system procedures,
; the cosmos bins do not work when executed directly
(define freespace?
  (lambda (dir)
    (let ([a (begin-process *df* *df-args* dir)])
      (begin
        (define parse-list a)
        (set! parse-list (map (lambda (z) (string->number z)) parse-list)))

      ; our number
      (let ([p (car (filter number? parse-list))])
        (if (< p 20000000)
            (display "free space check: failed?\n")
            (display "free space check: passed!\n"))))))

; this is mostly a stub to be improved
; for now we just print to console; we
; eventually either want to print to an
; editor canvas (text box), or, we will
; throw away output entirely and update
; a progress bar
(define begin-process
  (lambda cmds
    (let*-values ([(proc) (process (string-join cmds))]
                  [(out in err) (values (list-ref proc 0) (list-ref proc 1) (list-ref proc 3))])

      ; this is not suitable for a long running
      ; process like aria2; that requires poking the RPC
      (begin
        (define returnlist (port->lines out))
        (end-process out in err proc))

      ; we set our return value by writing it last
      returnlist)))

; only call this within a begin-process
(define end-process
  (lambda (x y z a)
    (close-input-port x)
    (close-output-port y)
    (close-input-port z)))

; fuck it we draw
(render
 (window #:title "tf2cdownloader"
         #:size '(600 200)
         #:position 'center

         (hpanel
          (input @userdir)

          (button "Browse"
                  (lambda ()
                    (define dir (gui:get-directory "hi"))
                    (when dir
                      (thread
                       (lambda ()
                         (begin
                           (freespace? (~a dir))
                           (obs-set! @userdir (~a dir)))))))))

         (hpanel #:alignment '(center center)
                 (button "New Install"
                         #:min-size '(200 10)
                         (lambda () (display "New Install")))

                 (button "Upgrade"
                         #:min-size '(200 10)
                         (lambda () (display "Upgrade")))
                 (button "Verify"
                         #:min-size '(200 10)
                         (lambda () (display "Verify"))))))
