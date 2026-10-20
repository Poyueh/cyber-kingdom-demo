extends Resource
@export_range(0,1,0.05) var last_blow_hold: float=0.15
@export_range(0.5,3,0.05) var blackout_end: float=1.65
@export_range(0.5,4,0.05) var message_start: float=1.85
@export_range(0.5,5,0.05) var message_end: float=2.65
## After the Demo's rocket epilogue, return to the start menu by itself.
@export_range(4,20,0.5) var finale_return: float=9.0
