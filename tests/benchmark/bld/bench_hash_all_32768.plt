set terminal svg
set title "Hash performance (input size 32768)"
set label "Date: ".strftime("%b %d %Y %H:%M:%S", time(0)) at character .5, 1.1 font "Courier,8"
set label "Config: -SHAEXT +AESNI +PCLMULQDQ +AVX +AVX2 +BMI2 +ADX +HACL +VALE SEED=0 SAMPLES=100" at character .5, .65 font "Courier,8"
set label "EverCrypt: /usr/bin/cc -Devercrypt\\_EXPORTS -I/mnt/e/everest/latest/hacl-star/dist/compact-c89 -I/mnt/e/everest/latest/kremlin/include -I/mnt/e/everest/latest/kremlin/kremlib/dist/generic  -g -fPIC   -Wno-parentheses -std=gnu11 -march=native -mtune=native -fPIC -fstack-check -o CMakeFiles/evercrypt.dir/mnt/e/everest/latest/hacl-star/dist/compact-c89/EverCrypt\\_Error.c.o   -c /mnt/e/everest/latest/hacl-star/dist/compact-c89/EverCrypt\\_Error.c" at character .5, .25 font "Courier,1"
set label "KreMLib: /usr/bin/cc -D\\_BSD\\_SOURCE -D\\_DEFAULT\\_SOURCE -I/mnt/e/everest/latest/kremlin/include -I/mnt/e/everest/latest/kremlin/kremlib/dist/generic  -g   -std=c11 -fwrapv -Wall -Wextra -Werror -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unknown-warning-option -Wno-infinite-recursion -Wno-unused-parameter -fPIC -o CMakeFiles/kremlib.dir/mnt/e/everest/latest/kremlin/kremlib/dist/generic/prims.c.o   -c /mnt/e/everest/latest/kremlin/kremlib/dist/generic/prims.c" at character .5, .35 font "Courier,1"
set datafile separator "," 
set datafile commentschars "//" 
set xtics rotate 
set boxwidth 0.5 
set style fill solid
set bmargin 3
set key off
set ylabel "avg cycles/hash"
set output 'bench_hash_all_32768.svg'
set xtics norotate
set key on
set style histogram clustered gap 3 title
set style data histograms
set xrange [5.5:8.5]
plot 'bench_hash_MD5.csv'using 8:xticlabels(1) title "MD5", \
'bench_hash_SHA1.csv'using 8 title "SHA1", \
'bench_hash_SHA2_224.csv'using 8 title "SHA2-224", \
'bench_hash_SHA2_256.csv'using 8 title "SHA2-256", \
'bench_hash_SHA2_384.csv'using 8 title "SHA2-384", \
'bench_hash_SHA2_512.csv'using 8 title "SHA2-512"
