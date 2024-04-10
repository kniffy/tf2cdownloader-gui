(import pstk)

; parse libraryfolders.vdf ?

(tk-start) ; default calls tclsh8.6
(ttk-map-widgets 'all) ; Use the Ttk widget set
(tk/wm 'title tk "tf2cdownloader")
(tk 'configure 'height: 600 'width: 800)

(define statusbox
  (tk 'create-widget 'label
      'text: "this is a label"))

(tk/pack
  (tk 'create-widget 'button
      'text: (quote "New Install")
      #:command (lambda () (print "clicked install")))
  (tk 'create-widget 'button
      'text: 'Upgrade
      #:command (lambda () (print "clicked upgrade")))
  (tk 'create-widget 'button
      'text: 'Quit
      #:command (lambda () (tk-end)))
  (tk 'create-widget 'label
      'text: "some text"
      'anchor: 'center)

  #:expand #t
  #:fill 'both)

(tk-event-loop)
