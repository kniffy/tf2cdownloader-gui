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
(define *defaultdir* 0)
(if (string=? (~a (system-type 'os)) "unix")
    (set! *defaultdir* (string-append
                        (~a (find-system-path 'home-dir))
                        ".local/share/Steam/steamapps/sourcemods"))
    (set! *defaultdir* "c:\\program files (x86)\\steam\\steamapps\\sourcemods"))

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
    (let*-values ([(proc) (process (string-join (list *df* *df-args* dir)))]
                  [(out in err) (values (list-ref proc 0) (list-ref proc 1) (list-ref proc 3))])

      ;(define-values (out in z err) (values (list-ref proclist 0) 1 2 3))

      (printf "stdout:\n~a" (port->string out))
      (printf "stderr:\n~a" (port->string err))
      

      (close-input-port out)
      (close-output-port in)
      (close-input-port err))))

; TODO define a boilerplate function to call
; a subprocess and open the ports
; and define a close-proc secondary lambda

(define begin-process
  (lambda cmds
    (let*-values ([(proc) (process (string-join cmds))]
                  [(out in err) (values (list-ref proc 0) (list-ref proc 1) (list-ref proc 3))])

      (printf "stdout:\n~a" (port->string out))
      (printf "stderr:\n~a" (port->string err))

      (close-input-port out)
      (close-output-port in)
      (close-input-port err))))

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
