#source('/Users/hana/myprojects/snowFT/tests/test_functions.R')
source('test_functions.R')
run.rnorm.sock()
run.rnorm.seq()
#run.rnorm.sock.cluster.args()
#run.rnorm.pvm()
#run.rnorm.mpi()
check.reproducibility.for.seq.and.par()