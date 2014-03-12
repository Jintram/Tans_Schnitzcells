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

function optimalShift2 = DJK_getFluorShift_red(p,varargin)

%--------------------------------------------------------------------------
% Input error checking
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 1; functionName = 'DJK_getFluorShift_red';

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
if ~existfield(p,'DJK_saveDir2')
  p.DJK_saveDir2 = [p.analysisDir 'fluor2\'];
end
% Make sure that DJK_saveDir directory exists
if exist(p.DJK_saveDir2)~=7
  [status,msg,id] = mymkdir([p.DJK_saveDir2]);
  if status == 0
    disp(['Warning: unable to mkdir ' p.DJK_saveDir2 ' : ' msg]);
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
fid = fopen([p.DJK_saveDir2 p.movieName '-getFluor2Shift.txt'],'wt');
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Let know what is happening
%--------------------------------------------------------------------------
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, ['Getting fluor2Shift from fluor2 images and seg files.']);
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
  rname= [p.imageDir,p.movieName,'-r-',str3(frameNum),'.tif'];
  if exist(rname)==2
    rimage = imread(rname);
  else
    dispAndWrite(fid, [' * ' str3(frameNum) ' -> Cannot open : ' p.movieName '-r-' str3(frameNum) '.tif in ' p.imageDir]);
    continue;
  end

  % load segmentation file
  filename = [p.segmentationDir, p.movieName, 'seg', str3(frameNum)];
  clear rreg rect rbinning rback phaseFullSize gainr exptr Lc LNsub;
  rreg = [];
  load(filename);
  dispAndWrite(fid, [' * ' str3(frameNum) ' -> loaded ' p.movieName 'seg' str3(frameNum) ' in ' p.segmentationDir]);
  if ~exist('Lc')      
    dispAndWrite(fid, ['       ->  segmentations has not been corrected -> will use LNsub in stead of Lc !!!']);
    Lc = LNsub;
  end
  phaseCropSize = phaseFullSize; % seg file thinks phaseFullSize is full size, but might be crop size

  % still need to resize yimage
  rimage = imresize(rimage,rbinning,'nearest');
  
  %------------------------------------------------------------------------
  % Check Lc & rreg from segmentation file
  %------------------------------------------------------------------------
  % get subimages
  r = double(rreg);
  seg = +(Lc(1+ p.maxShift:end- p.maxShift, 1+ p.maxShift:end- p.maxShift) > 0);
  % try all possible translations
  for di = - p.maxShift: p.maxShift
    for dj = - p.maxShift: p.maxShift
      r_shifted = r( p.maxShift+di+1:end- p.maxShift+di,  p.maxShift+dj+1:end- p.maxShift+dj);
      tot_fluor(di+ p.maxShift+1,dj+ p.maxShift+1) = sum(r_shifted(seg > 0));
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
  r = double(rimage);
  L = zeros(phaseCropSize);
  L((rect(1):rect(3)), (rect(2):rect(4))) = Lc;
  seg = +(L(1+ p.maxShift:end- p.maxShift, 1+ p.maxShift:end- p.maxShift) > 0);
  % try all possible translations
  for di = - p.maxShift: p.maxShift
    for dj = - p.maxShift: p.maxShift
      r_shifted = r( p.maxShift+di+1:end- p.maxShift+di,  p.maxShift+dj+1:end- p.maxShift+dj);
      tot_fluor(di+ p.maxShift+1,dj+ p.maxShift+1) = sum(r_shifted(seg > 0));
    end
  end
  % best translation is the one with largest fluorescence within seg
  [shift_y, shift_x] = find(tot_fluor == max2(tot_fluor));
  best_shift(3) = - (mean(shift_x) -  p.maxShift - 1);
  best_shift(4) = - (mean(shift_y) -  p.maxShift - 1);

  % record and display translation
  frameShift(size(frameShift,1)+1,:) = [frameNum best_shift(1) best_shift(2) best_shift(3) best_shift(4)];
  dispAndWrite(fid, ['       -> best shift of fluor2 is [' num2str(best_shift(1)) ',' num2str(best_shift(2)) '] and [' num2str(best_shift(3)) ',' num2str(best_shift(4)) ']']);
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
%   saveas(fig1,[p.DJK_saveDir2 p.movieName '-histogram_optimal_shift_x.fig']);
%   saveas(fig2,[p.DJK_saveDir2 p.movieName '-histogram_optimal_shift_y.fig']);
  saveSameSize(fig1,'file',[p.DJK_saveDir2 p.movieName '-histogram_optimal_shift_x.png'], 'format', 'png');
  saveSameSize(fig2,'file',[p.DJK_saveDir2 p.movieName '-histogram_optimal_shift_y.png'], 'format', 'png');
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
optimalShift2 = [average(4) average(5)];
%--------------------------------------------------------------------------
