

function MW_tracker(p, varargin)


% Code from NW_tracker_centroid_vs_area
% ***************************************************************************
%--------------------------------------------------------------------------
% Input error checking
%--------------------------------------------------------------------------
%% When executed as function:
numRequiredArgs = 1;
functionName = 'MW_tracker';

if (nargin < numRequiredArgs) | (mod(nargin,2) ~= (mod(numRequiredArgs,2)) | ~isSchnitzParamStruct(p))
  errorMessage = sprintf('%s\n%s',['Error with input arguments of ' functionName],['Try "help ' functionName '".']);
  error([errorMessage]);
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

%% Processing
% lineageName is the primary tracking output
if ~existfield(p,'lineageName')
  p.lineageName = [p.tracksDir,p.movieName,'_lin.mat'];
end

%{
% by default we track only checked frames, but by setting this flag 
% you can track the uncorrected segmentation 
if ~existfield(p,'trackUnCheckedFrames')
    p.trackUnCheckedFrames = 0;
end
%}

if ~existfield(p,'overwrite')
  p.overwrite = 0;
end
if existfield(p,'override') % backwards compatibility
  p.overwrite = p.override;
  disp('Please use p.overwrite instead of p.override');
end

% Get names of segmentation files in segmentation directory
outprefix = [p.movieName 'seg'];
D = dir([p.segmentationDir, outprefix, '*.mat']);
[S,I] = sort({D.name}');
D = D(I);
numpos= findstr(D(1).name, '.mat')-3;

% If explicit manualRange is not given, take all segmentation files
if ~existfield(p,'manualRange')
  segNameStrings = char(S);
  p.manualRange = str2num(segNameStrings(:,numpos:numpos+2))';
end

% Keep only the frames in the range that contain a corrected segmentation (unless we're tracking un-checked frames)
manualRangeChecked = [];
for frameNum = p.manualRange
  clear Lc 
  load([p.segmentationDir,p.movieName,'seg',str3(frameNum)]);
  if exist('Lc')==1 | p.trackUnCheckedFrames 
    manualRangeChecked = [manualRangeChecked frameNum];
  else
    disp(['Skipping frame ' str3(frameNum) ' (segmentation not corrected). Use p.trackUnCheckedFrames=1 to track unchecked frames.']);
  end
end
p.manualRange = manualRangeChecked;

% if no frames in manualRange, exit here
if length(p.manualRange)==0
  error('No frames found to track. Use p.trackUnCheckedFrames=1 to track unchecked frames.');
end

disp(['Tracking ' num2str(length(p.manualRange)) ' frames ', num2str(p.manualRange(1)), ' to ', num2str(p.manualRange(end))]);
%--------------------------------------------------------------------------


%% Martijn's tracking
count = 2;  % because core schnitz functions ignore frame labels, 
            % and always start counting at 1.
for frameIdx = p.manualRange(2:numel(p.manualRange))
   
    % Actual tracking MW --------------------------------------------------
    disp(['Starting pair ' num2str(frameIdx-1) ', ' num2str(frameIdx) '.']);
    [linklistschnitz, segFile1Path, segFile2Path] = MW_linkframes(p, frameIdx-1, frameIdx);
    % End actual tracking MW ----------------------------------------------
            
    % Some stats required for checking the tracking later:
    % First frame only
    if count==2
        [Lc_fullsize_centered, Lc_fullsize, Lc] = MW_loadLcData(segFile1Path); % TODO redundancy with my fn above!
        rp  = regionprops(Lc_fullsize,'Centroid','Orientation','MajorAxisLength','Area');
        rp2 = regionprops(Lc_fullsize_centered,'Centroid');
        num_pts = size(rp,1);
        for j=1:num_pts
            Points(j).cenx      = rp(j).Centroid(1);
            Points(j).ceny      = rp(j).Centroid(2);
            Points(j).cenx_cent = rp2(j).Centroid(1); % DJK 090410
            Points(j).ceny_cent = rp2(j).Centroid(2); % DJK 090410
            Points(j).ang       = rp(j).Orientation;
            Points(j).len       = rp(j).MajorAxisLength;
            Points(j).areapx    = rp(j).Area;  %NW 2013-12
            Points(j).cellno    = j;
            Points(j).frextra   = frameIdx-1; % MW DEBUG REMOVE
        end
        opts{1}=Points(1:num_pts);
    end    

    % Other frames
    % (Code from NW_tracker_centroid_vs_area)    
    [Lc_fullsize_centered, Lc_fullsize, Lc] = MW_loadLcData(segFile2Path); % TODO redundancy with my fn above!
    rp  = regionprops(Lc_fullsize,'Centroid','Orientation','MajorAxisLength','Area');
    rp2 = regionprops(Lc_fullsize_centered,'Centroid');
    num_pts = size(rp,1);
    for j=1:num_pts
        Points(j).cenx      = rp(j).Centroid(1);
        Points(j).ceny      = rp(j).Centroid(2);
        Points(j).cenx_cent = rp2(j).Centroid(1); % DJK 090410
        Points(j).ceny_cent = rp2(j).Centroid(2); % DJK 090410
        Points(j).ang       = rp(j).Orientation;
        Points(j).len       = rp(j).MajorAxisLength;
        Points(j).areapx    = rp(j).Area;  %NW 2013-12
        Points(j).cellno    = j;
        Points(j).frextra   = frameIdx; % MW DEBUG REMOVE
    end
    opts{count}=Points(1:num_pts);   
    
    count = count+1;
       
    % Skip this pair if tracking file is newer than segfile
    % (This is decided in MW_linkframes, with linklistschnitz==0 as flag.)
    %{
    % (opts do need to be recalculated, so shouldn't do skipping.)
    if linklistschnitz==0, continue, end;
    %}
    
end

%% Save to schnitz format (in .mat)
% No idea what the following code does, but let's see
% Stolen from NW_tracker_centroid_vs_area
% -MW

if count>2 % if frames tracked at all
    disp('Reculculating whole lineage file from tracking files..');

    [P D E G] = DJK_data_treat(p);

    [schnitzcells cellid] = recalc_schnitz(P,D,E,G,p.manualRange,'',opts); %
    schnitzcells = renumberschnitzes(p,schnitzcells); % MW TODO, is this necessary step?

    disp(['saving schnitzcells lineage structure to ' p.lineageName]);
    save(p.lineageName,'schnitzcells');
else
    disp('WARNING: Didn''t track anything! Correct segfiles, set p.overwrite=1 to track frames if desired.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


