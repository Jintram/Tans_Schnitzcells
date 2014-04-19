

close all;

% See 
% http://www.mathworks.nl/help/images/ref/imopen.html
% For explanation of opening.

% Load image_______________________________________________________________
my_dir = 'D:\LocalPlayground\'
%img_name = 'pos1-p-1-002.tif'
img_name = 'pos1-p-3-101.tif'
output_name = ['SM' img_name]

%img_location = 'D:\LocalPlayground\Vincent_van_Gogh_(1853-1890)_-_Wheat_Field_with_Crows_(1890).jpg'
[original,my_colormap] = imread([my_dir img_name]);

figure (1), imshow(original,my_colormap);

% Let's modify the img a little bit
% create working copy
work_img = original;
work_img = double(work_img);
% normalize
work_img = work_img ./ max(work_img(:)); 
% invert black/white
work_img = 1 - work_img; 
% convert to black and white
work_img = im2bw(work_img);



% _________________________________________________________________________

figure (2), imshow(work_img);

% Create a disk-shaped structuring element with a radius of 5 pixels.

se = strel('disk',5);

% Remove snowflakes having a radius less than 5 pixels by opening it with the disk-shaped structuring element.

% "TOOLBOX"
%{
img_after = imopen(work_img,se);
img_after = imclose(work_img,se);
img_after = imbothat(work_img,se);
img_after = imtophat(work_img,se);

work_img = imdilate(work_img,se);
work_img = imerode(work_img,se);

work_img = bwareaopen(work_img, 500);
%}

% perform operations
work_img = bwareaopen(work_img, 500);
work_img = imopen(work_img,se);

% invert black/white back again
work_img = 1 - work_img; 

% put result in img_after and show_________________________________________

img_after = work_img;
figure (3), imshow(img_after);

%{
ff_img = fft(work_img);
figure (3), imshow(ff_img);
%}

% Write away result________________________________________________________

% Get old image metadata
im_info = imfinfo([my_dir img_name]);

% Note that this produces 'cropped' image style metadata
im_description = [im_info.ImageDescription 'DateTime: ' im_info.DateTime 'Software: ' im_info.Software];
imwrite(img_after,[my_dir output_name], 'tif', 'Compression', 'none', 'Description', im_description);

