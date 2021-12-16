 #!/bin/bash
 find /home/fset.stuve.uni-ulm.de/ -maxdepth 1 -not -wholename '/home/fset.stuve.uni-ulm.de/' -mtime +30 -exec command rm -R {} \;
