 
clear,clc,close all;
I=imread('2.png');
%I=imread('6.jpg');
figure(1),imshow(I);title('原图')
%figure(1),imshow(I)
bw=rgb2gray(I);
figure(2),imshow(bw);title('灰度图')
bw=im2bw(I,graythresh(bw));
bw=double(bw);
figure(3),imshow(bw);title('二值图')
%这是滤波的代码
%fil=medfilt2(bw,[2,2]);
%figure(4),imshow(fil);title('滤波后的图');
BW=edge(bw,'canny');
figure(5),imshow(BW);
title('canny 边界图像');
[H,T,R]=hough(BW);
%{
函数原型houghpeaks(h,numpeaks,threshold,nhood);
h代表上面的H，即角度和长度的空间；
numpeaks指定要寻找的峰值个数；
threshold指定门限，如果不指定，自动使用默认值0.5*max(H(:))
返回值为npeaks×2的矩阵，代表每个点的坐标
%}

P=houghpeaks(H,4,'threshold',ceil(0.3*max(H(:))));
hold on;
x=T(P(:,2)); y = R(P(:,1));
%houghlines从H变换矩阵中提取线段
%T,R是houghpeaks的输出
%50:正的标量，指定了与相同的hough变换相关的两条线段的距离，小于则合并。默认20
%7：正的标量，指定合并的线是丢弃还是保留,默认40
lines=houghlines(BW,T,R,P,'FillGap',50,'MinLength',7);
max_len = 0;
for k=1:length(lines)
    xy=[lines(k).point1;lines(k).point2];
    %描出线段
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
     plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
     %归一化,计算线的长度，找最长线段
    len=norm(lines(k).point1-lines(k).point2);
    Len(k)=len;
    if (len>max_len)
        max_len=len;
    end
end
[L1,Index1]=max(Len(:));  %获取最大线段长度和索引
% 最长线段的起始和终止点
x1=[lines(Index1).point1(1) lines(Index1).point2(1)];
y1=[lines(Index1).point1(2) lines(Index1).point2(2)];
% 求得线段的斜率
K1=-(lines(Index1).point1(2)-lines(Index1).point2(2))/(lines(Index1).point1(1)-lines(Index1).point2(1))
%反正切函数求夹角
angle=atan(K1)*180/pi
if angle==0
    angle=90;
end
A = imrotate(I,90-angle,'bilinear');
A=rgb2gray(A);
A=im2bw(A,graythresh(A));
A=double(A);
%下面是译码部分
[m,n]=size(A);
figure(6),imshow(A);
title('校正后的图像');
number=0;
for i=1:m
    pos_cnt=1;
    width_id=1;
    for j=1:n-1
        if A(i,j) ~= A(i,j+1)
            pos(i,pos_cnt)=j;
            if pos_cnt>1
                width(i,width_id)=pos(i,pos_cnt)-pos(i,pos_cnt-1);
                width_id=width_id+1;
            end
            pos_cnt=pos_cnt+1;
        end
    end  
    %这是针对校正图像的
    if angle~=90
        if width_id==62
            number=number+1;
            for k=1:59
                  total_len(number,k)=width(i,k+1);
            end
        end
    %这是针对没有校正的图像
    else
        if width_id==60
            number=number+1;
            for k=1:59
                  total_len(number,k)=width(i,k);
            end
        end
    end
end

%求取宽度的平均值
[mm,nn]=size(total_len);
for i=1:nn
    tmp=0;
    for j=1:mm
        tmp=tmp+total_len(j,i);
    end
    final_width(1,i)=tmp/mm;
end

%总宽度除以95得到单位模块长度
unit_len=0;
for i=1:59
    unit_len=unit_len+final_width(1,i);
end
unit_len=unit_len/95;

%求每一个长度所占单位模块长度的比例
for i=1:59
    proposition(1,i)=final_width(1,i)/unit_len;
end

%0/1标注并检验
index=1
for i=1:59
    if mod(i,2)==1
        for j=1:1:round(proposition(1,i))
            mat95(1,index)=1;
            index=index+1;
        end
    else
        for j=1:1:round(proposition(1,i))
            mat95(1,index)=0;
            index=index+1;
        end
    end
end
isCheck=0;
if(mat95(1,1)==1&&mat95(1,2)==0&&mat95(1,3)==1&&mat95(1,46)==0&&mat95(1,47)==1&&mat95(1,48)==0&&mat95(1,49)==1&&mat95(1,50)==0&&mat95(1,93)==1&&mat95(1,94)==0&&mat95(1,95)==1)
  isCheck=1;
end

if isCheck==0
    msgbox('不满足EAN-13码的条件！');
    return
end

%检验的另一种方法
%test=round(proposition);
%test_sum=sum(test);
%temp=0;
%isValid=true;
%ii=0;
%for k=4:28
%	if mod(ii,4)==0
%		if(temp==0 || temp==7)
%			isValid=true;
%		else
%			isValid=false;
%			break;
%		end
%		temp=0;
%	end
%temp=test(k)+temp;
%ii=ii+1;
%end

%计算左侧数据栏和右侧数据栏的十进制数，分别保存到left和right数组里
j=1;
for i=4:7:39
    left(1,j)=bin2dec(num2str(mat95(1:1,i:i+6)));
    j=j+1;
end
k=1;
for i=51:7:86
    right(1,k)=bin2dec(num2str(mat95(1:1,i:i+6)));
    k=k+1;
end

checkLeft=[13,25,19,61,35,49,47,59,55,11,39,51,27,33,29,57,5,17,9,23];
checkRight=[114,102,108,66,92,78,80,68,72,116];
num_bar='';
AB_check='';    %AB字符串序列，用来得到前置位
for i=1:6
    for j=0:19
        if left(i)==checkLeft(j+1)
            if j>9
                AB_check=strcat(AB_check,'B');
            else
                AB_check=strcat(AB_check,'A');
            end
            num_bar=strcat(num_bar,num2str(mod(j,10)));
        end
    end
end


for i=1:6
    for j=0:9
        if right(i)==checkRight(j+1)
            num_bar=strcat(num_bar,num2str(j))
        end
    end
end
preMap = containers.Map({'AAAAAA','AABABB','AABBAB','AABBBA','ABAABB','ABBAAB','ABBBAA','ABABAB','ABABBA','ABBABA'},...
    {'0','1','2','3','4','5','6','7','8','9'});
pre=preMap(AB_check);
num_bar=strcat(pre,num_bar);

oddSum=0;evenSum=0;
for i=1:12
    if mod(i,2)==1
        oddSum=oddSum+str2num(num_bar(i));
    else
        evenSum=evenSum+str2num(num_bar(i));
    end
end

c=oddSum+3*evenSum;
if mod(c,10)==0
    checkBit=0;
else
    checkBit=10-mod(c,10);
end

if num2str(checkBit)==num_bar(13)
    msgbox('Okay')
else
    msgbox('Failed');
end
