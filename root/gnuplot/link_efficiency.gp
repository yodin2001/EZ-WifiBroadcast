set terminal pngcairo notransparent rounded font "/usr/share/fonts/truetype/DejaVuSans.ttf" size 1920,1080

set datafile separator ","

# nomirror means do not put tics on the opposite side of the plot
set xtics nomirror
set ytics nomirror

# On the Y axis put a major tick every 5
set ytics 5

# On both the x and y axes split each space in half and put a minor tic there
set mxtics 2
set mytics 2

# Line style for axes
# Define a line style (we're calling it 80) and set 
# lt = linetype to 0 (dashed line)
# lc = linecolor to a gray defined by that number
set style line 80 lt 0 lc rgb "#808080"

# Set the border using the linestyle 80 that we defined
# 3 = 1 + 2 (1 = plot the bottom line and 2 = plot the left line)
# back means the border should be behind anything else drawn
set border 3 back ls 80

# Line style for grid
# Define a new linestyle (81)
# linetype = 0 (dashed line)
# linecolor = gray
# lw = lineweight, make it half as wide as the axes lines
set style line 81 lt 0 lc rgb "#808080" lw 0.5

# Draw the grid lines for both the major and minor tics
set grid xtics
set grid ytics
set grid mxtics
set grid mytics

# Put the grid behind anything drawn and use the linestyle 81
set grid back ls 81


# Create some linestyles for our data
# pt = point type (triangles, circles, squares, etc.)
# ps = point size
set style line 1 lt 1 lc rgb "#A00000" lw 2 pt 7 ps 0.5
set style line 2 lt 1 lc rgb "#00A000" lw 2 pt 13 ps 0.5
set style line 3 lt 1 lc rgb "#5060D0" lw 2 pt 5 ps 0.5

set style line 4 lt 1 lc rgb "#00A000" lw 0.5
set style line 5 lt 1 lc rgb "#5060D0" lw 0.5
set style line 6 lt 1 lc rgb "#D08000" lw 0.5

# Name our output file
set output "/media/usb/rssi/linkefficiency.png"

# Put X and Y labels
set xlabel "time [s]"
set ylabel "link efficiency [dbm]"

# Set the range of our x and y axes
#set xrange [100:]
set yrange [0:]

# Give the plot a title
set title "Link Efficiency"

# Put the legend at the bottom left of the plot
set key left bottom

# Plot the actual data
# u 1:2 = using column 1 for X axis and column 2 for Y axis
# w lp = with linepoints, meaning put a point symbol and draw a line
# ls 1 = use our defined linestyle 1
# t "Test 1" = title "Test 1" will go in the legend
# The rest of the lines plot columns 3, 5 and 7

stats "/wbc_tmp/telemetry_log_file.csv" u 1:6 nooutput

plot "/wbc_tmp/telemetry_log_file.csv" u 1:6 w lines ls 5 t "link efficiency",\
STATS_max_y w lines ls 4 t "MAX efficiency"

# This is important because it closes our output file.
set output
