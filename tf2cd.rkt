#lang racket

(require racket/format
         racket/gui/easy)

; global vars

; we query the environment for the home dir,
; convert to string, and concatenate 
(define *defaultdir*
  (string-append (~a (find-system-path 'home-dir))
                 ".local/share/Steam/steamapps/sourcemods"))

; all the init+drawing the gui is in this
; render block
(render
 (window #:title "tf2cdownloader"
         #:size '(600 300)
         #:position 'center
  (text "sourcemods dir:")

  (hpanel
   (input "select a dir :^)")
   (button "Browse"
           (lambda () (display "brwose"))))
  
  (hpanel
   (button "foo"
          (lambda () (display "foo")))
   (button "bar"
          (lambda () (display "bar")))
   (button "baz"
          (lambda () (display "baz"))))))
