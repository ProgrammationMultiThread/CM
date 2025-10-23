unset key
unset border

set size 1.2
set size ratio 0.6

set style arrow 1 head filled size screen 0.015,15,45 lw 0.8 lc rgb "#000000"

# --- X axis ---
set xrange [1970:2023]
unset ytics
do for [p in "0 1 2 3 4 5 6 7 8"] {
    y = 10**p
    set arrow from 1970,y to 2023,y nohead lc rgb "#bbbbbb" lw 0.8
    set label sprintf("$10^{%s}$", p) at 1966.5,y  font ",6"
}
set arrow from graph 0, first 0.15 to graph 1.02, first 0.15 as 1


# --- Y axis ---
set yrange [0.15:1e8]
set logscale y
unset xtics
do for [x in "1970 1980 1990 2000 2010 2020"] {
    set arrow from x,0.15 to x,1e8 nohead lc rgb "#bbbbbb" lw 0.8
    set label x at x-2,.08  font ",6"
}
set arrow from first 1970, graph 0 to first 1970, graph 1.04 as 1
set label "Année" at 2024,.08  font ",6" center front



# --- Data ---

set label "Transistors" at 2005,6e7  font ",7" tc rgb "#00468C" center front
set label "(milliers)"  at 2005,2e7  font ",7" tc rgb "#00468C" center front
set label "Fréquence"   at 2015,6e4  font ",7" tc rgb "#0E5A00" center front
set label "(mHz)"       at 2015,2e4  font ",7" tc rgb "#0E5A00" center front
set label "Nombre"      at 2015,6  font ",7" tc rgb "#A0280F" center front
set label "de cœurs"    at 2015,2  font ",7" tc rgb "#A0280F" center front

transistors(x) = a*x + b
fit transistors(x) 'transistors.dat' using 1:(log($2)) via a,b

frequencyA(x) = c*x + d
fit [1990:2004] frequencyA(x) 'frequency.dat' using 1:(log($2)) via c,d
frequencyB(x) = e*x + f
fit [2004:2022] frequencyB(x) 'frequency.dat' using 1:(log($2)) via e,f

coresA(x) = g*x + h
fit [1970:2005] coresA(x) 'cores.dat' using 1:(log($2)) via g,h
coresB(x) = i*x + j
fit [2008:2020] coresB(x) 'cores.dat' using 1:(log($2)) via i,j


plot \
  "transistors.dat" using 1:2 with points pt 3 ps 0.7 lc rgb "#00468C", \
  "frequency.dat"   using 1:2 with points pt 6 ps 0.7 lc rgb "#0E5A00", \
  "cores.dat"       using 1:2 with points pt 7 ps 0.7 lc rgb "#A0280F", \
  [1980:2023] exp(transistors(x)) with lines lw 1.2 lc rgb "#00468C", \
  [1980:2010] exp(frequencyA(x))  with lines lw 1.2 lc rgb "#0E5A00", \
  [2000:2023] exp(frequencyB(x))  with lines lw 1.2 lc rgb "#0E5A00", \
  [1980:2010] exp(coresA(x))  with lines lw 1.2 lc rgb "#A0280F", \
  [2000:2023] exp(coresB(x))  with lines lw 1.2 lc rgb "#A0280F"


