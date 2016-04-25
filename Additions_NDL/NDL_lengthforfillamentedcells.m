

function [p, allLengthsOfBacteriaInPixels, allLengthsOfBacteriaInMicrons] = NDL_lengthforfillamentedcells(p, frameRange) 
%function [p,schnitzcells] = NDL_lengthforfillamentedcells(p) 
% 
% Function written by Nick de Lange and Martijn Wehrens.
% 2016/04
% 
% This function calculates length for bacteria using skeletons. This is
% useful when bacteria are very "curly" and fitting a curve to their shape
% does not yield succesfull results.
%
% Additionally, if p.generateStraigthenedBacteria is set, also images of
% straigthened bacteria will be generated using the function
% MW_straightenbacteria. (Note that his function outputs two paramters, the
% straigthened bacteria, and the length progression along the skeleton,
% since the transformation does not preserve equidistance of pixels 
% within the bacteria.)
%
% Input arguments:
% p.extraOutput    if this parameter is set, extra output will be shown in
%                   plots and in command window.
%
% Output arguments:
%     % lengths
%     allLengthsOfBacteriaInPixels{framenr}(cellnum)
%     allLengthsOfBacteriaInMicrons{framenr}(cellnum)
%     
%     % Skeleton, area, additional data
%     allPixelAreaOfBacterium{framenr}(cellnum) 
%     allSkeletonXYpoleToPole{framenr}(cellnum) 
%     allMinX{framenr}(cellnum)
%     allMinY{framenr}(cellnum) 
%     allarray2{framenr}{cellnum}
%     alldistanceAlongSkeleton{framenr}{cellnum}
%     allextrapolatedDistanceEnds{framenr}(:,cellnum)
%
% Test easily with following command:
% >> NDL_lengthforfillamentedcells(p, settings.frameRangeFull) 
%
%

% function parameters set by user
AVERAGEBACTERIAWIDTH = .5;
EXTRAPOLATIONLENGTH = 30;

% parameters calculated based on user-supplied parameters
averageBacterialWidthInPixel= AVERAGEBACTERIAWIDTH/p.micronsPerPixel;
paddingsize = round(averageBacterialWidthInPixel*4);
extrapolationLength=round(averageBacterialWidthInPixel);

if isfield(p,'extraOutput')
    extraOutput = p.extraOutput;
else
    extraOutput = 0;
end

% if isfield(p,'extraoutput')
%     % Plot with outline of all bacteria and extended skeletons
%     plot() 
%     saveas([p.analysisDir '/lengthNick/' num2str(frame) num2str(cellno) '.tif'])
% end

%% Loop over frames of this dataset
% Prepare output parameters.
lastFrame = frameRange(end);
% lengths
allLengthsOfBacteriaInPixels    = cell(1,lastFrame);
allLengthsOfBacteriaInMicrons   = cell(1,lastFrame);
% Skeleton, area, additional data
allPixelAreaOfBacterium         = cell(1,lastFrame);    
allSkeletonXYpoleToPole         = cell(1,lastFrame);
allMinX                         = cell(1,lastFrame);
allMinY                         = cell(1,lastFrame);
allarray2                       = cell(1,lastFrame);
alldistanceAlongSkeletonPixels        = cell(1,lastFrame);
allextrapolatedDistanceEndsPixels  = cell(1,lastFrame);
allextrapolatedDistanceEndsMicrons = cell(1,lastFrame);

for framenr = frameRange
    
    disp(['Analyzing frame ' num2str(framenr) ' (highest framenr =' num2str(lastFrame) ').']);

    %% % Load data for current frame of the dataset
    %e.g. load 'G:\EXPERIMENTAL_DATA_2016\a_incoming\2016-03-23\pos4crop\segmentation\pos4cropseg337.mat'
    load ([p.segmentationDir p.movieName 'seg' sprintf('%03d',framenr) '.mat']);
        % Important contents are Lc and Xreg, which respectively hold the
        % checked segmentation, and the fluorescence image, 
    
    %% Loop over all cell numbers in this frame
    
    % get unique cellnos
    nonZeroIndices = (Lc(:)>0);
    allCellnos = transpose(unique(Lc(nonZeroIndices)));
    % prepare output parameters for this frame
    lengthOfBacteriaInPixelsInThisFrame = NaN(1,numel(allCellnos));
    lengthOfBacteriaInMicronsInThisFrame = NaN(1,numel(allCellnos));    
    pixelAreaOfBacteriumInThisFrame =  NaN(1,numel(allCellnos));
    skeletonXYpoleToPoleInThisFrame = cell(1,numel(allCellnos));
    minXThisFrame = NaN(1,numel(allCellnos));
    minYThisFrame = NaN(1,numel(allCellnos));
    array2ThisFrame = cell(1,numel(allCellnos));
    distanceAlongSkeletonPixelsThisFrame = cell(1,numel(allCellnos));
    extrapolatedDistancePixelsEndsThisFrame = NaN(2,numel(allCellnos)); 
    extrapolatedDistanceMicronsEndsThisFrame = NaN(2,numel(allCellnos)); 
    % loop
    for cellnum = allCellnos
            
        
        %% Convert one cell to x,y coordinates.        
        [y,x] = find(Lc == cellnum);
        
        if extraOutput
            % show original
            figure(1); clf; 
            imshow(Lc,[]);            
            
            % show conversion
            figure(2); clf;
            axis equal;
            plot(x,y,'.');
        end
        
        
        
        %% % Select ROI and make image binary
        
        % administration required to select ROI 
        minY = min(y);
        minX = min(x);
        sizeY = max(y)-minY+1;
        sizeX = max(x)-minX+1;

        % create zero array size of bacterium
        zer=zeros(sizeY,sizeX);

        % use x,y coordinates to fill it
        for framen=1:length(x)
            zer(y(framen)-minY+1,x(framen)-minX+1)=1;
        end

        bin_im=zer;

        % % add padding to image (to avoid filters "seeing" edges)
        % bin_im=padarray(bin_im,[paddingsize,paddingsize]);

        if extraOutput
            figure(3);
            imshow(bin_im);
        end
        
        % calculate total area of bacterium
        pixelAreaOfBacterium = sum(bin_im(:));
        

        %% % Skeletonizes image
        BW = bwmorph(bin_im,'skel',Inf);
        %BW = voronoiSkel(bin_im); % downloaded this, but to tricky to get to work
        %BW = skeleton(bin_im); % downloaded this, but to tricky to get to work

        if extraOutput
            figure(4); clf;
            imshow(BW)
            imshow((bin_im+BW)/2,[])
        end
        
        %% % Finds edges
        edges = bin_im-bwmorph(bin_im,'erode');
        
        if extraOutput
            figure(); clf;
            imshow(edges+BW)
        end
        
        %% % Finds endings
        ends_before = bwmorph(BW,'endpoints');
        
        if extraOutput
            figure(50); clf;
            imshow(ends_before)
        end
        
        %% % Calculate number of ends
        num_ends_before=sum(sum(ends_before,2));
        
        %% Finds x & y values of endings before removing branches
        
        k=1;        
        xyends_before=zeros(1,2,num_ends_before);
        for framen=1:sizeX
            for j=1:sizeY
                if ends_before(j,framen)==1
                    xyends_before(:,:,k)=[j,framen];
                    k=k+1;
                end
            end
        end
        
        if extraOutput
            num_ends_before
            xyends_before
        end
        
        %% % Disconnects at branch points
        disc = BW-bwmorph(BW,'branchpoints');
        
        if extraOutput
            figure(); clf;
            imshow(disc);
        end
        
        %% % XXX
        [xx,yy]=find(BW==1);
        
        func=csaps(xx,yy);
        extrapolatedSpline1=fnxtr(func);
        
        if extraOutput
            extrapolatedSpline1
            plot(xx,yy,'.')
            figure()
            fnplt(extrapolatedSpline1)
        end
               
        % BWfit=fit(xx,yy,'poly9')
        % plot(BWfit)
        % BWspline=spline(xx,yy)
        
        %% % Removes side-branches
        % Main idea is to trim branhes until only two end-points are left
        % such that there's a branchless skeleton (i.e. the main branch).
        count=0;
        num_ends=num_ends_before;
        
        % make all pixels at the edge 0, as this otherwise can lead to
        % issues with detecting branches that are at the edge.
        BW(1,:)   = 0;
        BW(end,:) = 0;
        BW(:,1)   = 0;
        BW(:,end) = 0;
        
        % Continue removing spur pixels until we have branchless skeleton
        while num_ends>2
                BW = bwmorph(BW,'spur');                
                BW = bwmorph(BW,'skel'); % To prevent issue with 4-way crossings
                count=count+1;
                ends = bwmorph(BW,'endpoints');
                num_ends=sum(sum(ends,2));
                if count>1000
                    figure(); imshow(BW,[]);
                    error(['Error spurring, cellnum=' num2str(cellnum) ', showing current skeleton.']);                    
                end;
        end
        BW1=BW;
        
        if extraOutput
            count
            num_ends
        end
        %% % Finds endings
        ends = bwmorph(BW1,'endpoints');
        
        if extraOutput
            figure(51); clf;
            imshow(ends)
        end
        
        %% Finds x & y values of endings after removing branches
        
        l=1;
        xyends=zeros(1,2,num_ends);
        for framen=1:sizeX
            for j=1:sizeY
                if ends(j,framen)==1
                    xyends(:,:,l)=[j,framen];
                    l=l+1;
                end
            end
        end
        
        if extraOutput
            xyends
        end
        %% Gets x & y values of the branchless skeleton, and sets them in an array

        % Get "boundaries" of the line (result should make a loop around the line,
        % but from an arbitrary point)
        skeletonBoundary=bwboundaries(BW1,8); 
        skeletonBoundary=skeletonBoundary{1,1};

        % paste this loop 2x behind itself
        twotimesskeletonBoundary = [skeletonBoundary; skeletonBoundary];
        leftend = xyends(:,:,1);

        % Now find one of the bacterial poles
        poleIndex = find(skeletonBoundary(:,1)==leftend(1) & skeletonBoundary(:,2)==leftend(2));

        % Now get skeletonXYpoleToPole(i,:)=v(i), with v(i,:)=[x(i),y(i)],
        % point i along the skeleton
        skeletonXYpoleToPole=twotimesskeletonBoundary(poleIndex:poleIndex+round((size(skeletonBoundary,1)+1)/2),:);

        % for i=1:sizeX
        %     for i=1:sizeY
        %         
        % if ends==1
        %     xends=
        if extraOutput
            figure(5); clf;
            imshow((BW1+bin_im)/2)
        end
        
        %% % Gets x & y values of the segmented edges, and plots them
        edges2=bwboundaries(edges,8);
        array2=edges2{1,1};
        
        if extraOutput
            figure(71)
            plot(array2(:,1),array2(:,2))
            hold on
            plot(skeletonXYpoleToPole(:,1),skeletonXYpoleToPole(:,2))
        end
        %% % Sets length of dataset (coming from branchless skeleton) which gets extrapolated
        % extra_length=30;
        % if length(array)<extra_length
        %     extra_length=length(array)
        % end
        extrapolationLength = min(EXTRAPOLATIONLENGTH, length(skeletonXYpoleToPole));
        % vq3 = interp1(array(1:20,1),array(1:20,2),'pchip');
        % bla=bspline(array(1:50,1),array(1:50,2));
        %% % Extrapolates start of the bacteria
        %try
        func=csaps(skeletonXYpoleToPole(1:extrapolationLength,1),skeletonXYpoleToPole(1:extrapolationLength,2)); % TODO MAYBE USE OTHER (POLY)FIT?
        extrapolatedSpline1=fnxtr(func,2);

        extrapolatedSkeleton1 = fnplt(extrapolatedSpline1,[skeletonXYpoleToPole(1,1)-(count+extrapolationLength) skeletonXYpoleToPole(1,1)+(count+extrapolationLength)]).';
        %catch
        %    cellnum
        %    figure(); imshow(bin_im+BW,[]);
        %    skeletonXYpoleToPole
        %end 
        
        if extraOutput
            extrapolatedSkeleton1
            figure()            
            fnplt(extrapolatedSpline1,[skeletonXYpoleToPole(1,1)-(count+extrapolationLength) skeletonXYpoleToPole(1,1)+(count+extrapolationLength)])
        end
        %% % Extrapolates end of the bacteria
        func2=csaps(skeletonXYpoleToPole(length(skeletonXYpoleToPole)-(extrapolationLength-1):length(skeletonXYpoleToPole),1),skeletonXYpoleToPole(length(skeletonXYpoleToPole)-(extrapolationLength-1):length(skeletonXYpoleToPole),2));
        extrapolatedSpline2=fnxtr(func2);
        
        extrapolatedSkeleton2 = fnplt(extrapolatedSpline2,[skeletonXYpoleToPole(length(skeletonXYpoleToPole),1)-(count+extrapolationLength) skeletonXYpoleToPole(length(skeletonXYpoleToPole),1)+(count+extrapolationLength)]).';
        
        if extraOutput
            extrapolatedSkeleton2
            figure()            
            fnplt(extrapolatedSpline2,[skeletonXYpoleToPole(length(skeletonXYpoleToPole),1)-(count+extrapolationLength) skeletonXYpoleToPole(length(skeletonXYpoleToPole),1)+(count+extrapolationLength)])
        end
        %% % Plot extrapolations and segmented edges
        if extraOutput
            figure(72)
            plot(array2(:,1),array2(:,2))
            hold on
            plot(extrapolatedSkeleton1(:,1),extrapolatedSkeleton1(:,2))
            hold on
            plot(extrapolatedSkeleton2(:,1),extrapolatedSkeleton2(:,2))
            hold on
            plot(skeletonXYpoleToPole(:,1),skeletonXYpoleToPole(:,2))
        end
        %% % Determine intersection point and with that the correction length for one end
        
        disx=zeros(length(extrapolatedSkeleton1),length(array2));
        disy=zeros(length(extrapolatedSkeleton1),length(array2));
        distot=zeros(length(extrapolatedSkeleton1),length(array2));
        
        for framen=1:length(extrapolatedSkeleton1)
            for j=1:length(array2)
                disx(framen,j)=abs(array2(j,1)-extrapolatedSkeleton1(framen,1));
                disy(framen,j)=abs(array2(j,2)-extrapolatedSkeleton1(framen,2));
                distot(framen,j)=disx(framen,j)+disy(framen,j);
            end
        end        
        mini=min(min(distot));
        
        for framen=1:length(extrapolatedSkeleton1)
            for j=1:length(array2)
                if distot(framen,j)==mini
                    icor=framen;
                    jcor=j;
                end
            end
        end
        
        extrapolated_intersection=extrapolatedSkeleton1(icor,:);
        
        % determine extra length at start of bacterium
        % determine distance to both end from intersection
        extra_dist11=pdist2(extrapolated_intersection,xyends(1,:,1));
        extra_dist12=pdist2(extrapolated_intersection,xyends(1,:,num_ends));
        % take smallest as distance intersect to skeleton
        extra_dist1=min([extra_dist11 extra_dist12]);
        
        if extraOutput
            extrapolated_intersection
            mini
            array2(jcor,:)            
            xyends(1,:,1)
            extra_dist1            
        end
        
        %% % Determine other intersection point and with that the correction length for the other end
        disx2=zeros(length(extrapolatedSkeleton2),length(array2));
        disy2=zeros(length(extrapolatedSkeleton2),length(array2));
        distot2=zeros(length(extrapolatedSkeleton2),length(array2));
        
        for framen=1:length(extrapolatedSkeleton2)
            for j=1:length(array2)
                disx2(framen,j)=abs(array2(j,1)-extrapolatedSkeleton2(framen,1));
                disy2(framen,j)=abs(array2(j,2)-extrapolatedSkeleton2(framen,2));
                distot2(framen,j)=disx2(framen,j)+disy2(framen,j);
            end
        end        
        mini2=min(min(distot2));
        
        for framen=1:length(extrapolatedSkeleton2)
            for j=1:length(array2)
                if distot2(framen,j)==mini2
                    icor2=framen;
                    jcor2=j;
                end
            end
        end
           
        extrapolated_intersection2 = extrapolatedSkeleton2(icor2,:);
        
        % determine extra length at end of bacterium
        extra_dist21    = pdist2(extrapolated_intersection2,xyends(1,:,1));
        extra_dist22    = pdist2(extrapolated_intersection2,xyends(1,:,num_ends));
        extra_dist2     = min([extra_dist21 extra_dist22]);
                
        if extraOutput
            mini2
            array2(jcor2,:)            
            xyends(1,:,num_ends)
            extra_dist2
            extrapolated_intersection2
        end
        
        %% Calculates length of branchless skeleton, and the total estimated length (by adding the extrapolated lengths of the ends)
        
        distance_mask=ends;
        extract_end=xyends(1,:,1);
        distance_mask(extract_end(1),extract_end(2))=0;
        D=bwdistgeodesic(BW1,distance_mask,'quasi-euclidean');
        
        % determine distance along skeleton
        distanceAlongSkeletonPixels = D(sub2ind(size(D),skeletonXYpoleToPole(:,1),skeletonXYpoleToPole(:,2)));
        
        dist_BW1=max(max(D));
        if extraOutput
            dist_BW1
        end
        
        % export length data 
        lengthOfBacteriaInPixelsInThisFrame(cellnum)  = dist_BW1+extra_dist1+extra_dist2;
        lengthOfBacteriaInMicronsInThisFrame(cellnum) = lengthOfBacteriaInPixelsInThisFrame(cellnum)*p.micronsPerPixel;
        
        % export additional data
        pixelAreaOfBacteriumInThisFrame(cellnum) = pixelAreaOfBacterium;
        skeletonXYpoleToPoleInThisFrame{cellnum} = skeletonXYpoleToPole;
        minXThisFrame(cellnum) = minX;
        minYThisFrame(cellnum) = minY;
        array2ThisFrame{cellnum} = array2;
        distanceAlongSkeletonPixelsThisFrame{cellnum} = distanceAlongSkeletonPixels;
        extrapolatedDistancePixelsEndsThisFrame(:,cellnum) = [extra_dist1 extra_dist2];
        extrapolatedDistanceMicronsEndsThisFrame(:,cellnum) = [extra_dist1 extra_dist2]*p.micronsPerPixel;
    end
        
    % lengths
    allLengthsOfBacteriaInPixels{framenr} = lengthOfBacteriaInPixelsInThisFrame;
    allLengthsOfBacteriaInMicrons{framenr} = lengthOfBacteriaInMicronsInThisFrame;
    
    % Skeleton, area, additional data
    allPixelAreaOfBacterium{framenr} = pixelAreaOfBacteriumInThisFrame;    
    allSkeletonXYpoleToPole{framenr} = skeletonXYpoleToPoleInThisFrame;
    allMinX{framenr} = minXThisFrame;
    allMinY{framenr} = minYThisFrame;
    allarray2{framenr} = array2ThisFrame;
    alldistanceAlongSkeletonPixels{framenr} = distanceAlongSkeletonPixelsThisFrame;
    allextrapolatedDistanceEndsPixels{framenr} = extrapolatedDistancePixelsEndsThisFrame;
    allextrapolatedDistanceEndsMicrons{framenr} = extrapolatedDistanceMicronsEndsThisFrame;
    
    save([p.tracksDir p.movieName '-skeletonData.mat'],...
        'allLengthsOfBacteriaInPixels','allLengthsOfBacteriaInMicrons',...
        'allPixelAreaOfBacterium','allSkeletonXYpoleToPole',...
        'allMinX','allMinY',...
        'allarray2','alldistanceAlongSkeletonPixels',...
        'allextrapolatedDistanceEndsPixels','allextrapolatedDistanceEndsMicrons');
    
end


%{ 
%% Old code

% int2=zeros(1,length(points));
% for i=1:length(points)
%     int2(1,i)=min(disx(i,:))+min(disy(i,:));
% end
% int2;
% %
% Alternative script to get rid of side-branches
% skel= bwmorph(bin_im,'skel',Inf);
% skel = testBacterium>0;
% 
% B = bwmorph(skel, 'branchpoints');
% E = bwmorph(skel, 'endpoints');
% 
% [y,x] = find(E);
% B_loc = find(B);
% 
% Dmask = false(size(skel));
% for k = 1:numel(x)
%     D = bwdistgeodesic(skel,x(k),y(k));
%     distanceToBranchPt = min(D(B_loc));
%     Dmask(D < distanceToBranchPt) =true;
% end
% skelD = skel - Dmask;
% figure(60); clf;
% imshow(skelD);
% hold all;
% [y,x] = find(B); plot(x,y,'ro')
% leng=sum(sum(skel,2))

%% Plot the total skeleton on top of the bacterium
%}

%{
% %% smooth using circular neighborhood
        % % Seems to make it a little better for my cells
        % SCALING = 1; % scaling is not so useful actually, 1 means no scaling is applied
        % 
        % work_img = bin_im;
        % 
        % % rescaling, maybe higher resolution better?
        % work_img = imresize(work_img,SCALING,'nearest');
        % 
        % % set circular neighborhood
        % % note that the size of the disk is pretty critical, and due to the size 
        % % of the bacterium is too small to have an actual effect
        % sizeOfDisk=round(averageBacterialWidthInPixel)*.5*SCALING;
        % se=strel('disk',sizeOfDisk);
        % 
        % % apply filters
        % %work_img = imerode(work_img,se);
        % %work_img = imdilate(work_img,se);
        % work_img = imclose(work_img,se); % works best
        % 
        % % show results
        % figure(); 
        % subplot(1,2,1);
        % imshow(bin_im);
        % subplot(1,2,2)
        % imshow(work_img);
        % 
        % if 0 % to turn on/off this filter
        %     bin_im = work_img;
        % end
%}