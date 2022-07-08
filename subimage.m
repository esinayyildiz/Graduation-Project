clc;
close all;
clear;
workspace;
format long g;
format compact;
fontSize = 20;
file_path=pwd;

fileName='edit.tif'; % editlenmiş görüntü
stacks = tiffRead(fullfile(file_path,'data',fileName),{'MONO'});
grayImage = stacks.MONO; %read image

fileName='aksotomi sonrasi yakindakiler soluyor_uzaktakiler parliyor_b0v0t0z0c1x0-1024y0-1024-bf.tif'; % brightfield görüntü
stacks = tiffRead(fullfile(file_path,'data',fileName),{'MONO'});
bfImage = stacks.MONO; %read image

fileName='untitled.tif'; % floresan görüntü/ label
stacks = tiffRead(fullfile(file_path,'data',fileName),{'MONO'});
flImage = stacks.MONO; %read image

[rows, columns, numberOfColorBands] = size(grayImage)
if numberOfColorBands > 1
  grayImage = grayImage(:, :, 2);
end
[rows, columns, numberOfColorBands] = size(bfImage)
if numberOfColorBands > 1
  bfImage = bfImage(:, :, 2);
end
[rows, columns, numberOfColorBands] = size(flImage)
if numberOfColorBands > 1
  flImage = flImage(:, :, 2);
end

meanIntensity = mean(bfImage(:));

mean1(1:rows, 1:128) = meanIntensity;
mean2(1:128, 1:(columns+128)) = meanIntensity;
mean3(1:(rows+256), 1:128) = meanIntensity;

zeros1 = zeros(rows, 128);
zeros2 = zeros(128, columns+128);
zeros3 = zeros(rows+256,128);

grayImage = [zeros1 grayImage];
grayImage = [zeros2; grayImage];
grayImage = [grayImage; zeros2];
grayImage = [grayImage zeros3];

bfImage = [mean1 bfImage];
bfImage = [mean2; bfImage];
bfImage = [bfImage; mean2];
bfImage = [bfImage mean3];

flImage = [zeros1 flImage];
flImage = [zeros2; flImage];
flImage = [flImage; zeros2];
flImage = [flImage zeros3];

%subplot(2, 1, 1);
% imshow(grayImage, []);

% title('Preprocessed Brightfield Image', 'FontSize', fontSize, 'Interpreter', 'None');
% set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% set(gcf, 'Toolbar', 'none', 'Menu', 'none');
% set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off') 
binaryImage = grayImage > 200;
binaryImage = imclearborder(binaryImage);
binaryImage = bwareaopen(binaryImage, 100); %removes all connected components (objects) that have fewer than P pixels from the binary image BW, producing another binary image, BW2. This operation is known as an area opening.
%subplot(2, 1, 2);
figure; imshow(bfImage, []);
figure; imshow(flImage, []);
% title('Binary Image with Centroids', 'FontSize', fontSize, 'Interpreter', 'None');
labeledImage = bwlabel(binaryImage, 8);
blobMeasurements = regionprops(labeledImage, 'Centroid');
numberOfBlobs = size(blobMeasurements, 1);
hold on;

for k = 1 : length(blobMeasurements)
  x = blobMeasurements(k).Centroid(1);
  y = blobMeasurements(k).Centroid(2);
  plot(x, y, 'ys', 'MarkerSize', 60, 'LineWidth', 1);
hold on;

%Determine starting and ending rows and columns.
row1 = floor(y - 64);
col1 = floor(x - 64);
% Extract sub-image using imcrop():
subImage = imcrop(flImage, [col1, row1, 127, 127]);

%  figure;
%  imshow(subImage,[]);
 fname = 'C:\Users\Zişan\Desktop\SomaExtraction-master\SomaExtraction-master\data'; % sub path
 filename = sprintf('%d.tif', k); % dosya ismi
 imwrite(subImage, fullfile(fname, filename));
%   figure;

 
%   str = sprintf('The centroid of shape %d is at (%.2f, %.2f)', ...
%     k, x, y);
%   uiwait(helpdlg(str));


end

