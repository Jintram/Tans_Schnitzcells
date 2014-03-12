% DJK_addToBranches_noise 
%
% Of each field except the timefield (dataFields(1)) a noise and norm
% version are added.
%
% noise: normalized by subtracting mean for this timepoint off all branches. 
%
% norm: normalized by subtracting the mean of the branch data for all timepoints.  
%
% OUTPUT
% 'branches'        cell structure with branches, with noise/norm added
%
% REQUIRED ARGUMENTS:
% 'branches'        cell structure with branches
%
% OPTIONAL ARGUMENTS:
% 'dataFields'        fields to be stored in branches
%                     default: {'Y_time' 'Y6_mean' 'mu_fitNew'}
%

function branches = DJK_addToBranches_noise(p, branches, varargin)

%--------------------------------------------------------------------------
% Input error checking
%--------------------------------------------------------------------------
% Settings
numRequiredArgs = 2; functionName = 'DJK_addToBranches_noise';

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
% If not provided, use standard dataFields
if ~existfield(p, 'dataFields')
  p.dataFields = {'Y_time' 'Y6_mean' 'mu_fitNew'};
end

for i = 1:length(p.dataFields)
  field = char(p.dataFields(i));
  if ~existfield(branches(1),field)
    disp(['Field ' field ' does not exist. Exiting...!']);
    return;
  end
end

% first dataField should contain time (timeField)
timeField = char(p.dataFields(1));

unique_timeField  = unique([branches.(timeField)]);
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
% GET MEAN FOR NOISE & NORM FIELDS
%--------------------------------------------------------------------------
datafield_sum = zeros(length(p.dataFields), length(unique_timeField));
datafield_count = zeros(length(p.dataFields), length(unique_timeField));

% loop over branches
for branchNr = 1:length(branches)
  for age = 1:length(branches(branchNr).schnitzNrs)
    idx  = find(unique_timeField  == branches(branchNr).(timeField)(age));
    for i = 1:length(p.dataFields)
      datafield_sum(i,idx) = datafield_sum(i,idx) + branches(branchNr).(char(p.dataFields(i)))(age) / branches(branchNr).count(age); % DJK 091125 last / used to be *, but I now think this is wrong
      datafield_count(i,idx) = datafield_count(i,idx) + 1/branches(branchNr).count(age); % DJK 091125 last + 1/ used to be + , but I now think this is wrong
    end
  end
end

datafield_mean = datafield_sum ./ datafield_count;

% loop over noiseFields in dataFields
for i = 2:length(p.dataFields)
  field = char(p.dataFields(i));
  noisefield = ['noise_' field];
  normfield  = ['norm_' field];

  % loop over branches
  for branchNr = 1:length(branches)
    % loop over data
    for age = 1:length(branches(branchNr).(field))
      idx  = find(unique_timeField  == branches(branchNr).(timeField)(age));
      branches(branchNr).(noisefield)(age) = branches(branchNr).(field)(age) - datafield_mean(i,idx);
      branches(branchNr).(normfield)(age) = branches(branchNr).(field)(age) - mean(datafield_mean(i,:));
    end
  end
end
%--------------------------------------------------------------------------
