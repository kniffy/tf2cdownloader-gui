(import r7rs
	pstk)

(tk-start "tclsh")
;(tk-start)
(ttk-map-widgets 'all) ; Use the Ttk widget set

(tk/wm 'title tk "tf2cdownloader")

(tk-event-loop)
