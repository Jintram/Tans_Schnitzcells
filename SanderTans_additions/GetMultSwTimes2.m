%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Getting data out of several schnitzes in different files. The files information/address is 
% mentioned in a file called Fdata. The schnitz that contain switching
% have to be mention LAST. The first schnitz is said to be 0 but later on will 
% become the PARENT schnitz of  the switching schnitz. The middle schnitz is usually the sister 
% schnitz as control.
% Output values are being stored in workspace as file called
% AllData, with every collum contain specified data as mention below.
% col 1 : Movie name and schnitzes information
% col 2 : Time data of selected schnitzes
% col 3 : Mean Fluor data of selected schnitzes
% col 4 : Birth time of switching schnitz
% col 5 : Switching time 
% col 6 : Division time of switchin schnitz
% col 7 : Cell length data of selected schnitz
% col 8 : Birth length of switching schnitz
% col 9 : Switching length
% col 10: Division length of switching schnitz
% col 11: Phase data of selected schnitzes
% col 12: Switching phase
% col 13: a and b for ax+b of the first regression
% col 14: a and b for ax+b of the second regression
% col 15: number of SeqA spots
% NOT working : If data wants to be added to the existing AllData file, for example at
% entry number 17, then change SchI value from 0 to n-1 (in this case 16).
% But the F data should be the corresponding Fdata file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%With SeqA :
Fdata = {...
% %       'Pos05-mini-01','2006-11-07','e.coli','rootDir','G:\',[0 2 3];...
%       'Pos06-mini-01','2006-11-17','e.coli','rootDir','G:\',[0 13 12];...
% %       'Pos04-mini-01','2006-11-17','e.coli','rootDir','G:\',[0 4 5];...
% %           %above event happened very late in the movie all SeqA spots have been bleached
%       'Pos06-mini-01','2006-11-21','e.coli','rootDir','G:\',[0 13 8];...
%       'Pos03-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 5 4];...
%       'Pos03e2-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 7 6];...
%       'Pos03e3-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 7 8];...
       'Pos06-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 3 12];...
%       'Pos06e2-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 3 2];...
%       'Pos08-mini-01','2006-11-22','e.coli','rootDir','G:\',[0 5 4];...
% %           %above event happened very late in the movie, not developed very far yet
% %           %and later on out of field of view.
%       'Pos05-mini-01','2007-01-23','e.coli','rootDir','G:\',[0 5 4];...
        }

% % For all switching :
% Fdata = {...
%     'Pos06-mini-01','2006-07-20','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 5 20];...
%     'Pos04-mini-01','2006-08-08','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 9 10];...
%     'Pos01-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 4 5];...
%     'Pos01e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 5 12];...         
%     'Pos01e3-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 8 9];...
%     'Pos02-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 6 7];...
%     'Pos02e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 6];...
%     'Pos02e3-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 4 8];...
%           %above:ambiguous, asuming event happen very2 early  
%     'Pos06-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 8 9];...      
%     'Pos06e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 36 4];...
%     'Pos02-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 7 4];...
%          %above:ambiguous, asuming event happen very2 early      
%     'Pos02e2-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...
% % %     'Pos03-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 1];...
% % %      %above: movie is not early enough to include the birth of the switching schnitz
%     'Pos03e2-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...       
%     'Pos05e1b-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 3];...
%          %above:ambiguous, asuming event happen very2 early  
%     'Pos06-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 5 4];...
%          %above:ambiguous, asuming event happen very2 early      
%     'Pos03-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 9 10];...
%     'Pos03e2-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 8 7];...
% % %      %above: ambiguous, asuming event happen very2 early, later schnitzes need to be checked
%      'Pos05-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...     
%      'Pos01-mini-01','2006-08-15','e.coli','rootDir','D:\CellObserver',[0 4 3];...
%          %above:ambiguous, asuming event happen very2 early  
%      'Pos05-mini-01','2006-08-15','e.coli','rootDir','D:\CellObserver',[0 3 2];...
% % %      %above: movie is not early enough to include the birth of the parent of switching schnitz
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %with td less than 60 mins :
%     'Pos04-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 7 6];...
%          %above:ambiguous, asuming event happen very2 early 
%     'Pos05-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 7 6];...
%          %above:ambiguous, asuming event happen very2 early 
%          %above:if late,movie is not early enough to include the birth of the parent of switching schnitz
%     }


% %For td>150 mins :
% Fdata = {...
%     'Pos06-mini-01','2006-07-20','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 5 20];...
%     'Pos06-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 5 4];...
%     'Pos03-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 9 10];...
%     'Pos05-mini-01','2006-08-15','e.coli','rootDir','D:\CellObserver',[0 3 2];...
% % %      %above: movie is not early enough to include the birth of the parent of switching schnitz
%     }

% %For <100 mins <td< 150 mins :
% Fdata = {...  
%     'Pos04-mini-01','2006-08-08','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 9 10];...
%     'Pos02e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 6];...
%         % above :  sister of switching cell is abnormal
%     'Pos06-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 8 9];...          
%     'Pos02e2-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...
%     'Pos03e2-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...       
%     'Pos03e2-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 5 4];...
% %      %above: asuming event happen very2 late, later schnitzes need to be checked
%     'Pos03e2-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 8 7];...
%        %above: asuming event happen very2 early, later schnitzes need to be checked
%     'Pos05-mini-01','2006-08-22','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 4 5];...     
% % %      %above: movie is not early enough to include the birth of the parent of switching schnitz
%     }
 
    
% %For 60 mins <td< 100 mins :
% Fdata = {...   
%     'Pos01-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 4 5];...
%     'Pos01e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 5 6];...         
%     'Pos01e3-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 8 9];...
%     'Pos02-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 11 9];...       
%     'Pos02e3-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 4 8];...    
%     'Pos06e2-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 36 4];...
%     'Pos02-mini-01','2006-08-17','e.coli','rootDir','F:\CELLOBSERVER\2006mondate\',[0 7 4];...
%     'Pos01-mini-01','2006-08-15','e.coli','rootDir','D:\CellObserver',[0 4 3];...     
%     }
% 
% 
% %For td <60 mins  mins :
% Fdata = {...   
%     'Pos04-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 2 3];...
%          %above: movie is not early enough to include the birth of the parent of switching schnitz
%     'Pos05-mini-01','2006-08-10','e.coli','rootDir','D:\CellObserver',[0 2 3];...
%          %above: movie is not early enough to include the birth of the parent of switching schnitz     
%     }


PlotStyles={'r-';'b-';'g-';'k-';'m-';'c-'};
NrSchnitz=1;
SchI=0;
for i=1:length(Fdata(:,1))
    SchI = SchI + 1;
    p = feval('initschnitz',char(Fdata(i,1)),char(Fdata(i,2)),char(Fdata(i,3)),char(Fdata(i,4)),char(Fdata(i,5)));    
    [p,schnitzcells] = feval('compileschnitzSeqA',p,'load',1);
    
    SwSchnitz = Fdata{i,6}(length(Fdata{i,6})) 
    ParentSwSchnitz = schnitzcells(1,SwSchnitz).P
    Fdata{i,6}(1) = ParentSwSchnitz %the first schnitz is the parent of the switching schnitz
    
    %[Ti Fl Tbr Tsw Tdv]= feval('plotschnitzmeST_NoAnc',p,schnitzcells,'FYsmins','MYs',Fdata{i,6},PlotStyles);
    [Ti Fl]= feval('plotschnitzmeST_NoAncNoReg',p,schnitzcells,'FYsmins','MYs',Fdata{i,6},PlotStyles);
    %Ti is all x data (xout)
    %Fl is all y data (yout)
    %Tbr is Xbr
    %Tsw is Xsw
    %Tdv is Xdv
    %AllData{SchI,1}=Fdata(1,:);
    AllData{SchI,1}=Fdata(i,:)
    AllData{SchI,2}=Ti;
    AllData{SchI,3}=Fl;
    
   
    
%%%%%%%%%%%REGRESSION:
    regX=[[AllData{i,2}{1,1} AllData{i,2}{1,end}]]
    regY=[AllData{i,3}{1,1} AllData{i,3}{1,end}]

plot(regX,regY,'-')
    done = 0;
    while ~done
    
    datacursormode on;
    
    %first regression :
    waitforbuttonpress;
    dcm_obj = datacursormode(gcf);
    c_info = getCursorInfo(dcm_obj);
    Index1 = c_info.DataIndex;
    waitforbuttonpress;
    dcm_obj = datacursormode(gcf);
    c_info = getCursorInfo(dcm_obj);
    Index2 = c_info.DataIndex;
   
    regX([Index1:Index2]);
    regY([Index1:Index2]);
    fitpar1 = polyfit(regX([Index1:Index2]),regY([Index1:Index2]),1) 
    fitpar2 = fitpar1 * 10^3
    fitfunct = polyval(fitpar1,regX([1:Index2]));
    hold on;
    plot(regX([1:Index2]),fitfunct);
    hold on;
    reply1 = input('correct (y/n)', 's');
    reply1
   
    %second regression:
    waitforbuttonpress;
    dcm_obj = datacursormode(gcf);
    c_info = getCursorInfo(dcm_obj);
    Index3 = c_info.DataIndex;
    waitforbuttonpress;
    dcm_obj = datacursormode(gcf);
    c_info = getCursorInfo(dcm_obj);
    Index4 = c_info.DataIndex;
    
    regX([Index3:Index4]);
    regY([Index3:Index4]);
    fitpar3 = polyfit(regX([Index3:Index4]),regY([Index3:Index4]),1) 
    fitpar4 = fitpar3 * 10^3
    fitfunct = polyval(fitpar3,regX([1:Index4]));
    hold on;
    plot(regX([1:Index4]),fitfunct);
    hold on;
    reply2 = input('correct (y/n)', 's');
    reply2
    
    if and(reply1=='y',reply2=='y')
        done = 1;
    end
   
    AllData{SchI,13}=fitpar1;
    AllData{SchI,14}=fitpar3;
    
    Tsw=(fitpar3(2)-fitpar1(2))/(fitpar1(1)-fitpar3(1))
    
end
hold off;
close(gcf);

%%%%%%%%%%%%%end of regression

    Tbr=AllData{SchI,2}{1,length(AllData{SchI,2})}(1);
    AllData{SchI,4}=Tbr;
    AllData{SchI,5}=Tsw;
    Tdv=AllData{SchI,2}{1,length(AllData{SchI,2})}(length(AllData{SchI,2}{1,length(AllData{SchI,2})})); 
    AllData{SchI,6}=Tdv;

    [Ti LenMic]= feval('plotschnitzmeST_NoAncNoReg',p,schnitzcells,'FYsmins','lengthMicrons',Fdata{i,6},PlotStyles);
    AllData{SchI,7}= LenMic;
    
    Lbr=AllData{SchI,7}{1,length(AllData{SchI,7})}(1);
    AllData{SchI,8}=Lbr;
    
    %below : interpolation of cell length at the coresponding time switch.
    if Tsw<Tbr
        Lsw=interp1(AllData{SchI,2}{1,1},AllData{SchI,7}{1,1},Tsw,'linear');
    else Lsw=interp1(AllData{SchI,2}{1,length(AllData{SchI,2})},AllData{SchI,7}{1,length(AllData{SchI,7})},Tsw,'linear');      
    end
    AllData{SchI,9}=Lsw;
    
    Ldv=AllData{SchI,7}{1,length(AllData{SchI,7})}(length(AllData{SchI,7}{1,length(AllData{SchI,7})})); 
    AllData{SchI,10}=Ldv;
    

    [Ti Phase]= feval('plotschnitzmeST_NoAncNoReg',p,schnitzcells,'FYsmins','phase',Fdata{i,6},PlotStyles);
    AllData{SchI,11}=Phase;
    
    %below : interpolation of cell phase at the coresponding time switch.
    if Tsw<Tbr
        Psw=interp1(AllData{SchI,2}{1,1},AllData{SchI,11}{1,1},Tsw,'linear');
    else Psw=interp1(AllData{SchI,2}{1,length(AllData{SchI,2})},AllData{SchI,11}{1,length(AllData{SchI,11})},Tsw,'linear');      
    end
    AllData{SchI,12}=Psw;
    
%     PrntSpot = 1:length(AllData{SchI,2}{1,1})
%     SisSpot = 1:length(AllData{SchI,2}{1,2})
%     SwSpot = 1:length(AllData{SchI,2}{1,2})
%     AllData{SchI,15}=[PrntSpot SisSpot SwSpot]
    

% To plot Parental data only & Getting the parental data into file AllData
% separately
%     [PTi PFl]= feval('plotschnitzmeST_NoAncNoReg',p,schnitzcells,'FYsmins','MYs',ParentSwSchnitz,PlotStyles);
%     AllData{SchI,12}=PTi;
%     AllData{SchI,13}=PFl;
%     [PTi PLenMic]= feval('plotschnitzmeST_NoAncNoReg',p,schnitzcells,'FYsmins','lengthMicrons',ParentSwSchnitz,PlotStyles);
%     AllData{SchI,14}=PLenMic;



end
