clear all;
close all;
clc;

% Load a grayscale image from a PNG file
Image_Noisy = imread('test_image.png');
if size(Image_Noisy, 3) == 3 % Checking if image is RGB
    Image_Noisy = rgb2gray(Image_Noisy); % Converting to grayscale if RGB
end
Image_Double = double(Image_Noisy)/255; % Converting to double and normalizing to the range [0,1]

lambda = 0.02; % Setting regularization parameter
iterations = 5; % Setting number of iterations

% Defining Tikhonov function
function output = tikhonov2D(input, lambda)
    % Initialize output image
    output = input;
    [rows, cols] = size(input);
    % Using nested loops to iterate through each pixel and adjusting the
    % value based on the neighboring pixels: 
    for i = 2:rows-1 % Excluding borders in rows
        for j = 2:cols-1 % Excluding borders in columns
            % Calculating differences between current pixel and neighbors
            diff_up = input(i-1, j) - input(i, j);
            diff_down = input(i+1, j) - input(i, j);
            diff_left = input(i, j-1) - input(i, j);
            diff_right = input(i, j+1) - input(i, j);
            % Updating the output pixel value
            output(i, j) = input(i, j) + lambda * (diff_up + diff_down + diff_left + diff_right);
        end
    end
end

% Storing intermediate images as a cell array
Intermediates = cell(1, 4);
Intermediates{1} = Image_Double; % Start with the original image for the first direction

% Processing the image sequentially in different directions
for iter = 1:iterations
    % Each step starts from the result of the previous step
    Intermediates{1} = tikhonov2D(Intermediates{1}, lambda); % Top to Bottom
    Intermediates{2} = fliplr(tikhonov2D(fliplr(Intermediates{1}), lambda)); % Right to Left
    Intermediates{3} = flipud(tikhonov2D(flipud(Intermediates{2}), lambda)); % Bottom to Top
    Intermediates{4} = tikhonov2D(fliplr(Intermediates{3}), lambda) ; % Left to Right
end

% Converting images back to 8-bit integers for display
Intermediates_uint8 = cellfun(@(x) uint8(x * 255), Intermediates, 'UniformOutput', false);

% Displaying the original and processed images
subplot(3, 2, 1);
imshow(Image_Noisy);
title('Original Image');
subplot(3, 2, 2);
imshow(Intermediates_uint8{1});
title('Top to Bottom');
subplot(3, 2, 3);
imshow(Intermediates_uint8{2});
title('Right to Left');
subplot(3, 2, 4);
imshow(Intermediates_uint8{3});
title('Bottom to Top');
subplot(3, 2, 5);
imshow(Intermediates_uint8{4});
title('Left to Right');
