% DJK_analyzeMu: determines the mu of the microcolony by an exponential fit
% to the sum of the length of the cells over time. 
%
% By default the fit is done for data between 20 and 100 (um)
%
% If schnitzcells has the field 'useForPlot', only schnitzes that are 1
% there, will be used, otherwise all cells with data will be plotted. 
%
% OUTPUT
% 'fitTime'         first & last timepoint used for mu fitting (calculated
%                   from fitLength
% 'fitMu'
%
% REQUIRED ARGUMENTS:
% 'p'
% 'schnitzcells'    schnitzcells structure, where useForPlot must be set
%
% OPTIONAL ARGUMENTS:
% 'muField'         field from schnitzcells used for mu determination
%                   (default: length_fitNew)
% 'timeField'       default: 'time', but can also be 'Y_time'
% 'fitTime'         time used for fitting, if not set, will determine with fitLength
%                   default: []
% 'fitLength'       if fitTime is not set, will find time where cells have length in between these values
%                   default: [20 100]
% 'manualRange'     allows to analyze a subset of frames
% 'onScreen' = 0    automatically save and close image
%              1    will ask to save and close image (default)
% 'DJK_saveDir'     directory where images will be saved.
%                   default: "p.analysisDir 'schnitzcells\mu'"
% 'selectionName'   
% 'xlim'            default: [0 900]
% 'ylim'            default: [2 2000]
%

function [fitTime, fitMu] = DJK_analyzeMu(p, schnitzcells, varargin);

%--------------------------------------------------------------------------
% Input error checking and parsing
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 2; functionName = 'DJK_analyzeMu';

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
if ~existfield(p,'muField')
  p.muField = 'length_fitNew';
end
if ~existfield(p,'timeField')
  p.timeField = 'time';
end
if ~existfield(p,'fitTime')
  p.fitTime = [];
end
if ~existfield(p,'fitLength')
  p.fitLength = [20 200];
end
% If explicit manualRange is not given, take all in schnitzcells
if ~existfield(p,'manualRange')
  p.manualRange = unique( [schnitzcells.frames] -1);
end
% If onScreen, nothing is saved to disc automatically
if ~existfield(p,'onScreen')
  p.onScreen = 1;
end
% In case it has not been set yet
if ~existfield(p,'selectionName ')
  p.selectionName = '';
end
% In case it has not been set yet
if ~existfield(p,'DJK_saveDir')
  p.DJK_saveDir = [p.analysisDir 'schnitzcells' filesep];
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

if ~existfield(p,'xlim')
  p.xlim = [0 900];
end
if ~existfield(p,'ylim')
  p.ylim = [2 2000];
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Check Schnitzcells
%--------------------------------------------------------------------------
if length(schnitzcells) < 1
  disp('Schnitzcells is empty. Not plotting!');
  return;
end
if ~existfield(schnitzcells(1),p.muField)
  disp(['Field ' p.muField ' does not exist. Not plotting!']);
  return;
end

% check whether field has only 1 value per schnitz
if length([schnitzcells.(p.muField)]) <= length([schnitzcells.P])
  onlyOneDataPoint = 1;
else
  onlyOneDataPoint = 0;
end  
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Get data to plot
%--------------------------------------------------------------------------
useAllcells = ~existfield(schnitzcells(1),'useForPlot');

% initialize alldata
for fr = unique( [schnitzcells.frames] -1);
  alldata_muField_sum(fr) = 0;
  alldata_cellsContributing(fr) = 0;
  alldata_time(fr) = 0;
end

nrCells = 0;
% loop over cells
for cell = 1:length(schnitzcells)
  % check whether cell will be used for plotting
  if useAllcells | schnitzcells(cell).useForPlot
    nrCells = nrCells + 1;
    % loop over frames where cell lives
    for age = 1:length(schnitzcells(cell).frames)
      if length(schnitzcells(cell).(p.muField)) > 0
        
        fr = schnitzcells(cell).frames(age)-1;
        alldata_cellsContributing(fr) = alldata_cellsContributing(fr) + 1;
        alldata_time(fr) = schnitzcells(cell).(p.timeField)(age);
        if onlyOneDataPoint
          alldata_muField_sum(fr) = alldata_muField_sum(fr) + schnitzcells(cell).(p.muField)(1);
        else
          alldata_muField_sum(fr) = alldata_muField_sum(fr) + schnitzcells(cell).(p.muField)(age);
        end
      end
    end
  end
end
 
% loop over frames
data_frames = [];
data_time   = [];
data_muField_sum  = [];
count = 0;
for fr = p.manualRange
  count = count+1;
  data_frames(count)  = fr;
  data_time(count)    = alldata_time(fr);
  data_muField_sum(count)   = alldata_muField_sum(fr);
end

% remove nan data
idx = find(~isnan(data_muField_sum));
data_frames = data_frames(idx);
data_time = data_time(idx);
data_muField_sum = data_muField_sum(idx);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% PLOTTING
%--------------------------------------------------------------------------
% Make Figure Name
figureName = ['mu_' p.muField]; 
figureFileName = ['mu_' p.muField]; 

% determine which data will be used for fitting
if p.fitTime
  fit_idx = find( data_time >= p.fitTime(1) & data_time <= p.fitTime(2) );

  figureName = [figureName '_fitTime' num2str(round(p.fitTime(1))) '_' num2str(round(p.fitTime(2)))]; 
  figureFileName = [figureFileName '_fitTime' num2str(round(p.fitTime(1))) '_' num2str(round(p.fitTime(2)))]; 

% in case p.fitTime has not been set, determine by length
else
  fit_idx = find( data_muField_sum >= p.fitLength(1) & data_muField_sum <= p.fitLength(2) );
  p.fitTime(1) = data_time(fit_idx(1));
  p.fitTime(2) = data_time(fit_idx(end));

  figureName = [figureName '_fitLength' num2str(p.fitLength(1)) '_' num2str(p.fitLength(2))]; 
  figureFileName = [figureFileName '_fitLength' num2str(p.fitLength(1)) '_' num2str(p.fitLength(2))]; 
end
% for output
fitTime = p.fitTime;


% make figure with full screen size
scrsz = get(0, 'ScreenSize');
% fig1 = figure('Position', [1 scrsz(4) scrsz(3) scrsz(4)], 'Name', figureName);
fig1 = figure('Position', [126 scrsz(4)-150 scrsz(3)-125 scrsz(4)-150], 'Name', figureName, 'visible','off');

semilogy(data_time, data_muField_sum, 'o-k', 'MarkerSize',12, 'LineWidth',2);
hold on;

% label axes
xlabel('time (mins)','interpreter','none','FontWeight','bold','FontSize',12); % interpreter to avoid problem with underscores
ylabel(['sum ' p.muField ' (um)'],'interpreter','none','FontWeight','bold','FontSize',12);
% Add title
title([p.movieDate ' ' p.movieName ' for ' num2str(nrCells) ' schnitzes in folder: schnitzcells\\' p.selectionName],'FontWeight','bold','FontSize',12);

% add fitted line
[fitMu A0] = DJK_ExponentialFit(data_time(fit_idx)/60, data_muField_sum(fit_idx));
length_fitted = A0*power(2,fitMu/60*data_time);
hold on;
semilogy(data_time, length_fitted, ':','LineWidth',3);
hold on;
semilogy(data_time(fit_idx), length_fitted(fit_idx), '-','LineWidth',4);

% output mu
text(0.02,0.98,['Fit from (um)  : ' DJK_setDecimalPlaces(p.fitLength(1),0) ' to ' DJK_setDecimalPlaces(p.fitLength(2),0)], 'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
text(0.02,0.96,['Fit from (min) : ' DJK_setDecimalPlaces(p.fitTime(1),0) ' to ' DJK_setDecimalPlaces(p.fitTime(2),0)], 'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
text(0.02,0.94,['Fitted Mu is   : ' DJK_setDecimalPlaces(fitMu,3)], 'sc','FontName','FixedWidth','FontWeight','bold','FontSize',11);
  
% in case xlim or ylim
if existfield(p,'xlim ')
  xlim(p.xlim);
end
if existfield(p,'ylim ')
  ylim(p.ylim);
end

%--------------------------------------------------------------------------

       
%--------------------------------------------------------------------------
% ASKING TO SAVE FIGURE
%--------------------------------------------------------------------------
% Ask to save the figure
if p.onScreen
  set(fig1,'visible','on');
  saveFigInput = questdlg('Save Figure?','Save Figure?','Yes','Yes and Close','No','Yes');
  pause(0.2);
else
  saveFigInput='Yes and Close';
end
if (upper(saveFigInput(1))=='Y')
%     saveas(fig1,[p.DJK_saveDir figureFileName '.fig']);
    saveSameSize(fig1,'file',[p.DJK_saveDir figureFileName '.png'], 'format', 'png');
    if (strcmp(saveFigInput,'Yes and Close'))
        close(fig1);
        pause(0.2);
    end
  disp([' * Saved plot in ' figureFileName '.png']);
end
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function number_string = DJK_setDecimalPlaces(number, decimal_places);
number_string = sprintf(['%1.' num2str(decimal_places) 'f'], number);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%