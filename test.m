
tic; % Start timer.
clc; % Clear command window.
clearvars; % Get rid of variables from prior run of this m-file.
disp('Running BlobsDemo.m...'); % Message sent to command window.
workspace; % Make sure the workspace panel with all the variables is showing.
imtool close all;  % Close all imtool figures.
format longg;
format compact;
fontSize = 20;


% fileName='edit.tif'; % editlenmiş görüntü
% stacks = tiffRead(fullfile(file_path,'data',fileName),{'MONO'});
% grayImage = stacks.MONO; %read image

predictedFile = imread('C:\Users\Zişan\Desktop\test test imgs\Image16binary.png');
%binary = im2bw(predictedFile, 0.5);
bw = bwareaopen(predictedFile, 1200);

%uint8Image = uint8(255 * bw);
%bw = double(bw);

se = strel('disk', 2);
closeBW = imclose(bw,se);

D = -bwdist(~closeBW);
Ld = watershed(D);
bw2 = closeBW;
bw2(Ld == 0) = 0;
mask = imextendedmin(D,2);
D2 = imimposemin(D,mask);
Ld2 = watershed(D2);
bw3 = closeBW;
bw3(Ld2 == 0) = 0; %watershed img
binaryImage = imfill(bw3, 'holes');
fname = 'C:\Users\ilknu\OneDrive\Masaüstü\matlab-acc'; % kaydedileceği klasör pathi
filename = sprintf('NEBU.jpg'); % dosya ismi
imwrite(binaryImage, fullfile(fname, filename));
% Check that user has the Image Processing Toolbox installed.

	% Found it on the search path.  Construct the file name.
fullFileName = 'C:\Users\ilknu\OneDrive\Masaüstü\matlab-acc\NEBU.jpg'; % Note: don't prepend the folder.

% If we get here, we should have found the image file.
originalImage = imread(fullFileName);
% Check to make sure that it is grayscale.
[rows, columns, numberOfColorBands] = size(originalImage);
if numberOfColorBands > 1
	% Do the conversion using standard book formula
	originalImage = rgb2gray(originalImage);
end

% Threshold the image to binarize it
binaryImage = originalImage > 50;
% Do a "hole fill" to get rid of any background pixels inside the blobs.
binaryImage = imfill(binaryImage, 'holes');

% Display the binary image.
subplot(2, 3, 1);
imshow(binaryImage);
% Maximize the figure window.
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Force it to display RIGHT NOW (otherwise it might not display until it's all done, unless you've stopped at a breakpoint.)
drawnow;
caption = sprintf('Original binary image showing\nblobs of a variety of shapes.');
title(caption);
axis square; % Make sure image is not artificially stretched because of screen's aspect ratio.

labeledImage = bwlabel(binaryImage, 8);     % Label each blob so we can make measurements of it
coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle'); % pseudo random color labels


subplot(2, 3, 2);
imshow(coloredLabels);
caption = sprintf('Pseudo colored labels, from label2rgb().');
title(caption);

% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
blobMeasurements = regionprops(labeledImage, originalImage, 'all');
numberOfBlobs = size(blobMeasurements, 1);

% Extract out individual structure members into individual arrays.
allBlobAreas = [blobMeasurements.Area];
allBlobPerimeters = [blobMeasurements.Perimeter];
allBlobCircularities = allBlobPerimeters  .^ 2 ./ (4 * pi * allBlobAreas);
allBlobECD = [blobMeasurements.EquivDiameter];
allBlobSolidities = [blobMeasurements.Solidity];
allBlobEccentricities = [blobMeasurements.Eccentricity];
allBlobCentroids = [blobMeasurements.Centroid];
centroidsX = allBlobCentroids(1:2:end-1);
centroidsY = allBlobCentroids(2:2:end);

fontSize = 20;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blobECD = zeros(1, numberOfBlobs);
% Print header line in the command window.
fprintf(1,'Blob #     Area    Perimeter  Circularity (Centroid_X, Centroid_Y)   Diameter   Solidity   Eccentricity\n');
% Loop over all blobs printing their measurements to the command window.
for k = 1 : numberOfBlobs           % Loop through all blobs.
	blobCentroid = blobMeasurements(k).Centroid;		% Get centroid one at a time
	fprintf('#%2d %12.1f %9.1f %9.1f       (%5.1f, %5.1f) %17.1f %10.1f %13.1f\n', k, ...
		allBlobAreas(k), allBlobPerimeters(k), allBlobCircularities(k), ...
		blobCentroid(1), blobCentroid(2), allBlobECD(k),...
		allBlobSolidities(k), allBlobEccentricities(k));
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), ...
		num2str(k), 'Color', 'r', 'FontSize', fontSize, 'FontWeight', 'Bold');
end


allowableCircularityIndexes = (allBlobCircularities < 1.26); %orjinali 3tü
allowableSolidityIndexes = allBlobSolidities > 0.92; % Take the big objects.orjinali 0.8
logicalKeepersIndexes = allowableCircularityIndexes & allowableSolidityIndexes;
keeperIndexes = find(logicalKeepersIndexes);
keeperBlobsImage = ismember(labeledImage, keeperIndexes);
% Re-label with only the keeper blobs kept.
labeledImage = bwlabel(keeperBlobsImage, 8);     % Label each blob so we can make measurements of it


subplot(2, 3, 1);
hold on; % Don't blow away image.
for k = 1 : numberOfBlobs           % Loop through all keeper blobs.
	itsRound = logicalKeepersIndexes(k); % See if this blob is considered round.
	if itsRound
		% Plot round blobs with a green circle.
		plot(centroidsX(k), centroidsY(k), 'go', 'MarkerSize', 1, 'LineWidth', 1);
	else
		% Plot non-round blobs with a red x.
		plot(centroidsX(k), centroidsY(k), 'rx', 'MarkerSize', 20, 'LineWidth', 3);
	end
end


maskedImage = originalImage; % Simply a copy at first.
maskedImage(~keeperBlobsImage) = 0;  % Set all non-keeper pixels to zero.
subplot(2, 3, 3);
imshow(maskedImage);
imwrite(maskedImage, 'result11.jpg');
title('Only the round blobs from the original image');



A = (logical(imread('C:\Users\ilknu\OneDrive\Masaüstü\matlab-acc\result11.jpg')));
BW_groundTruth = (logical(imread("C:\Users\ilknu\OneDrive\Masaüstü\matlab-acc\maskimage11.tif")));
similarity = dice(A, BW_groundTruth);
figure
imshowpair(A, BW_groundTruth)
title(['Dice Index = ' num2str(similarity)])

