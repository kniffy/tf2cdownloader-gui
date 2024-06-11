#lang racket

(require racket/base
         racket/format
         racket/gui/easy
         srfi/7)

; global vars

; we set our PATH environment var to be relative to where
; tf2cd is launched from, and build the path cross-platform-y?
; this is actually automatic on windows, but linux people are strange
(putenv "PATH" (~a (build-path (current-directory) "bin")))

; find-executable-path will search a second time with ".exe" added if #f is
; returned initially - in other words, dont ship linux shit for windowsdist :^)
(define *aria* (~a (find-executable-path "aria2c")))
(define *butler* (~a (find-executable-path "butler")))

; these utils are fully cross-platform
(define *df* (~a (find-executable-path "df")))
(define *tar* (~a (find-executable-path "tar")))
(define *zstd* (~a (find-executable-path "zstd")))

; we query the environment for the home dir,
; convert to string, and concatenate
; this is probably pointless, as we know the sourcemods
; path on windows is not here
(define *defaultdir*
  (string-append (~a (find-system-path 'home-dir))
                 ".local/share/Steam/steamapps/sourcemods"))

; fuck it we draw
(render
 (window #:title "tf2cdownloader"
         #:size '(600 200)
         #:position 'center

         (hpanel
          (input "select sourcemods directory :^)")
          (button "Browse"
                  (lambda () (display "brwose"))))

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
