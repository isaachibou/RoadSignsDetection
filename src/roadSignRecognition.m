function [roadsigns] = roadSignRecognition( filepath, sensCircle, propsSquare, useEq )
    %% ROAD SIGN RECOGNITION
    % Application aiming at recognizing road signs on french roads.

    %% Initialization
    % Image reading
    roadsignImage = imread(filepath);

    % Declaration of detected roadsign structure
    roadsigns = struct('image', {}, 'shape', {}, 'color1', {}, 'color2', {}, 'id', {});

    % Learning phase
    % -- Defines the number of zone dividing the image
    % -- width
    m = 6;
    % -- height
    n = 6;
    % -- Learning
    d = 10;
    
    if ~exist('learningDensities_circular.mat', 'file')
        learningDensities_circular = learningPhase(m, n, 'circular');
    else
        learningDensities_circular = load('learningDensities_circular.mat', '-ascii');
    end
    
    if ~exist('learningProfiles_triangular.mat', 'file')
        learningProfiles_triangular = learningProfiles(d);
    else
        learningProfiles_triangular = load('learningProfiles_triangular.mat', '-ascii');
    end
    
    if ~exist('learningDensities_square.mat', 'file')
        learningDensities_square = learningPhase(m, n, 'square');
    else
        learningDensities_square = load('learningDensities_square.mat', '-ascii');
    end

    %% Squares
    % Look for squared shapes in blue regions
    squares = squareDetection(roadsignImage, propsSquare);

    % If at least one is found, add it to the roadsign collection
    if(not(isempty(squares)) && strcmp(squares(1).shape, 'square'))
       roadsigns = [roadsigns squares];
    end

    %% Triangles 
    % Look for triangular shapes in red regions
    triangles = triangleDetection(roadsignImage);

    % If at least one is found, add it to the roadsign collection
    if(not(isempty(triangles)) && strcmp(triangles(1).shape,'triangular'))
        roadsigns = [roadsigns triangles];
    end
    
    %% Circular Pannels
    % Look for circular shapes 
    circles = circleDetection(roadsignImage, sensCircle);

    % If at least one is found, add it to the roadsign collection
    if(not(isempty(circles)) && strcmp(circles(1).shape, 'circular'))
       roadsigns = [roadsigns circles];
    end
    
    %% Color detection
    colorDetection(roadsigns);

    %% Roadsign identification knowing shape, main color and secondary color
    for i = 1:size(roadsigns, 2)   
        % Dimensions of regarded rectangle
        R = [1 1 size(roadsigns(i).image,2) size(roadsigns(i).image,1)];

        % background must be black --> TODO: must be improved
        mask = im2bw(imread(strcat('../data/mask_', roadsigns(i).shape, '.png')));
        mask = imresize(mask, [size(roadsigns(i).image, 1) size(roadsigns(i).image, 2)]);
        %mask = imcomplement(im2bw(rgb2gray(roadsigns(i).image),graythresh(rgb2gray(roadsigns(i).image))));
        graySign=rgb2gray(roadsigns(i).image).*uint8(mask);
        
        % Equalize histogram
        if(useEq)
            graySign = histeq(graySign);
        end
        
        % Compute density for each area of the picture
        densities = computeDensities(graySign, R, m, n);

        % Class identification according to densities comparison
        switch roadsigns(i).shape
            case 'circular'
                disp('circle')
                roadsigns(i).id = seekClass(densities,learningDensities_circular, true, roadsigns(i).color1);
            case 'triangular'
                disp('triangle')                
                profiles = seekProfiles(getIndoor(roadsigns(i).image), R, d ,false);
                roadsigns(i).id = distEuclid(profiles,learningProfiles_triangular);
            case 'square'
                disp('square')
                roadsigns(i).id = seekClass(densities,learningDensities_square, false, '');
            case default
        end
        disp(roadsigns(i).id(1))
        disp(roadsigns(i).color1)
        disp(roadsigns(i).color2)
        
    end

end