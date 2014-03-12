function [piecepoly,binPlotXvalue, averageBinData] = NW_plotCellCycleDependence(p, schnitzcells, fieldY, numberBins, varargin);
% NW_plotCellCycleDependence plots the value of fieldY with respect to the
% relative time of a Schnitz in its life cycle. Each cellular life cycle is
% scaled to [0 1]. For the exact way of mapping, see 'whichTimeReference'
% within the program.
% This should allow to find periodic fluctuations in values (e.g. growth rate)
% due to the cell cycle. Fluctuations might be biological or measurement
% artefacts
% Data is averaged over bins of custom size. A function to original data
% can be fitted (but bins is better and more up-to-date)
% The function assumes evenly spaced timefields and only uses cells with a
% complete cell cycle
%
% ****************************
% 'real-time-mode' currently ignores the first 25 schnitzes. reason: for
% fluorescence data, noise_.. should be used. The here substracted mean
% should come from decorrelated cell cycles (i.e. not all cells dividing
% simultaneously)
% ****************************
%
% ****************************
% If you want to look at fluorescence data (maybe also growth data, haven't
% checked yet), use e.g. noise_Y6_mean instead of Y6_mean. The plot of
% Y6_mean can be very distorted if a global trend of fluorescence values
% (e.g. monotoneous (strong) increase) exists.
% ****************************
%
%
% OUTPUT
% plots
%
% piecepoly         piecewise polynomial. calculated via spline/linear..
%                   interpolation of the mean values of each bin. Is used
%                   as input in NW_correctCellCycle 
% binPlotXvalue    center points of each bin on x-axis (relative time)
%                  (output not needed)
% averageBinData   average Y-values for each bin (output not needed)
%
% REQUIRED ARGUMENTS:
% 'p'
% 'schnitzcells'  - schnitzcells structure, where useForPlot must be set
% 'fieldY'        - field from schnitzcells used for Y axis
% 'numberBins'    - Sets how many bins are used. For each bin, fieldY is averaged over
%                   all data points within this bin.
%                   Typically 40-50 frames and 5-6 fluo frames exist per
%                   schnitz. Data gets weird if you set more bins than
%                   typically data points per cell cycle exist 
%                   (e.g. muP15_fitNew: exists only for fluo frames ...)
%                   I tried with 2012-03-02 pos6 (MG22 on 0.1%lactose. mu=0.54)
%                   and suggest:
%                   mu-correction: Take muP15_fitNew_all and numberBins=20
%                   YFP-correction: Take noise_Y6_mean and numberBins=6
%                              (fitted_Y.. data has strange features at
%                              borders!)
%                   However, the best is to use NW_testBinningCellCycle and
%                   see for yourself.
%
% OPTIONAL ARGUMENTS:
% 'onScreen' = 0      automatically save and close image (default)
%              1      will only show image, and not ask to save
% 'DJK_saveDir'       Directory where images will be saved. Default:
%                     "p.analysisDir 'schnitzcells\cellcycle\'"
% 'selectionName'
% 'ylim'
% 'mode'              'absolute': absolut values of fieldY are plotted
%                     'relative': fieldY is normalized with its average
%                      value
%                     Default is 'absolute'
% 'interpolMethod'    Method with which average data of each bin is
%                     interpolated. Determines form of piecepoly
%                     Default: 'spline'. Alternative (e.g.): 'linear'
% 'periodicData'      1: data periodic, one bin centered around =0 is the
%                       average of data from 0 to 1/(2#bins) and from
%                       1-1/(2#bins) to 1. This bincenter is a datapoint at
%                       =0 and =1
%                       Should be used for muP15_fitNew where do to
%                       construction (influence of parent and daughter
%                       cells) data is periodic
%                       *    |    *    |    *    |    *
%                       0        0.33      0.66       1
%                      *=bincenter, |=binboarder, first datapt=last datapt
%                         
%                     0: data not periodic. seems to be the case for
%                       fluorescence data! first and last bin have size
%                       'borderBinSize' and are typically smaller. No bin
%                       center at =0 or =1.
%                       | * |    *    |    *    | * |
%                       0  0.05      0.5      0.95  1
%
%                     Default: Program searches for 'muP' in fieldY, if it
%                     exists: =1. if not: =0.
%                     NOTE: in '0-1-mode', bins are always non-periodic!!!
%
%
% 'borderBinSize'    Size of border bins in non-periodic case.
%                    Default=0.05 (good for fluorescence data). Will be 
%                    ignored if periodicData=1.
%


%--------------------------------------------------------------------------
% Set which function should be fitted to fieldY. If you don't want fits,
% set to []. UpToDateConvention(2012-03): use binning and not fitting
%-------------------------------------------------------------------------- 
% Options: 1 : 2nd degree polynomial
%          2 : 4th degree polynomial
%         
% several options may be chosen simultaneously
whichFitFunction=[];
%-------------------------------------------------------------------------- 


%--------------------------------------------------------------------------
% Set time reference and binning mode
%-------------------------------------------------------------------------- 
% Options: '0-1-mode': time points for fieldY are equidistantly distributed
%                      from 0 to 1. Bins are equidistantly distributed from
%                      0 to 1 with size 1/#bins and center (i-0.5)/#bins
%                      (for bin i)
%          'real-time-mode': Time points for a schnitz are extracted from a
%                     variable that exists for every phase image (e.g.
%                     "frames"). The first frame is set to =0, the last to
%                     (#frames-1)/#frames. Hence, the (never reachable)
%                     time =1 corresponds to the frame one after the
%                     schnitz-frame-range, that is the first frame of the
%                     daughter schnitzes. Might be better description
%                     because then time=1 and time=0 both correspond to a
%                     division. 
%                     Time points of fieldY are extracted corresponding to
%                     its frame number
%                     
%  
% Motivation for the 'real-time-mode': 
% 1) For Fluor-data, the first entry of fieldY does not have to correspond 
%    at all to the birth time since fluor images are rare (The same holds
%    for the division time)

whichTimeReference='real-time-mode';
% whichTimeReference='0-1-mode';
%-------------------------------------------------------------------------- 



%--------------------------------------------------------------------------
% Input error checking and parsing
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 4; functionName = 'NW_plotCellCycleDependence'; 

if (nargin < numRequiredArgs) | (mod(nargin,2) ~= (mod(numRequiredArgs,2)) | ~isSchnitzParamStruct(p))
  errorMessage = sprintf('%s\n%s',['Error width input arguments of ' functionName],['Try "help ' functionName '".']);
  error(errorMessage);
end

numExtraArgs = nargin - numRequiredArgs;
if numExtraArgs > 0
  for i=1:2:(numExtraArgs-1)
    if (~isstr(varargin{i}))
      errorMessage = sprintf('%s\n%s',['This input argument should be a String: ' num2str(varargin{i})],['Try "help ' functionName '".']);
      error(errorMessage);
    end
    fieldName = DJK_schnitzfield(varargin{i});
    p.(fieldName) = varargin{i+1};
  end
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Parse the input arguments
% Override any schnitzcells parameters/defaults given optional fields/values
%--------------------------------------------------------------------------
% If onScreen, nothing is saved to disc automatically
if ~existfield(p,'onScreen')
  p.onScreen = 0;
end
if ~existfield(p,'selectionName')
  p.selectionName = '';
end
if ~existfield(p,'mode')
  p.mode = 'absolute';
end
if ~existfield(p,'interpolMethod')
  p.interpolMethod = 'spline';
end
% Just in case it has not been set yet
if ~existfield(p,'DJK_saveDir')
  p.DJK_saveDir = [p.analysisDir 'schnitzcells' filesep 'cellcycle' filesep];
end
if length(p.selectionName) > 0
  p.DJK_saveDir = [p.DJK_saveDir p.selectionName filesep];
end  
% Make sure that DJK_saveDir directory exists
if exist(p.DJK_saveDir)~=7
  [status,msg,id] = mymkdir([p.DJK_saveDir]);
  if status == 0
    disp(['Warning: unable to mkdir ' p.DJK_saveDir ' : ' msg]);
    return;
  end
end
% periodic binning?
if ~existfield(p,'periodicData')
    if isempty(strfind(fieldY,'muP')) % typically fluorescence data -> not periodic
        p.periodicData=0;
    else
        p.periodicData=1;
    end
end
if ~existfield(p,'borderBinSize')    
  p.borderBinSize = 0.05;
end

%--------------------------------------------------------------------------
% Let know what is happening
%--------------------------------------------------------------------------
if p.periodicData==0
     disp(['Will use non-periodic bins with borderBinSize=' num2str(p.borderBinSize)])
else
     disp(['Will use periodic bins.'])     
end
disp(['Number of bins=' num2str(numberBins)])
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Check Time referene mode
%--------------------------------------------------------------------------
if (~(strcmp(whichTimeReference,'0-1-mode')==1)) & ~(strcmp(whichTimeReference,'real-time-mode')==1)
    disp(['Unknown time reference mode. Exiting...']);
    return
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Check Schnitzcells
%--------------------------------------------------------------------------
if length(schnitzcells) < 1
  disp('Schnitzcells is empty. Not plotting!');
  return;
end

if ~existfield(schnitzcells(1),fieldY)
  disp(['Field ' fieldY ' does not exist. Not plotting!']);
  return;
end

% check if field "frames" for time calculation exists
if (strcmp(whichTimeReference,'real-time-mode')==1) & (~existfield(schnitzcells(1),'frames'))
  disp(['Field ''frames'' does not exist. Cannot calculate Time. Exiting...']);
  return;
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Get time/frame field in case of 'real-time-mode' 
%--------------------------------------------------------------------------
if (strcmp(whichTimeReference,'real-time-mode')==1)
    % if fieldY exists for all frames, take "frames" as timefield
    testschnitznr=100;
    if length(schnitzcells(testschnitznr).frames)==length(schnitzcells(testschnitznr).(fieldY))
        mytimefield='frames';
   %elseif length(schnitzcells(1).frames)+1==length(schnitzcells(1).(fieldY))
   %     mytimefield='frames'; %necessary for fitted_Y6_mean since error in
   %     data association
        
    % if fieldY exists for less frames, try with fluo-frames as timefield
    else
        %get 1st real fluor timefield
        if strcmp(p.fluor1,'none')==0
          mytimefield=[upper(p.fluor1) '_frames'];
        elseif strcmp(p.fluor2,'none')==0
          mytimefield=[upper(p.fluor2) '_frames'];
        elseif strcmp(p.fluor3,'none')==0
          mytimefield=[upper(p.fluor2) '_frames'];
        else
          disp(['Don''t find appropriate time points (frames) for fieldY. No FluorColor? Exiting...']);
          return
        end
        if length(schnitzcells(testschnitznr).(mytimefield))==length(schnitzcells(testschnitznr).(fieldY))
            disp(['Will use ' mytimefield ' as time/frame field.'])
        else
            disp(['Don''t find appropriate time points (frames) for fieldY. I tried fields of schnitz ' num2str(testschnitznr) ...
                'If bad choice, change ''testschnitznr'' in program. Exiting...']);
            return
        end
    end
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Get data to plot and do plot
%--------------------------------------------------------------------------
useAllcells = ~existfield(schnitzcells(1),'useForPlot'); %if useForPlot has not been set at all
  
if (strcmp(whichTimeReference,'real-time-mode')==1)
    figureName = ['cellcycle_' fieldY '_' num2str(numberBins) 'Bins_' p.mode 'Mode_realTime'];
else
    figureName = ['cellcycle_' fieldY '_' num2str(numberBins) 'Bins_' p.mode 'Mode_0-1-Time'];
end

% make figure with full screen size
fig1=figure;
scrsz = get(0, 'ScreenSize');
set(fig1,'Position', [50 50 scrsz(3)-200 scrsz(4)-150], 'Name', figureName);%, 'visible','off');
clf
hold on


% ********************************************************************
% TIMEREFERENCE: 0-1-mode
% ********************************************************************
if (strcmp(whichTimeReference,'0-1-mode')==1)
% single traces
    allData=[];
    schnitzcounter=0;
    birthmean=0;
    divisionmean=0;
    for schnitz = 1:length(schnitzcells)
      if useAllcells | schnitzcells(schnitz).useForPlot
          clear dataRelTime dataY
          %dataRelTime=(schnitzcells(schnitz).frames-2)/(length(schnitzcells(schnitz).frames)-1); %transform time to interval [0,1]
          deltaTime=1/(length(schnitzcells(schnitz).(fieldY))-1);
          dataRelTime=[0:deltaTime:1];
          dataY=schnitzcells(schnitz).(fieldY);
          if p.mode=='relative'
              % debugging
              % disp(['schnitz=', num2str(schnitz) , '  av_mu_fitNew=' num2str(schnitzcells(schnitz).av_mu_fitNew), '  mean(' , num2str(fieldY), ')=' num2str(mean(dataY))]);
              dataY=dataY./(mean(dataY));          
          end
          allData=[allData;dataRelTime',dataY'];
          plot(dataRelTime,dataY,'.-','Color',schnitz/length(schnitzcells)*[0.8 0.8 0.8])
          schnitzcounter=schnitzcounter+1;
          birthmean=birthmean+dataY(1);
          divisionmean=divisionmean+dataY(length(dataY));
      end
    end
    %allData; %debugging
end
% ********************************************************************

% ********************************************************************
% TIMEREFERENCE: real-time-mode
% ********************************************************************
if (strcmp(whichTimeReference,'real-time-mode')==1)
    % single traces
    allData=[];
    schnitzcounter=0;
    birthmean=0; % average fieldY for first entry, only considering entries at t=0
    firstentrymean=0; % average fieldY for first entry
    firstentrytimemean=0; % average time for first entry
    lastentrymean=0;  % analog to first entry
    lastentrytimemean=0;
    schnitzcounterinitialfluoframes=0;
    for schnitz = 25:length(schnitzcells)
      if (useAllcells | schnitzcells(schnitz).useForPlot) & schnitzcells(schnitz).completeCycle==1
          clear dataRelTime dataY totalTime
          totalTime=length(schnitzcells(schnitz).frames); %# frames a schnitz lives
          YdataTime=schnitzcells(schnitz).(mytimefield)-schnitzcells(schnitz).frames(1); %absolute time with initial frame set to 0
          YdataTime=YdataTime/totalTime; % relative time (birth=0. last frame=(#frames-1)/#frames
          
          dataY=schnitzcells(schnitz).(fieldY);
          %if length(dataY)>length(YdataTime) %necessary for fitted_Y6_mean
          %since error in data association
          %    dataY(length(dataY))=[]; 
          %end
          
          
          if p.mode=='relative'
              % debugging
              % disp(['schnitz=', num2str(schnitz) , '  av_mu_fitNew=' num2str(schnitzcells(schnitz).av_mu_fitNew), '  mean(' , num2str(fieldY), ')=' num2str(mean(dataY))]);
              dataY=dataY./(mean(dataY));          
          end
          
          % especially in noise-variables, it can happen, that entries are
          % empty (I think then these schnitzes are part of a non used
          % branch and unfortunately the noise-addition in
          % NW_addToSchntizesnoise is based on branchStructure)
          % Update (2012-03): if samelength=0 is added in DJK_getBranches
          % within the NW_addToSchnitzcellsNoise, all schnitzes get noise
          % values. Still, the check is no harm
          if ~isempty(dataY)
              plot(YdataTime,dataY,'.-','Color',schnitz/length(schnitzcells)*[0.8 0.8 0.8])

              % add same data at (tau+1) for periodicity 
              if p.periodicData==1
                  plot(YdataTime+1,dataY,'.','Color',[0.7 0.3 0.3])
              end

              %get averages for 1st/last entry/birth time
              if length(dataY)>0 % should always be the case for normal schnitzes
                    firstentrymean=firstentrymean+dataY(1);
                    firstentrytimemean=firstentrytimemean+YdataTime(1);
                    lastentrymean=lastentrymean+dataY(length(dataY));
                    lastentrytimemean=lastentrytimemean+YdataTime(length(dataY));
                    schnitzcounter=schnitzcounter+1;
                    if YdataTime(1)==0
                         birthmean=birthmean+dataY(1);
                         schnitzcounterinitialfluoframes=schnitzcounterinitialfluoframes+1;
                    end
              end

              allData=[allData;YdataTime',dataY'];
          end

          
      end
    end
    %allData; %debugging
end
% ********************************************************************
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Do Fitting (does not make sense with periodic repetitions i.e. p.periodicData=1!!)
%--------------------------------------------------------------------------
% fit function
x=0:0.01:1;
if ismember (1,whichFitFunction) % 2nd degree polynomial
    fitCoeffs = polyfit(allData(:,1),allData(:,2),2);  
    y=fitCoeffs(1)*x.*x+fitCoeffs(2)*x+fitCoeffs(3); 
    plot(x,y,'r','LineWidth',2)
end
if ismember (2,whichFitFunction) % 4th degree polynomial
    fitCoeffs2 = polyfit(allData(:,1),allData(:,2),4); 
    y2=fitCoeffs2(1)*x.^4+fitCoeffs2(2)*x.^3+fitCoeffs2(3)*x.^2+fitCoeffs2(4)*x+fitCoeffs2(5); 
    plot(x,y2,'g','LineWidth',2)
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Do averaging over bins
%--------------------------------------------------------------------------
% ********************************************************************
% TIMEREFERENCE: 0-1-mode
% ********************************************************************
if (strcmp(whichTimeReference,'0-1-mode')==1)
    binCounter=zeros(numberBins,1); % sums up how many data points in each bin
    binThresholds=zeros(numberBins,1); % starting value of each bin. if numberBins=2, binThresholds would be =[0, 0.5]
    for i=1:length(binThresholds)
        binThresholds(i)=(i-1)/numberBins;
    end
    binPlotXvalue=binThresholds+0.5*1/numberBins; % gt good xvalues for plot in center of each bin

    %sumBinData=zeros(numberBins,1); % one entry: sum of all fieldY values corresponding to one bin
    averageBinData=zeros(numberBins,1); %average for each bin
    stddevBinData=zeros(numberBins,1); %standard deviation for each bin

    % loop over data and bin it
    for runbin=1:numberBins
        binMin=binThresholds(runbin);
        if runbin<numberBins
            binMax=binThresholds(runbin+1);
        else binMax=1.01; end;
        bin_idx=find(allData(:,1)>=binMin & allData(:,1)<binMax);
        if ~isempty(bin_idx)
            binCounter(runbin)=length(bin_idx);
            sumBinData(runbin)=sum(allData(bin_idx,2));
            clear mymean mystddev myRunBinData;
            myRunBinData=allData(bin_idx,2);
            mymean=mean(myRunBinData);
            mystddev=std(myRunBinData,1); %flag=1: divided by n (see matlab docu)
            averageBinData(runbin)=mymean;
            stddevBinData(runbin)=mystddev;
        end
    end


    % plot binned average function with errorbars
    averageBinData; %debugging
    stddevBinData; %debugging
    errorbar(binPlotXvalue,averageBinData,stddevBinData,'.r','MarkerSize',20)
    %give basic on Screen output 
    %disp(['binCenter   mean   stddev']);
    %[binPlotXvalue,averageBinData,stddevBinData]
    %mean(averageBinData)
    %averageBinData
end
% ********************************************************************


% ********************************************************************
% TIMEREFERENCE: real-time-mode
% ********************************************************************
if (strcmp(whichTimeReference,'real-time-mode')==1)
    
    if p.periodicData==0
        binCounter=zeros(numberBins,1); % sums up how many data points in each bin
        %binThresholds=[0 0.5/numberBins:(1/numberBins):(1-1.5/numberBins)]'; % starting value of each bin. see intro comments
        binThresholds=zeros(numberBins,1);
        %binPlotXvalue=[0:1/numberBins:(1-1/numberBins)]; % get good centered xvalues for plot in center of each bin
        binPlotXvalue=zeros(numberBins,1);

        binThresholds(2)=p.borderBinSize; % first and last bin smaller
        incrbin1=binThresholds(2);
        binPlotXvalue(1)=incrbin1/2;
        incr=(1-2*binThresholds(2))/(numberBins-2);
        binThresholds(3:numberBins)=[incrbin1+incr:incr:0.999];
        binPlotXvalue(2:numberBins-1)=[incrbin1+0.5*incr:incr:0.999];
        binPlotXvalue(length(binPlotXvalue))=1-0.5*incrbin1;

        %binThresholds' %  some output
        %binPlotXvalue'
        
        %sumBinData=zeros(numberBins,1); % one entry: sum of all fieldY values corresponding to one bin
        averageBinData=zeros(numberBins,1); %average for each bin
        stddevBinData=zeros(numberBins,1); %standard deviation for each bin
        
    
    elseif p.periodicData==1
        binCounter=zeros(numberBins+1,1); % sums up how many data points in each bin
        % values above highest bin Threshold will be associated to a bin at
        % =0 (first bin) which shall be identical to a pt at =1
        binThresholds=[0 0.5/numberBins:(1/numberBins):(1-0.5/numberBins)]'; % starting value of each bin. see intro comments
        % first bin also gets very late yfp-data (+ very early until 1/2#bins)
        % but up to here still calculated seperately as an extra bin at
        % tau=1
        
        binPlotXvalue=[0:1/numberBins:1]'; % gt good xvalues for plot in center of each bin (not centered for first and last bin!)
        
        %binThresholds' % some output
        %binPlotXvalue'
     
        
        %sumBinData=zeros(numberBins,1); % one entry: sum of all fieldY values corresponding to one bin
        averageBinData=zeros(numberBins+1,1); %average for each bin
        stddevBinData=zeros(numberBins+1,1); %standard deviation for each bin

    end
    
    

    % loop over data and bin it
    for runbin=1:length(binCounter)
        binMin=binThresholds(runbin);
        if runbin<numberBins
            binMax=binThresholds(runbin+1);
        else binMax=1.000001; end;
        bin_idx=find(allData(:,1)>=binMin & allData(:,1)<binMax);
        if ~isempty(bin_idx)
            binCounter(runbin)=length(bin_idx);
            %sumBinData(runbin)=sum(allData(bin_idx,2));
            clear mymean mystddev myRunBinData;
            myRunBinData=allData(bin_idx,2);
            mymean=mean(myRunBinData);
            mystddev=std(myRunBinData,1); %flag=1: divided by n (see matlab docu)
            averageBinData(runbin)=mymean;
            stddevBinData(runbin)=mystddev;
            %disp([num2str(runbin)    '    '   num2str(length(myRunBinData))]) %debugging
        end
    end
    
    % take 1st bin and last (artificial) bin at tau=1 together STDEV WRONG!
    if p.periodicData==1
        doubleBinSum=averageBinData(1)*binCounter(1)+averageBinData(length(averageBinData))*binCounter(length(binCounter));
        totalCounter=binCounter(1)+binCounter(length(binCounter));
        averageBinData(1)=doubleBinSum(1)/totalCounter;
        stddevBinData(1)=0;
        averageBinData(length(averageBinData))=averageBinData(1);
        stddevBinData(length(stddevBinData))=0;
    end
    


    % plot binned average function with errorbars
    averageBinData; %debugging
    stddevBinData; %debugging
    errorbar(binPlotXvalue,averageBinData,stddevBinData,'.r','MarkerSize',20)
    %give basic on Screen output 
    %disp(['binCenter   mean   stddev']);
    %[binPlotXvalue,averageBinData,stddevBinData]
    %mean(averageBinData)
    %averageBinData
end
% ********************************************************************


%--------------------------------------------------------------------------
% Do interpolation of bins (stddevs ignored) (and plot)
%--------------------------------------------------------------------------
piecepoly=interp1(binPlotXvalue,averageBinData,p.interpolMethod,'pp');

xx=0:0.01:1;
yy=ppval(x,piecepoly);
plot(xx,yy,'-r','LineWidth',2)
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Plot border averages (birth, division)
%--------------------------------------------------------------------------
if (strcmp(whichTimeReference,'0-1-mode')==1)
    birthmean=birthmean/schnitzcounter;
    plot(0,birthmean,'.g','MarkerSize',20)
    divisionmean=divisionmean/schnitzcounter;
    plot(1,divisionmean,'.g','MarkerSize',20)
end
if (strcmp(whichTimeReference,'real-time-mode')==1)
    birthmean=birthmean/schnitzcounterinitialfluoframes;
    plot(0,birthmean,'.g','MarkerSize',20)
    firstentrymean=firstentrymean/schnitzcounter;
    firstentrytimemean=firstentrytimemean/schnitzcounter;
    lastentrymean=lastentrymean/schnitzcounter;
    lastentrytimemean=lastentrytimemean/schnitzcounter;
    plot(firstentrytimemean,firstentrymean,'.b','MarkerSize',20)
    plot(lastentrytimemean,lastentrymean,'.b','MarkerSize',20)

end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
% Add labels, title, etc
%--------------------------------------------------------------------------
% add statistics text
increment=0; % don't write text at same position
if ismember(1,whichFitFunction)
    text(0.02,0.98,['2nd degree fit (red): y=', DJK_setDecimalPlaces(fitCoeffs(1),3),'*x^2+', DJK_setDecimalPlaces(fitCoeffs(2),3),'*x+', DJK_setDecimalPlaces(fitCoeffs(3),3), ' max=',DJK_setDecimalPlaces(max(y),3),' min=',DJK_setDecimalPlaces(min(y),3),' ratio(max/min)=',DJK_setDecimalPlaces(max(y)/min(y),3)],       'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
    increment=0.03;
end
if ismember(2,whichFitFunction)
    text(0.02,0.98-increment,['4th degree fit (green): y=', DJK_setDecimalPlaces(fitCoeffs2(1),3),'*x^4+', DJK_setDecimalPlaces(fitCoeffs2(2),3),'*x^3+',...
        DJK_setDecimalPlaces(fitCoeffs2(3),3),'*x^2+', DJK_setDecimalPlaces(fitCoeffs2(4),3),'*x+',...
        DJK_setDecimalPlaces(fitCoeffs2(5),3),' max=',DJK_setDecimalPlaces(max(y2),3),' min=',DJK_setDecimalPlaces(min(y2),3),' ratio(max/min)=',DJK_setDecimalPlaces(max(y2)/min(y2),3)],       'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
    increment=increment+0.03;
end
if ismember(3,whichFitFunction)
    text(0.02,0.98-increment,['blubb'],       'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
end

% label axes
xlabel(['age/cell_cycle_length. Time: ', whichTimeReference],'interpreter','none','FontWeight','bold','FontSize',12); % interpreter to avoid problem with underscores
if p.mode=='absolute'
    ylabel(fieldY,'interpreter','none','FontWeight','bold','FontSize',12);
elseif p.mode=='relative'
    ylabel([fieldY ' / mean_over_each_cellcycle'],'interpreter','none','FontWeight','bold','FontSize',12);
end

% in case xlim or ylim
%if existfield(p,'xlim ')
%    xlim(p.xlim);
%end
if existfield(p,'ylim ')
    ylim(p.ylim);
end
xlim([0 1])

% Add title
title([p.movieDate ' ' p.movieName '    plotted ' num2str(schnitzcounter) ' schnitzes'], ...
      'interpreter','none','FontWeight','bold','FontSize',12);
  
% add Xtick labels
set(gca,'XTick',[0:0.1:1])
set(gca,'XTickLabel',{'0=birth','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1=division'})

% % resize
% set(gca,'Position', [0.1 0.1 0.8 0.8]); %[0.13 0.11 0.69422 0.815]
%--------------------------------------------------------------------------


        
%--------------------------------------------------------------------------
% SAVE AND CLOSE FIGURE (if p.onScreen==0)
%--------------------------------------------------------------------------
if p.onScreen == 0
    saveSameSize(fig1,'file',[p.DJK_saveDir figureName '.png'], 'format', 'png');
    disp([' * Saved plot in ' figureName '.png']);
    close(fig1)
end
%--------------------------------------------------------------------------




%%%%%%%%%%%%%%%%%%%%%%%%%%% from Daan %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function number_string = DJK_setDecimalPlaces(number, decimal_places);
number_string = sprintf(['%1.' num2str(decimal_places) 'f'], number);

% factor = power(10,decimal_places);
% number = number*factor;
% number = floor(number);
% number = number / factor;
% number_string = num2str(number);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%