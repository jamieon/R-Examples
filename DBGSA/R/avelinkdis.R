#����ƽ������:
avelinkdis<-function(C,num,Meth){
#���磺MethΪ"euclidean"
C<-t(C);
A<-as.matrix(C[1:num,]);
B<-as.matrix(C[(1+num):nrow(C),]);
rowA<-nrow(A);
rowB<-nrow(B);
if (Meth=="stat")
{
cr<-nrow(C);
cc<-ncol(C);
for(n in 1:cc){
C[,n]<-C[,n]*(1/sd(C[,n]))
}
D<-dist(C,method="euclidean",diag=TRUE,upper=TRUE)
}
else
{
D<-dist(C,method=Meth,diag=TRUE,upper=TRUE);##��������������������ʾ�Խ����ϵ�Ԫ��
}
D<-as.matrix(D);#ǿ�ƽ�D��dist��������ת��Ϊ�����ʽ
Out<-D[(rowA+1):nrow(D),1:rowA];
return(1/(rowA*rowB)*sum(Out));#���ݹ�ʽ����ľ���
 }