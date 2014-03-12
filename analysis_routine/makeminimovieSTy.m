 function p = makeminimovieSTy(p,varargin) 
% MAKEMINIMOVIE creates a sub-movie within the given movie around clicked points
% just like the original makeminimovie but for -y- and -p-1- images
%  
%

%-------------------------------------------------------------------------------
% Parse the input arguments, input error checking
%-------------------------------------------------------------------------------

global ourfig origfig reducefig

origfig=2;
reducefig=3;

numRequiredArgs = 1;
if (nargin < 1) | ...
   (mod(nargin,2) == 0) | ...
   (~isSchnitzParamStruct(p))
  errorMessage = sprintf ('%s\n%s\n%s\n',...
      'Error using ==> makeminimovie:',...
      '    Invalid input arguments.',...
      '    Try "help makeminimovie".');
  error(errorMessage);
end

F=[];X=[];Y=[];

%-------------------------------------------------------------------------------
% Override any schnitzcells parameters/defaults given optional fields/values
%-------------------------------------------------------------------------------

% Loop over pairs of optional input arguments and save the given fields/values 
% to the schnitzcells parameter structure
numExtraArgs = nargin - numRequiredArgs;
if numExtraArgs > 0
  for i=1:2:(numExtraArgs-1)
    if (~isstr(varargin{i}))
      errorMessage = sprintf ('%s\n%s%s%s\n%s\n',...
          'Error using ==> absaugen:',...
          '    Invalid property ', num2str(varargin{i}), ...
          ' is not (needs to be) a string.',...
          '    Try "help absaugen".');
      error(errorMessage);
    end
    fieldName = schnitzfield(varargin{i});
    p.(fieldName) = varargin{i+1};
  end
end


if ~existfield(p,'miniMovieName')
  p.miniMovieName = [p.movieName,'-mini-01'];
end

if ~existfield(p,'winSizeX')
  p.winSizeX = 500;
end
if ~existfield(p,'winSizeY')
  p.winSizeY = 500;
end

if ~existfield(p,'numphaseslices')
  p.numphaseslices = 2;
end

% If explicit frame range not given, figure it out by determining which frames 
% exist (based on image file names)
imprefix = [p.movieName '-y-'];
D = dir([p.imageDir, imprefix, '*.tif']);
[S,I] = sort({D.name}');
D = D(I);
numpos= findstr(D(1).name, '.tif')-3;
if ~existfield(p,'miniRange')
  D = dir([p.imageDir, imprefix, '*.tif']);
  [S,I] = sort({D.name}');
  D = D(I);
  frameNumStrings = char(S);
  p.miniRange = str2num(frameNumStrings(:,numpos:numpos+2))';
end

% bgDir=[p.rootDir,'Background\bg2.tif'];
% BG=imread(bgDir);

% Internally, code is set up to use the mini frame range in descending order
sortedMiniRange = sort(p.miniRange); % in case they give it to us descending!
descendingMiniRange = sortedMiniRange(end:-1:1);
descendingMiniRange = p.miniRange; % ADD: do not sort SJT
descendingMiniRange;
p.miniRange;
i=1;
imax = length(descendingMiniRange);  % i = row index into frame info, NOT frame number!
% p.numphaseslices = 2; %%%%%%%%%%%ADD SJT
% for frame=descendingMiniRange
while i<=imax
    frame=descendingMiniRange(i);
    if p.numphaseslices == 1
        imp = imread([p.imageDir,p.movieName,'-p-',str3(frame),'.tif']);
    else
        % assumes phase image 2 is the one to extract from!
        imp = imread([p.imageDir,p.movieName,'-p-1-',str3(frame),'.tif']);
    end
    imy = imread([p.imageDir,p.movieName,'-y-',str3(frame),'.tif']);
%     imy = imy + 600 - BG;
%    imp = imresize(imp,0.5);
%     iptsetpref('ImshowAxesVisible','on','ImshowBorder','loose' );

    figure(origfig);
    imshow(makergb(imresize(imp,0.5),imy));
    set(origfig,'name',['Frame ',str3(frame),'   click=reduce, space=preserve']);
    iptsetpref('ImshowAxesVisible','on');
    iptsetpref('ImshowBorder','loose');
%     frame
    w = waitforbuttonpress; 
    if w == 0, 
        F(i) = frame;
        xy = 2*round(get(gca,'CurrentPoint'));
        X(i) = xy(1,1);
        Y(i) = xy(1,2);
%          [i frame X(i) Y(i)]
    
        sz = size(imp);
        x1(i) = round(max(1,X(i)-p.winSizeX/2));
        x2(i) = round(min(sz(2),X(i)+p.winSizeX/2))-1;
        y1(i) = round(max(1,Y(i)-p.winSizeY/2));
        y2(i) = round(min(sz(1),Y(i)+p.winSizeY/2))-1;
        newimp=imp(y1(i):y2(i),x1(i):x2(i));
%         [x1(i) x2(i) y1(i) y2(i)]

%         [p.winSizeX p.winSizeY]
        x1h(i)=round(0.5*x1(i));
        x2h(i)=round(0.5*x2(i))-1;
        y1h(i)=round(0.5*y1(i));
        y2h(i)=round(0.5*y2(i))-1;
        newimy=imy(y1h(i):y2h(i),x1h(i):x2h(i));  
        
         [frame x2h(i)-x1h(i) y2h(i)-y1h(i)]
        
        figure(reducefig);
        imshow(makergb(imresize(newimp,0.5),newimy));
        set(reducefig,'name',['Frame ',str3(frame),' space=accept, b=re-do']);
    end
    
    w = waitforbuttonpress;
    cc=get(origfig,'CurrentCharacter');
    if cc=='b'
        i=i-1;
    elseif cc=='v'
        i=i-2;
    end
    i = i + 1;

%     size(newimp)
%     size(newimy
    % keyboard;
    
%    count=count+1;

%     w
% %     cc=get(ourfig,'currentcharacter');
%     if w==0
%         subcolroi=imresize(~roipoly,2);
% %         if size(subcolroi,1)~=size(Lout,1) | size(subcolroi,2)~=size(Lout,2)
% %             subcolroi2=zeros(size(Lout));
% %             subcolroi2(1:size(subcolroi,1),1:size(subcolroi,2))=subcolroi;
% %             subcolroi=subcolroi2;
% %         end
% % keyboard;
%         newimp=(newimp.*uint16(~subcolroi));
%         imshow(makergb(imresize(newimp,0.5),newimy));
%         w = waitforbuttonpress; 
%     end
end

clickdata = [F' X' Y'];
frames = clickdata(:,1);
X = clickdata(:,2);
Y = clickdata(:,3);

save([p.imageDir,'clickdata'],'clickdata');


% create a new movie with only one phase slice
newp = initschnitz(p.miniMovieName,p.movieDate,p.movieKind,'rootDir',p.rootDir,'numphaseslices',1);

if p.numphaseslices == 1
    basepathPh = [p.imageDir,p.movieName,'-p-'];
    outpathPh = [newp.imageDir,newp.movieName,'-p-'];   
else
    % assumes phase image 2 is the one to extract from!  >> saves both
    % slices SJT
%     basepathPh = [p.imageDir,p.movieName,'-p-'];
%     outpathPh = [newp.imageDir,newp.movieName,'-p-'];   
    basepathPh = [p.imageDir,p.movieName,'-p-1-'];
    outpathPh = [newp.imageDir,newp.movieName,'-p-'];   
end
basepathFy = [p.imageDir,p.movieName,'-y-'];
outpathFy = [newp.imageDir,newp.movieName,'-y-'];
% frames
for i = 1:size(clickdata,1),
    
    % readname = [basepathPh,str3(frames(i)),'.tif']
    
    imp = imread([basepathPh,str3(frames(i)),'.tif']);
    impi = imfinfo([basepathPh,str3(frames(i)),'.tif']);
    imy = imread([basepathFy,str3(frames(i)),'.tif']);    
%     imy = imy + 600 - BG;
    imyi = imfinfo([basepathFy,str3(frames(i)),'.tif']);
    
    newimp=imp(y1(i):y2(i),x1(i):x2(i));
    newimy=imy(y1h(i):y2h(i),x1h(i):x2h(i));

    %pwin = imp(starty:stopy,startx:stopx);
    descrp=[impi.ImageDescription 'DateTime: ' impi.DateTime 'Software: ' impi.Software];
    descry=[imyi.ImageDescription 'DateTime: ' imyi.DateTime 'Software: ' imyi.Software];
    imwrite(newimp,[outpathPh,str3(frames(i)),'.tif'],'tif','Description',descrp);
    imwrite(newimy,[outpathFy,str3(frames(i)),'.tif'],'tif','Description',descry);
end;
close(origfig);
close(reducefig);