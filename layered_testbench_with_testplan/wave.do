onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider P0
add wave -noupdate /top/p0_bus/clk
add wave -noupdate /top/p0_bus/sop
add wave -noupdate /top/p0_bus/eop
add wave -noupdate /top/p0_bus/data
add wave -noupdate -divider P1
add wave -noupdate /top/p1_bus/clk
add wave -noupdate /top/p1_bus/sop
add wave -noupdate /top/p1_bus/eop
add wave -noupdate /top/p1_bus/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1050 ns} {2050 ns}
