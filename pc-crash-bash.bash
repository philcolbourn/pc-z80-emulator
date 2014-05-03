#!/bin/bash

printf "Howto crash bash\n"

unset a b X
declare -i a=-1 b=1
declare -ia X=( {0..1000..100} )

(( b+=1                 )); printf "This works: a=%d  b=%d\n" $a $b
(( b=b+1                )); printf "This works: a=%d  b=%d\n" $a $b
(( a=X[b]               )); printf "This works: a=%d  b=%d\n" $a $b
(( a=X[b],       b+=1   )); printf "This works: a=%d  b=%d\n" $a $b
(( a=X[b] )); (( b+=1   )); printf "This works: a=%d  b=%d\n" $a $b
(( a=X[b] )); (( b=b+1  )); printf "This works: a=%d  b=%d\n" $a $b
(( b+=1,         b+=1   )); printf "This works: a=%d  b=%d\n" $a $b
(( b=b+1,        b=b+1  )); printf "This works: a=%d  b=%d\n" $a $b
(( b+=1  ));  (( a=X[b] )); printf "This works: a=%d  b=%d\n" $a $b
(( b=b+1 ));  (( a=X[b] )); printf "This works: a=%d  b=%d\n" $a $b
(( b+=1,         a=X[b] )); printf "This works: a=%d  b=%d\n" $a $b
(( b=b+1,        a=X[b] )); printf "This works: a=%d  b=%d\n" $a $b

printf "But a 'b=b+1' after an array read crashes bash.\n"

(( a=X[b],       b=b+1  )); printf "This crashes: a=%d  b=%d\n" $a $b

