
% Moving average of data points to smoothens the plot.
% y data source is avgFYsource and the filtered data is avgFY.
% The switching point is represented as a red dot.

% If one wants the switching points in the graph; then, the legend doesn't
% work properly. So, one have to chose between putting a legend or switching
% points.

% IMPRTOANT NOTE : there is still error in the %time or %length calculation,
% since the definition of 1 schnitz is from birth till longest point before
% division. The last/first data point for parent-daughter related schnitz
% are not the same. There is a gap in time between the two. The better way
% to calculate %time or %length is by dividing the sum of last parental
% point and first daughter point by 2. 

figure
hold all
clear legendstring
for i=1:size(AllData,1)
    
%      styleMap=['r-';'b-';'g-';'k-';'m-';'c-'];
%      style=char(styleMap(1+mod(i,size(styleMap,1))));
    
      colors=jet(size(AllData,1))
      morecolors=spring(size(AllData,1))
      
      Tbr=AllData{i,4}(1);
      Tsw=AllData{i,5}(1);
      Flsw=AllData{i,14}(1)*Tsw+AllData{i,14}(2)
      SeqAsw=AllData{i,16}(1);
      
% to make the division previous to switching lies at the same time point:

weight=[1/10 2/10 5/10 2/10 1/10]
% weight=[1/4 1/2 1/4]


% %TO PLOT FYmis vs MYs:
% 
% if Tsw>Tbr
% FYtime=[AllData{i,2}{1,1}-AllData{i,2}{1,end}(1) AllData{i,2}{1,end}-AllData{i,2}{1,end}(1)];
% else FYtime=[AllData{i,2}{1,1}-AllData{i,2}{1,1}(1) AllData{i,2}{1,end}-AllData{i,2}{1,1}(1)];
% end
% avgFYsource=[AllData{i,3}{1,1} AllData{i,3}{1,end}];   
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
%                                            % middle number is degree of regression
% %to plot only the averaged graph:
% if Tsw>Tbr
% plot(FYtime,avgFY,'-','Color',colors(i,:))  
% else plot(FYtime,avgFY,'-','Color',morecolors(i,:))
% end    
% 
% % to plot switching points:
% if Tsw>Tbr
% corrTsw=(AllData{i,5}(1)-AllData{i,2}{1,end}(1))
% else corrTsw=(AllData{i,5}(1)-AllData{i,2}{1,1}(1))
% end 
% if Tsw>Tbr
% plot(corrTsw,Flsw,'.','Color',colors(i,:))  
% else plot(corrTsw,Flsw,'.','Color',morecolors(i,:))
% end 

% %to plot both raw data and averaged graph:                                           
% %plot(FYtime,avgFYsource,'.',FYtime,avgFY,'-')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TO PLOT phase vs MYs:

% only the switching schnitz: 
% SchPhase=[AllData{i,11}{1,end}];
% avgFYsource=[ AllData{i,3}{1,end}]; 
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
                                           % middle number is degree of regression

%both parental & switching schnitz:
% if Tsw>Tbr
% SchPhase=[AllData{i,11}{1,1}-1 AllData{i,11}{1,end}];
% else SchPhase=[AllData{i,11}{1,1} AllData{i,11}{1,end}+1];
% end
% avgFYsource=[AllData{i,3}{1,1} AllData{i,3}{1,end}];   
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
%                                            % middle number is degree of regression
% 
% %to plot only the averaged graph:
% if Tsw>Tbr
% plot(SchPhase,avgFY,'-','Color',colors(i,:))  
% else plot(SchPhase,avgFY,'-','Color',morecolors(i,:))
% end 
% %%to plot both raw data and averaged graph:                                           
% %%plot(SchPhase,avgFYsource,'.',FYtime,avgFY,'-')
% 
% % to plot switching points:
% if Tsw>Tbr
% corrTsw=(AllData{i,12}(1)-AllData{i,11}{1,end}(1))
% else corrTsw=(AllData{i,12}(1)-AllData{i,11}{1,1}(1))
% end 
% if Tsw>Tbr
% plot(corrTsw,Flsw,'.r')
% else plot(corrTsw,Flsw,'.r')
% end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TO PLOT PERCENT TIME vs MYs:

% if Tsw>Tbr
% percenttime=[((AllData{i,2}{1,1}-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1)))-1 ...
%               (AllData{i,2}{1,end}-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1))];
% else percenttime=[((AllData{i,2}{1,1}-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1))) ...
%                   ((AllData{i,2}{1,end}-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1)))+1];
% end
% avgFYsource=[AllData{i,3}{1,1} AllData{i,3}{1,end}];   
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
%                                            % middle number is degree of regression
% %to plot only the averaged graph:
% if Tsw>Tbr
% plot(percenttime,avgFY,'-','Color',colors(i,:))  
% else plot(percenttime,avgFY,'-','Color',morecolors(i,:))
% end 
%  
% % to plot switching points:
% if Tsw>Tbr
% percentTsw=(AllData{i,5}(1)-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1))
% else percentTsw=(AllData{i,5}(1)-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1))
% end 
% if Tsw>Tbr
% plot(percentTsw,Flsw,'.r')%'.','Color',colors(i,:))  
% else plot(percentTsw,Flsw,'.r')%'.','Color',morecolors(i,:))
% end 

%%SPECIAL : TO PLOT PERCENT TIME vs MYS with normalized MYS
% if Tsw>Tbr
% percenttime=[((AllData{i,2}{1,1}-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1)))-1 ...
%               (AllData{i,2}{1,end}-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1))];
% else percenttime=[((AllData{i,2}{1,1}-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1))) ...
%                   ((AllData{i,2}{1,end}-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1)))+1];
% end
% avgFYsource=[AllData{i,3}{1,1}-AllData{i,3}{1,1}(1) AllData{i,3}{1,end}-AllData{i,3}{1,1}(1)];   
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
%                                            % middle number is degree of regression
% %to plot only the averaged graph:
% if Tsw>Tbr
% plot(percenttime,avgFY,'-','Color',colors(i,:))  
% else plot(percenttime,avgFY,'-','Color',morecolors(i,:))
% end 
%  
% % to plot switching points:
% if Tsw>Tbr
% percentTsw=(AllData{i,5}(1)-AllData{i,2}{1,end}(1))/(AllData{i,2}{1,end}(end)-AllData{i,2}{1,end}(1))
% else percentTsw=(AllData{i,5}(1)-AllData{i,2}{1,1}(1))/(AllData{i,2}{1,1}(end)-AllData{i,2}{1,1}(1))
% end 
% if Tsw>Tbr
% plot(percentTsw,Flsw-AllData{i,3}{1,1}(1),'.r')%'.','Color',colors(i,:))  
% else plot(percentTsw,Flsw-AllData{i,3}{1,1}(1),'.r')%'.','Color',morecolors(i,:))
% end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TO PLOT PERCENT LENGTH vs MYs:

% if Tsw>Tbr
% percentlength=[((AllData{i,7}{1,1}-AllData{i,7}{1,1}(1))/(AllData{i,7}{1,1}(end)-AllData{i,7}{1,1}(1)))-1 ...
%                 (AllData{i,7}{1,end}-AllData{i,7}{1,end}(1))/(AllData{i,7}{1,end}(end)-AllData{i,7}{1,end}(1))];
% else percentlength=[((AllData{i,7}{1,1}-AllData{i,7}{1,1}(1))/(AllData{i,7}{1,1}(end)-AllData{i,7}{1,1}(1))) ...
%                     ((AllData{i,7}{1,end}-AllData{i,7}{1,end}(1))/(AllData{i,7}{1,end}(end)-AllData{i,7}{1,end}(1)))+1];
% end
% avgFYsource=[AllData{i,3}{1,1} AllData{i,3}{1,end}];   
% avgFY= sgolayfilt(avgFYsource,1,5,weight); % last number(fame length) have to be ODD
%                                            %% middle number is degree of regression
% %to plot only the averaged graph:
% if Tsw>Tbr
% plot(percentlength,avgFY,'-','Color',colors(i,:))  
% else plot(percentlength,avgFY,'-','Color',morecolors(i,:))
% end 
% %to plot switching points:
% if Tsw>Tbr
% percentLsw=(AllData{i,9}(1)-AllData{i,7}{1,end}(1))/(AllData{i,7}{1,end}(end)-AllData{i,7}{1,end}(1))
% else percentLsw=(AllData{i,9}(1)-AllData{i,7}{1,1}(1))/(AllData{i,7}{1,1}(end)-AllData{i,7}{1,1}(1))
% end 
% if Tsw>Tbr
% plot(percentLsw,Flsw,'.r')%,'Color',colors(i,:))  
% else plot(percentLsw,Flsw,'.r')%,'Color',morecolors(i,:))
% end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TO PLOT PHASE vs #SeqA SPOTS:

% %only the switching schnitz: 
% SchPhase=[AllData{i,11}{1,end}];
% SeqAnr=[AllData{i,15}{1,1} AllData{i,15}{1,end}]; 

                                           
%both parental & switching schnitz:
if Tsw>Tbr
SchPhase=[AllData{i,11}{1,1}-1 AllData{i,11}{1,end}];
else SchPhase=[AllData{i,11}{1,1} AllData{i,11}{1,end}+1];
end
SeqAnr=[AllData{i,15}{1,1} AllData{i,15}{1,end}];   


if Tsw>Tbr
plot(SchPhase,SeqAnr,'-','Color',colors(i,:))  
else plot(SchPhase,SeqAnr,'-','Color',morecolors(i,:))
end  

%to plot switching points:
if Tsw>Tbr
corrTsw=(AllData{i,12}(1)-AllData{i,11}{1,end}(1))
else corrTsw=(AllData{i,12}(1)-AllData{i,11}{1,1}(1))
end 
if Tsw>Tbr
plot(corrTsw,SeqAsw,'.r')
else plot(corrTsw,SeqAsw,'.r')
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%legendstring(i)=AllData{i,1}(1);
end
%legend(legendstring,'Location','Best')
