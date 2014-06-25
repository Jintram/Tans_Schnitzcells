function problemCells = DJK_analyzeTracking(p, varargin);
% DJK_analyzeTracking analyses the complete tracking file. 
%
% Reports on :
% # cells tracked in complete lineage 
%   # cells in manualRange
%     * cells that are in segmentation but not in tree
%     * cells that are orphan (first frame always has orphans)
%     * cells that are barren (cell lineage ends before last frame)
%     * cells that move more than p.pixelsMoveDef pixels between frames 
%     * cells that grow more/less than p.pixelsLenDef pixels between frames 
%     * cells that change length more/less than 20 pixels after division
%                              and grow/shrink more than p.pixelAreaDiv
%
%
% OPTIONAL ARGUMENTS:
%  'lineageName'    allows to use a tracking lineage file other than standard
%
%  'manualRange'    allows to analyze a subset of frames (standard: all framse)
%
%  'DJK_saveDir'    Directory where results will be saved. Defaults to
%                   "p.analysisDir 'tracking\' 'manualRange1_200\'"
%
%  'pixelsMoveDef'  threshold number for moving cell in pixels (default: 10)
%
%  'pixelsLenDef'   threshold numbers for growing cell in pixels. 
%                   default: [-4 6] = shrink 4 of grow more than 6 => weird
%                   Note: old length definition is used (fit of ellipse) ->
%                   majoraxislength. Using 'THIN' WOULD BE BETTER
%
%  'pixelsAreaDiv'   threshold change in px area at division. Extra criterion
%                  in addition to 20px length change because length change
%                  for bent cells (majoraxislength!) is a poor criterion
%                  and often false positive.
%                  default: 70
%
%
% OUTPUT:
% problemcells; a matrix that contains: [schnitzes, frames] which appear
%               problematic. 
%               EDIT MW 2014/06/11: the problem occured for (frame) -> (frame+1)
%

%--------------------------------------------------------------------------
% Input error checking and parsing
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 1;
functionName = 'DJK_analyzeTracking';

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
% If explicit lineageName is not given, use standard
if ~existfield(p,'lineageName')
  p.lineageName = [p.tracksDir,p.movieName,'_lin.mat'];
end

% Load lineage file
if ~(exist(p.lineageName)==2)
  error(['Could not read tracking file ''' p.lineageName '''.']);
end

load(p.lineageName);

% If explicit manualRange is not given, take all frames that are in schnitzcells
if ~existfield(p,'manualRange')
  fr_maximum = -1; fr_minimum = 1000;
  for cell = 1:length(schnitzcells)
    if (max(schnitzcells(cell).frame_nrs) > fr_maximum) 
      fr_maximum = max(schnitzcells(cell).frame_nrs);
    end
    if (min(schnitzcells(cell).frame_nrs) < fr_minimum) 
      fr_minimum = min(schnitzcells(cell).frame_nrs);
    end
  end
  p.manualRange = [fr_minimum-1:fr_maximum-1]; % in schnitzcells frames are +1
end

% If explicit DJK_saveDir is not given, use standard
if ~existfield(p,'DJK_saveDir')
  p.DJK_saveDir = [p.analysisDir 'tracking' filesep 'manualRange' num2str(p.manualRange(1)) '_' num2str(p.manualRange(end)) filesep];
end

% Make sure that DJK_saveDir directory exists
if exist(p.DJK_saveDir)~=7
  [status,msg,id] = mymkdir([p.DJK_saveDir]);
  if status == 0
    disp(['Warning: unable to mkdir ' p.DJK_saveDir ' : ' msg]);
    return;
  end
end

% If explicit pixelsMoveDef is not given, use 10 pixels
if ~existfield(p,'pixelsMoveDef')
    p.pixelsMoveDef = 10;
end

% If explicit pixelsMoveDef is not given, use [-1 4] pixels
if ~existfield(p,'pixelsLenDef')
    p.pixelsLenDef = [-4 6];
end

% If explicit pixelsAreaDiv is not given, use 50 pixels
if ~existfield(p,'pixelsAreaDiv')
    p.pixelsAreaDiv = 70;
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Open file to write results to
%--------------------------------------------------------------------------
fid = fopen([p.DJK_saveDir p.movieName '-tracking.txt'],'wt');
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% PREPARATION OF TRACKING DATA
%--------------------------------------------------------------------------
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, ['Analyzing ' num2str(length(p.manualRange)) ' frames from ' num2str(p.manualRange(1)) ' to ' num2str(p.manualRange(end))]);
dispAndWrite(fid, [' * Saving results in : ' p.DJK_saveDir]);
dispAndWrite(fid, [' * Loaded tracking file from : ' p.lineageName]);

firstFrame = min(p.manualRange);
lastFrame = max(p.manualRange);

% Determine for each cell in schnitzcells whether really in tracking
% indicated by inTracking (schnitzcells(1).inTracking=true)
range = p.manualRange; % (MW 2014/06/11) N+1 fix
nrCellsInTracking = 0;
for cell = 1:length(schnitzcells)
  schnitzcells(cell).inTracking = false;
  if (intersect(range, schnitzcells(cell).frame_nrs))
    schnitzcells(cell).inTracking = true;
    nrCellsInTracking = nrCellsInTracking+1;
  end
end

% Get number of segmented cells of each frame
for frameNum = p.manualRange
  clear LNsub Lc timestamp;
  load([p.segmentationDir, p.movieName, 'seg', str3(frameNum)]);
  if ~exist('Lc') 
    Lc = LNsub;
  end
  NrCellsPerFrame(frameNum) = max2(Lc);
end;

% Get number of cells in tracking for each frame
NrCellsInTrackingPerFrame = zeros(lastFrame, 1);
% MWc loop over schnitzes 
for schnitznum = 1:length(schnitzcells)
  % MWc loop over frames belonging to that schnitz
  for frame = schnitzcells(schnitznum).frame_nrs; % MW 2014/06/11 removal N+1 bug
    % MWc if frame within range
    if (frame<=lastFrame)
      % MWc increase count for that frame
      NrCellsInTrackingPerFrame(frame) = NrCellsInTrackingPerFrame(frame) + 1;
    end;
  end
end

% Find cells that are in segmentation but not in tree
segAndTrackDoNotMatch = zeros(lastFrame, 1);
for frameNum = p.manualRange
  if ~(NrCellsPerFrame(frameNum) == NrCellsInTrackingPerFrame(frameNum))
    segAndTrackDoNotMatch(frameNum) = 1;
  end
end

% Find orphans
nrOrphansInManualRange = 0;
for cell = 1:length(schnitzcells)
  schnitzcells(cell).orphan = true;
  if schnitzcells(cell).P > 0;
    schnitzcells(cell).orphan = false;
  else
    if schnitzcells(cell).inTracking & schnitzcells(cell).frame_nrs(1) > firstFrame % cells in first frame do not count % MW 2014/06/11 removal N+1 bug
      nrOrphansInManualRange = nrOrphansInManualRange + 1;
    end
  end
end

% output of problem cells (schnitz nr + frame)
problemCells = [];

% Find barren cells
framesWithBarrenCells = [];
%nrBarrenInManualRange = 0;
for cell = 1:length(schnitzcells)
  schnitzcells(cell).barren = false;
  if schnitzcells(cell).E==0 | schnitzcells(cell).D==0;
    schnitzcells(cell).barren = true;
    if schnitzcells(cell).inTracking & schnitzcells(cell).frame_nrs(end) < lastFrame % cells in last frame do not count % MW 2014/06/11 removal N+1 bug
      framesWithBarrenCells = [framesWithBarrenCells schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
      problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
      % nrBarrenInManualRange = nrBarrenInManualRange + 1;
    end
  end
end
framesWithBarrenCells = unique(framesWithBarrenCells);

% Find cells moving > p.pixelsMoveDef pixels
framesWithCellsMoving = [];
for cell = 1:length(schnitzcells)
  schnitzcells(cell).moving = [];
  cenx = schnitzcells(cell).cenx_cent(1); % DJK 090410 cenx(i);
  ceny = schnitzcells(cell).ceny_cent(1); % DJK 090410 ceny(i);
  for i = 2:length(schnitzcells(cell).frame_nrs);
    if schnitzcells(cell).inTracking % last frame should be taken in account (MW 2014/06/11)
      cenx_new = schnitzcells(cell).cenx_cent(i); % DJK 090410 cenx(i);
      ceny_new = schnitzcells(cell).ceny_cent(i); % DJK 090410 ceny(i);
      if sqrt( (cenx_new-cenx)^2 + (ceny_new-ceny)^2 ) > p.pixelsMoveDef
        schnitzcells(cell).moving = [schnitzcells(cell).moving schnitzcells(cell).frame_nrs(i-1)]; % MW 2014/06/11 here -1 needed
        framesWithCellsMoving = [framesWithCellsMoving schnitzcells(cell).frame_nrs(i-1)];        
        problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(i-1)];                   
%         disp([str3(cell) ' moved ' num2str(sqrt( (cenx_new-cenx)^2 + (ceny_new-ceny)^2 )) ' pixels ']);
      end
      cenx = cenx_new; ceny = ceny_new;
    end
  end
end
framesWithCellsMoving = unique(framesWithCellsMoving);

% Find cells growing < > p.pixelsLenDef pixels
framesWithCellsGrowingTooLittle = [];
framesWithCellsGrowingTooMuch = [];
for cell = 1:length(schnitzcells)
  schnitzcells(cell).growingTooLittle = [];
  schnitzcells(cell).growingTooMuch = [];
  len = schnitzcells(cell).len(1);
  for i = 2:length(schnitzcells(cell).frame_nrs);
    if schnitzcells(cell).inTracking % last frame should be taken in account (MW 2014/06/11)
      len_new = schnitzcells(cell).len(i);
      if (len_new-len) < p.pixelsLenDef(1)
        schnitzcells(cell).growingTooLittle = [schnitzcells(cell).growingTooLittle schnitzcells(cell).frame_nrs(i-1)]; % here -1 also required, MW 2014/06/11
        framesWithCellsGrowingTooLittle = [framesWithCellsGrowingTooLittle schnitzcells(cell).frame_nrs(i-1)];
        problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(i-1)];
      elseif (len_new-len) > p.pixelsLenDef(2) 
        schnitzcells(cell).growingTooMuch = [schnitzcells(cell).growingTooMuch schnitzcells(cell).frame_nrs(i-1)];
        framesWithCellsGrowingTooMuch = [framesWithCellsGrowingTooMuch schnitzcells(cell).frame_nrs(i-1)];
        problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(i-1)];
      end
      len = len_new;
    end
  end
end
framesWithCellsGrowingTooLittle = unique(framesWithCellsGrowingTooLittle);
framesWithCellsGrowingTooMuch = unique(framesWithCellsGrowingTooMuch);
framesWithCellsGrowingWeird = unique([framesWithCellsGrowingTooLittle framesWithCellsGrowingTooMuch]);

% Find cells that change length more/less than 20 pixels after division and
% have area change larger than p.pixelsAreaDiv
framesWithCellsChangingAfterDivision = [];
for cell = 1:length(schnitzcells)
  schnitzcells(cell).offspringToBig = false;
  D = schnitzcells(cell).D;
  E = schnitzcells(cell).E;
  if schnitzcells(cell).inTracking & E>0 & D>0
    combined_length = schnitzcells(D).len(1) + schnitzcells(E).len(1);
    %length change
    if (schnitzcells(cell).len(end) >  20 + schnitzcells(D).len(1) + schnitzcells(E).len(1)) | ...
       (schnitzcells(cell).len(end) < -20 + schnitzcells(D).len(1) + schnitzcells(E).len(1))
        %area change (check only if schnitz contains this field -> not true for schnitz files older than 2013-12)
        if ~existfield(schnitzcells,'areapx')
            schnitzcells(cell).offspringToBig = true;
            framesWithCellsChangingAfterDivision = [framesWithCellsChangingAfterDivision schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
            problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
        else
            AreaChange=abs(schnitzcells(cell).areapx(end) -  ( schnitzcells(D).areapx(1) + schnitzcells(E).areapx(1)));
            if AreaChange>p.pixelsAreaDiv;
                schnitzcells(cell).offspringToBig = true;
                framesWithCellsChangingAfterDivision = [framesWithCellsChangingAfterDivision schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
                problemCells = [problemCells ; cell schnitzcells(cell).frame_nrs(end)]; % MW 2014/06/11 removal N+1 bug
                %disp(['Parent schnitz: ' num2str(cell) ' Frame '   num2str(schnitzcells(cell).frame_nrs(end)-1)])
            end
        end
    end
  end
end
framesWithCellsChangingAfterDivision = unique(framesWithCellsChangingAfterDivision);

% output of problem cells
problemCells = unique(problemCells, 'rows');
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% CHECKING OF TRACKING
%--------------------------------------------------------------------------
% get all framenumbers to write in which tracking step (e.g. 1->3 or
% 23->24) the problem occured
framesunique=unique([schnitzcells.frame_nrs]);
% The -1 below results in taking next frame and current frame as inspected
% frames, I think I solved this. (Variables are also more clearly named
% now.) - MW 2014/6/3
%framesunique=unique([schnitzcells.frame_nrs])-1;  %NW2013-12. Miraculeously, a shift of '-1' has to be introduced
                                               % TODO!

% Display nr of cells in lineage file______________________________________
dispAndWrite(fid, ['-------------------------------------------------']);
dispAndWrite(fid, ['Results:']);
dispAndWrite(fid, ['--- ' str3(length(schnitzcells)) ' cells in tracking file']);
dispAndWrite(fid, ['  | ']);
dispAndWrite(fid, ['  |--- ' str3(nrCellsInTracking) ' of these are in manualRange']);
dispAndWrite(fid, ['     | ']);

% Display cells that are in segmentation but not in tree___________________
dispAndWrite(fid, ['     |--- ' str3(sum(segAndTrackDoNotMatch)) ' frames lack cells in tracking, which are there in segmentation']);
for frameNum = p.manualRange
  if segAndTrackDoNotMatch(frameNum)
    dispAndWrite(fid, ['     |  |--- frame ' str3(frameNum) ' has ' str3(NrCellsInTrackingPerFrame(frameNum)) ' / ' str3(NrCellsPerFrame(frameNum)) ' cells in tracking / segmentation']);
    for cellnum = [1:NrCellsPerFrame(frameNum)]
      if ( findSchnitz(schnitzcells, frameNum, cellnum) == 0) % 2014/06/11 MW +1 fix // == 0: edit other numbering issue
        dispAndWrite(fid, ['     |     |--- cellno ' str3(cellnum) ' is missing in tracking']);
      end
    end
  end
end

% Display orphans (first frame always has orphans)_________________________
dispAndWrite(fid, ['     |  ']);
dispAndWrite(fid, ['     |--- ' str3(nrOrphansInManualRange) ' of cells are orphans']);
for cell = 1:length(schnitzcells)
  if schnitzcells(cell).inTracking & schnitzcells(cell).orphan & schnitzcells(cell).frame_nrs(1) > firstFrame % cells in first frame do not count % MW 2014/06/11 removal N+1 bug
    dispAndWrite(fid, ['     |  |--- schnitz ' str3(cell) ' is an orphan and appears in frame ' str3(schnitzcells(cell).frame_nrs(1))]); % MW 2014/06/11 removal N+1 bug
  end
end

% Display barren cells (cell lineage ends)_________________________________
dispAndWrite(fid, ['     |  ']);
% dispAndWrite(fid, ['     |--- ' str3(nrBarrenInManualRange) ' of barren cells in manualRange']);
dispAndWrite(fid, ['     |--- ' str3(length(framesWithBarrenCells)) ' frames have barren cells']);
if ~isempty(framesWithBarrenCells)
    for fr = framesWithBarrenCells
      out = ['     |  |--- in frame ' str3(fr) ' schnitz '];
      for cell = 1:length(schnitzcells)
        if schnitzcells(cell).inTracking & schnitzcells(cell).barren & intersect(fr, schnitzcells(cell).frame_nrs(end)) % MW 2014/06/11 removal N+1 bug
          out = [out str3(cell) ' '];
          %dispAndWrite(fid, ['     |  |--- schnitz ' str3(cell) ' is barren and disappears in frame ' str3(schnitzcells(cell).frame_nrs(end)-1)]);
        end
      end
      out = [out 'are barren'];
      dispAndWrite(fid, out);
    end
end

% Display moving cells (possibly wrong tracking)___________________________
dispAndWrite(fid, ['     |  ']);
dispAndWrite(fid, ['     |--- ' str3(length(framesWithCellsMoving)) ' frames have cells moving > ' num2str(p.pixelsMoveDef) ' pixels']);

% Only loop when frames w. suspicious cells were detected
if ~isempty(framesWithCellsMoving)
    
    % Loop over frames w. cells that seem to be moving (suspicious)    
    for fr = framesWithCellsMoving
               
     
      
      % output
      dispAndWrite(fid, ['     |  |--- in frame ' str3(fr) ' -> ' str3(fr+1)]); %NW2013-12 change display (fr)->(next fr)
      for cell = 1:length(schnitzcells)
          
          % Get the index that corresponds to the schnitz with the frame of
          % interest, and then also find the next schnitz 
          % edit MW 2014/6/3: cleaner code. renaming.      
          %next_fr_idx =  find(schnitzcells(cell).frame_nrs==(fr+1)); % take +1 frame as reference
          %current_fr_idx = next_fr_idx - 1;      
          % TODO (2014/6/3): not entirely clear to me why we want next frame as a
          % reference, and not like this:
          current_fr_idx = find(schnitzcells(cell).frame_nrs==(fr)); % MW 2014/06/11 let's do like this for now (TODO remove these comments.)
          next_fr_idx = current_fr_idx + 1;           
          
          if schnitzcells(cell).inTracking & intersect(fr, schnitzcells(cell).moving)                                   

              % get x,y locations of centers of schnitzes
              cenx = schnitzcells(cell).cenx_cent(current_fr_idx); % MW 2014/6/3 renaming
              ceny = schnitzcells(cell).ceny_cent(current_fr_idx);
              cenx_new = schnitzcells(cell).cenx_cent(next_fr_idx);
              ceny_new = schnitzcells(cell).ceny_cent(next_fr_idx);

              % Pythagoras
              distanceMoved = sqrt( (cenx_new-cenx)^2 + (ceny_new-ceny)^2 );
              dispAndWrite(fid, ['     |  |  |--- schnitz ' str3(cell) ' : ' num2str( round(distanceMoved) ) ' pixels']);

              % MW 2014/6/3 || bugfix 2014/06/24
              % missing frames might introduce extra movement, could tell user that
              if ((find(schnitzcells(cell).frame_nrs==next_fr_idx) - find(schnitzcells(cell).frame_nrs==current_fr_idx)) ~= 1)
                  dispAndWrite(fid, ['     |  |--- (but missing frame detected, this might be the cause.)' ]);    
              end
              
          end
          
      end
      
      dispAndWrite(fid, ['     |  |' ]);
    end
end

% Display weird growing cells (possibly wrong tracking / segmentation)_____
dispAndWrite(fid, ['     |  ']);
dispAndWrite(fid, ['     |--- ' str3(length(framesWithCellsGrowingWeird)) ' frames have cells growing < ' num2str(p.pixelsLenDef(1)) ' or > ' num2str(p.pixelsLenDef(2)) ' pixels']);
if ~isempty(framesWithCellsGrowingWeird)
    for fr = framesWithCellsGrowingWeird       
      
      % output
      dispAndWrite(fid, ['     |  |--- in frame ' str3(fr) ' -> ' str3(fr+1)]);
      for cell = 1:length(schnitzcells)
          
          % Get the index that corresponds to the schnitz with the frame of
          % interest, and then also find the next schnitz 
          % edit MW 2014/6/3: cleaner code. renaming.      
          %next_fr_idx =  find(schnitzcells(cell).frame_nrs==(fr+1)); % take +1 frame as reference
          %current_fr_idx = next_fr_idx - 1;      
          % TODO: not entirely clear to me why we want next frame as a
          % reference, and not like this:
          current_fr_idx = find(schnitzcells(cell).frame_nrs==(fr)); % MW 2014/06/11
          next_fr_idx = current_fr_idx + 1;  % MW 2014/06/11

          % get indices schnitzes that grow too fast/too little
          idx = [find(schnitzcells(cell).growingTooLittle==(fr))  find(schnitzcells(cell).growingTooMuch==(fr))];
        
          if schnitzcells(cell).inTracking & ~isempty(idx) % MW TODO 2014/6, probably this should be & ~isempty(idx)??
            lengthIncrease = schnitzcells(cell).len(next_fr_idx) - schnitzcells(cell).len(current_fr_idx);
            dispAndWrite(fid, ['     |  |  |--- schnitz ' str3(cell) ' : ' num2str( round(lengthIncrease) ) ' pixels']);

            % MW 2014/6/3 || bugfix 2014/06/24
            % missing frames might introduce extra movement, could tell user that
            if (find(schnitzcells(cell).frame_nrs==next_fr_idx)-find(schnitzcells(cell).frame_nrs==current_fr_idx) ~= 1)
                dispAndWrite(fid, ['     |  |--- (but missing frame detected, this might be the cause.)' ]);    
            end          
            
          end
          
      end
      
      dispAndWrite(fid, ['     |  |' ]);
    end
end

% Display moving whose length change after division (possibly wrong tracking)
dispAndWrite(fid, ['     |  ']);
dispAndWrite(fid, ['     |--- ' str3(length(framesWithCellsChangingAfterDivision)) ' frames have cells with length change <> 20 pixels after division']);
% loop over frames when there are frames that contain suspicious cells
if ~isempty(framesWithCellsChangingAfterDivision)
    for fr = framesWithCellsChangingAfterDivision
      
      % get next frame nr and current frame nr (edit MW 2014/6/3)
      next_fr_idx = find(framesunique==fr+1);
      current_fr_idx = next_fr_idx-1;
     
      % output
      dispAndWrite(fid, ['     |  |--- in frame ' str3(current_fr_idx) ' -> ' str3(next_fr_idx)]); 
      for cell = 1:length(schnitzcells)
          
        % determine whether this schnitz is suspicious
        if schnitzcells(cell).inTracking & schnitzcells(cell).offspringToBig & fr==schnitzcells(cell).frame_nrs(end) % MW 2014/06/11 removal N+1 bug

          % Obtain children
          D = schnitzcells(cell).D;
          E = schnitzcells(cell).E;

          % Calculate length increase
          lengthIncrease = schnitzcells(D).len(1) +  schnitzcells(E).len(1) - schnitzcells(cell).len(end);
          dispAndWrite(fid, ['        |  |--- parent schnitz ' str3(cell) ' : ' num2str( round(lengthIncrease) ) ' pixels']);
          
          % MW 2014/6/3 || bugfix 2014/6/24
          % missing frames might introduce extra movement, could tell user that
          if (find(schnitzcells(cell).frame_nrs==next_fr_idx)-find(schnitzcells(cell).frame_nrs==current_fr_idx) ~= 1)
              dispAndWrite(fid, ['     |  |--- (but missing frame detected, this might be the cause.)' ]);    
          end          
          
        end        
        
      end      
      
      dispAndWrite(fid, ['        |' ]);
    end
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% Close file to write results to
%--------------------------------------------------------------------------
dispAndWrite(fid, ['-------------------------------------------------']);
fclose(fid);
%--------------------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schnitzNum = findSchnitz(s,fr,cellnumber);
% Find schnitznumber associated with certain framenumber and cellnumber.
% Find schnitznumber that contains a certain cell (identified by its
% number cellno), in a certain frame (identified by its number fr).

% loop over schnitzes
for schnitzNum = [1:length(s)]
  % get schnitz
  schnitz = s(schnitzNum);
  
  % get idx corresponding to fr for schnitzarray
  index = find( [schnitz.frame_nrs] == fr);
  
  % check whether current schnitz is the cell we're looking for
  if schnitz.cellno(index) == cellnumber
    return;
  end
end

% schnitzNum = -1; % this makes no sense - MW 2014/06/11 (edit also with
% usage).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%








