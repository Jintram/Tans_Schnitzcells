% DJK_getFluorShift takes original fluor images and segmentation files, and
% determines shift between fluor and phase image. Does this by trying
% different shifts and looking for maximum fluorescence within
% segmentation.
%
% OUTPUT
% 'optimalShift'  Best shift in case of getShift mode, otherwise empty.
%
% REQUIRED ARGUMENTS:
% 'p'             
%
% OPTIONAL ARGUMENTS:
% 'manualRange'   These frames will be treated
% 'DJK_saveDir'   Folder where tiff files are saved
%                 default: '\analysis\fluor\'
% 'maxShift'      Shifts the y image maximally this much for getShift 
%                 default: 7
% 'onScreen' = 0  automatically save and close images (default)
%              1  will ask to save and close images

function optimalShift = DJK_getFluorShift(p,varargin)

%--------------------------------------------------------------------------
% Input error checking
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 1; functionName = 'DJK_correctFluorImage';

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
% Override any schnitzcells parameters/defaults given optional fields/values
%--------------------------------------------------------------------------
% If explicit manualRange is not given, take all segmentation files
if ~existfield(p,'manualRange')
  % Get directory of existing segmentation files 
  outprefix = [p.movieName 'seg'];
  D = dir([p.segmentationDir, outprefix, '*.mat']);
  [S,I] = sort({D.name}');
  D = D(I);
  numpos= findstr(D(1).name, '.mat')-3;
  
  segNameStrings = char(S);
  p.manualRange = str2num(segNameStrings(:,numpos:numpos+2))';
end

% If explicit DJK_saveDir is not given, define it
if ~existfield(p,'DJK_saveDir')
  p.DJK_saveDir = [p.analysisDir 'fluor\'];
end
% Make sure that DJK_saveDir directory exists
if exist(p.DJK_saveDir)~=7
  [status,msg,id] = mymkdir([p.DJK_saveDir]);
  if status == 0
    disp(['Warning: unable to mkdir ' p.DJK_saveDir ' : ' msg]);
    return;
  end
end

% If explicit maxShift is not given, maxShift is 7
if ~existfield(p,'maxShift')
  p.maxShift = 7;
end

if ~existfield(p,'onScreen')
  p.onScreen = 0;
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Open file to write results to
%--------------------------------------------------------------------------
frameShift = []; %holder for optimal shifts for each frame
fid = fopen([p.DJK_saveDir p.movieName '-getFluorShift.txt'],'wt');
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Let know what is happening
%--------------------------------------------------------------------------
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, ['Getting fluorShift from fluor images and seg files.']);
dispAndWrite(fid, ['maxShift is ' num2str(p.maxShift)]);
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, ['Analyzing ' num2str(length(p.manualRange)) ' frames from ' num2str(p.manualRange(1)) ' to ' num2str(p.manualRange(end))]);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% LOOP OVER SEG FILES AND NORMALIZATION OF FLUOR
%--------------------------------------------------------------------------
% loop over frames
for frameNum = p.manualRange
  
  % load complete fluor image (ALSO THIS WHEN p.TIFFonly)
  yname= [p.imageDir,p.movieName,'-y-',str3(frameNum),'.tif'];
  if exist(yname)==2
    yimage = imread(yname);
  else
    dispAndWrite(fid, [' * ' str3(frameNum) ' -> Cannot open : ' p.movieName '-y-' str3(frameNum) '.tif in ' p.imageDir]);
    continue;
  end

  % load segmentation file
  filename = [p.segmentationDir, p.movieName, 'seg', str3(frameNum)];
  clear yreg rect ybinning yback phaseFullSize gainy expty Lc LNsub;
  yreg = [];
  load(filename);
  dispAndWrite(fid, [' * ' str3(frameNum) ' -> loaded ' p.movieName 'seg' str3(frameNum) ' in ' p.segmentationDir]);
  if ~exist('Lc')      
    dispAndWrite(fid, ['       ->  segmentations has not been corrected -> will use LNsub in stead of Lc !!!']);
    Lc = LNsub;
  end
  phaseCropSize = phaseFullSize; % seg file thinks phaseFullSize is full size, but might be crop size

  % still need to resize yimage
  yimage = imresize(yimage,ybinning,'nearest');
  
  %------------------------------------------------------------------------
  % Check Lc & yreg from segmentation file
  %------------------------------------------------------------------------
  % get subimages
  y = double(yreg);
  seg = +(Lc(1+ p.maxShift:end- p.maxShift, 1+ p.maxShift:end- p.maxShift) > 0);
  % try all possible translations
  for di = - p.maxShift: p.maxShift
    for dj = - p.maxShift: p.maxShift
      y_shifted = y( p.maxShift+di+1:end- p.maxShift+di,  p.maxShift+dj+1:end- p.maxShift+dj);
      tot_fluor(di+ p.maxShift+1,dj+ p.maxShift+1) = sum(y_shifted(seg > 0));
    end
  end
  % best translation is the one with largest fluorescence within seg
  [shift_y, shift_x] = find(tot_fluor == max2(tot_fluor)); % find returns [row, col]
  best_shift(1) = - (mean(shift_x) -  p.maxShift - 1);
  best_shift(2) = - (mean(shift_y) -  p.maxShift - 1);
  %------------------------------------------------------------------------

  
  %------------------------------------------------------------------------
  % Check Lc & loaded y image
  %------------------------------------------------------------------------
  % get subimages
  y = double(yimage);
  L = zeros(phaseCropSize);
  L((rect(1):rect(3)), (rect(2):rect(4))) = Lc;
  seg = +(L(1+ p.maxShift:end- p.maxShift, 1+ p.maxShift:end- p.maxShift) > 0);
  % try all possible translations
  for di = - p.maxShift: p.maxShift
    for dj = - p.maxShift: p.maxShift
      y_shifted = y( p.maxShift+di+1:end- p.maxShift+di,  p.maxShift+dj+1:end- p.maxShift+dj);
      tot_fluor(di+ p.maxShift+1,dj+ p.maxShift+1) = sum(y_shifted(seg > 0));
    end
  end
  % best translation is the one with largest fluorescence within seg
  [shift_y, shift_x] = find(tot_fluor == max2(tot_fluor));
  best_shift(3) = - (mean(shift_x) -  p.maxShift - 1);
  best_shift(4) = - (mean(shift_y) -  p.maxShift - 1);

  % record and display translation
  frameShift(size(frameShift,1)+1,:) = [frameNum best_shift(1) best_shift(2) best_shift(3) best_shift(4)];
  dispAndWrite(fid, ['       -> best shift of fluor is [' num2str(best_shift(1)) ',' num2str(best_shift(2)) '] and [' num2str(best_shift(3)) ',' num2str(best_shift(4)) ']']);
  %------------------------------------------------------------------------
  
end 
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% AVERAGE OUTPUT OF SHIFT CHECK
%--------------------------------------------------------------------------
average = round(mean(frameShift));
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, [' * Best average shifts are  [' num2str(average(2)) ',' num2str(average(3)) '] and  [' num2str(average(4)) ',' num2str(average(5)) ']']);

% Show histograms
scrsz = get(0, 'ScreenSize');
fig1 = figure('Position', [151 scrsz(4)-200 scrsz(3)-130 scrsz(4)-200], 'visible','off');
hist(frameShift(:,4));
xlabel('Optimal shifts for x');
xlim([-p.maxShift-1 p.maxShift+1]);
hold off;

fig2 = figure('Position', [151 scrsz(4)-200 scrsz(3)-130 scrsz(4)-200], 'visible','off');
hist(frameShift(:,5));
xlabel('Optimal shifts for y');
xlim([-p.maxShift-1 p.maxShift+1]);

% Ask to save the figure
if p.onScreen
  set(fig1,'visible','on');
  set(fig2,'visible','on');
  saveFigInput = questdlg('Save Figures?','Save Figures?','Yes','Yes and Close','No','Yes');
  pause(0.2);
else
  saveFigInput='Yes and Close';
end

if (upper(saveFigInput(1))=='Y')
%   saveas(fig1,[p.DJK_saveDir p.movieName '-histogram_optimal_shift_x.fig']);
%   saveas(fig2,[p.DJK_saveDir p.movieName '-histogram_optimal_shift_y.fig']);
  saveSameSize(fig1,'file',[p.DJK_saveDir p.movieName '-histogram_optimal_shift_x.png'], 'format', 'png');
  saveSameSize(fig2,'file',[p.DJK_saveDir p.movieName '-histogram_optimal_shift_y.png'], 'format', 'png');
  if (strcmp(saveFigInput,'Yes and Close'))
    close(fig1);close(fig2);
    pause(0.2);
  end
  dispAndWrite(fid, [' * Saved histogram of optimal shift for x in ' p.movieName '-histogram_optimal_shift_x.png']);
  dispAndWrite(fid, [' * Saved histogram of optimal shift for y in ' p.movieName '-histogram_optimal_shift_y.png']);
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Close file to write results to
%--------------------------------------------------------------------------
dispAndWrite(fid, ['-------------------------------------------------']);
fclose(fid);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% OUTPUT
%--------------------------------------------------------------------------
optimalShift = [average(4) average(5)];
%--------------------------------------------------------------------------
