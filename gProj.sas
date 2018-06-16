libname cpdat 'C:\SAS Files\Project';

*Preparing the Data-Model using ETL;

DATA cpdat.books (drop=Var15); 
infile 'C:\SAS Files\Project\books.txt' delimiter='09'x MISSOVER DSD lrecl=50000 firstobs=2 IGNOREDOSEOF; 
informat userid best32. ;
informat education best32. ; 
informat region best32. ; 
informat hhsz best32. ;
informat age best32. ;
informat income best32. ; 
informat child best32. ; 
informat race best32. ;
informat country best32. ;
informat domain $20. ; 
informat date best32. ; 
informat product $132. ; 
informat qty best32. ; 
informat price best32. ; 

/* To display records in the format*/

format userid best12. ; 
format education best12. ; 
format region best12. ; 
format hhsz best12. ; 
format age best12. ; 
format income best12. ; 
format child best12. ; 
format race best12. ; 
format country best12. ; 
format domain $20. ; 
format date best12. ; 
format product $132. ; 
format qty best12. ; 
format price best12. ; 

/* field names */

Input userid education region hhsz age income child race country domain $ date product $ qty price; 
RUN;


/*cleaning the dataset*/

data books;
set cpdat.books;
if region='*' then region='7';
if age='99' then age='7';
if education='99' then education='6';
run;

/*Count DataSet Generation*/
data bnncount;
set cpdat.books;
proc sort data=bnncount out=temp;
by userid;
run;


data totalby(keep=userid education region hhsz age	income	child	race	country domain count);
   set temp;
   retain count;
   by userid;
   if First.userid then count=0;
   if domain = 'barnesandnoble.com' then count = qty + count;
   if Last.userid;
run;

proc export data = work.totalby
outfile = totalbyexcel dbms = 'xlsx';
run;


proc print data=totalby(obs=10);
run;

proc sort data=totalby;
by descending count;
run;

/* NBD Model Creation*/ 

data nop(keep=peoplecnt count);
set totalby;
retain peoplecnt 0;
by count;
peoplecnt= peoplecnt+1;
if Last.count then 
do;
output;
peoplecnt = 0;
end;
run;


PROC NLMIXED DATA=work.Nop;
parms r=0.1 a=1;
  ll = peoplecnt*(log(gamma(r+count))-log(gamma(r))-log(fact(count))+r*log(a/(a+1))+count*log(1/(a+1)));
  model count ~ general(ll);
RUN;



*Performing the Poisson Regression;

proc nlmixed data=work.totalby;
  /* m stands for lambda */
  parms m0=1 b1=0 b2=0 b3=0 b4=0 b5=0 b6=0 b7=0 b8=0;
  m=m0*exp(b1*education+b2*region+b3*hhsz+b4*age+b5*income+b6*child+b7*race+b8*country);
  ll = count*log(m)-m-log(fact(count));
  model count ~ general(ll);
run;



*Performing NBD-Regression;

libname cpdat 'C:\SAS Files\Project';

proc nlmixed data=work.totalby;
  parms r=1 a=1 b2=0 b7=0;
  expBX=exp(b2*region+b7*race);
  ll = log(gamma(r+count))-log(gamma(r))-log(fact(count))+r*log(a/(a+expBX))+count*log(expBX/(a+expBX));
  model count ~ general(ll);
run;



