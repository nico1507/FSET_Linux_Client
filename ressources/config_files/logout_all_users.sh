 #!/bin/bash
for u in $(ls /home/fset.stuve.uni-ulm.de); do
    killall --quiet --user $u 
done
