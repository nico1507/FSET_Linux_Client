 #!/bin/bash
for u in $(ls /home/fset.stuve.uni-ulm.de); do
    sudo killall --user $u 
done
