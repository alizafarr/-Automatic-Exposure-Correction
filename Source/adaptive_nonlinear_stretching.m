close all;
clear all;
clc
%%================================================================================================
D = '../Dataset/Part A/';
% D = '../Dataset/Part B/';
S = fullfile(pwd, D, 'IMG_1.png');
im = imread(S); % Read the Image
hsv_x = rgb2hsv(im);

i = hsv_x(:,:,3);
i255 = uint8(hsv_x(:,:,3)*255);
hsv_y = adapt_nonlinear_stretch(i, i255);
%i_new = double(hsv_y)/255.0;
hsv_x(:,:,3) = hsv_y;
y =  hsv2rgb(hsv_x);

figure; imshow(im), title('Original Image');
figure; imshow(y), title('Adaptive Non Linear Stretched Image')

brisque_orig_img = round(brisque(im), 4);
brisque_adaptnonlinear = round(brisque(y), 4);

function threshold = otsu_threshold(I)
    n=imhist(I); % Compute the histogram
    N=sum(n); % sum the values of all the histogram values
    max=0; %initialize maximum to zero
    %%================================================================================================
    for i=1:256
        P(i)=n(i)/N; %Computing the probability of each intensity level
    end
    %%================================================================================================
    for T=2:255      % step through all thresholds from 2 to 255
        w0=sum(P(1:T)); % Probability of class 1 (separated by threshold)
        w1=sum(P(T+1:256)); %probability of class2 (separated by threshold)
        u0=dot([0:T-1],P(1:T))/w0; % class mean u0
        u1=dot([T:255],P(T+1:256))/w1; % class mean u1
        sigma=w0*w1*((u1-u0)^2); % compute sigma i.e variance(between class)
        if sigma>max % compare sigma with maximum 
            max=sigma; % update the value of max i.e max=sigma
            threshold=T-1; % desired threshold corresponds to maximum variance of between class
        end
    end
end

function y = summationXPX(x, low, high)
    %Calculate px
    [M,N]=size(x); % get size of image
    total_pixels = M*N;  
    for i=0:255
       PDF(i+1)=sum(sum(x==i))/total_pixels; %hist of input image
    end
    y = x;
    for i=low:high
       I=find(x==i); %index of pixels in input image with value �i�
       xpx = x(I, 0) * PDF(low:i);
       CDF = sum(xpx);
       y(I)=round(CDF*255); %(L-1)*CDF
    end
    
end

function y = summationPx(x, low, high)
    [M,N]=size(x); % get size of image
    total_pixels = M*N;  
    for i=0:255
       PDF(i+1)=sum(sum(x==i))/total_pixels; %hist of input image
    end
    y = x;
    for i=low:high
       I=find(x==i); %index of pixels in input image with value �i�
       CDF = sum(PDF(low:i));
       y(I)=round(CDF*255); %(L-1)*CDF
    end
end

function kbar = calc_kbar(x)
    ybar = 0.5;                       %%% Given in paper
    b = otsu_threshold(x);            %%% In range 0- 255
    a1 = summationXPX(x, b, 255);
    b1 = summationPx(x, b, 255);
    c1 = summationXPX(x, 0, b);
    d1 = summationPx(x, b, 255);
    e1 = summationXPX(x, 0, 255);
    num = (255 - b) * ybar - a1 + b * b1;
    den = c1 + b * (d1) - b * e1;
    
    kbar = b * (num/den)
end

function y = adapt_nonlinear_stretch(x, x255)
    kbar = calc_kbar(x255)
    xmin = double(min(x(:)));
    xmax = double(max(x(:)));
    b = otsu_threshold(x)/255.0           %%%Value of Adaptation level
    mu = 0.5;  %%%% Parameter lie between [0, 1]
    k = mu + (1 - mu)*b;   %%%% Check 
    [M,N]=size(x); % get size of image
    y = x;
    for i = 1:M
        for j = 1:N
          if x(i, j) <= xmin
              y(i, j) = 0;
          elseif x(i, j) > xmin && x(i, j) <= b
              y(i, j) = (k/(b - xmin))*(x(i, j) - xmin);
          elseif x(i, j) > b && x(i, j) < xmax
              y(i, j) = k + ((1 - k)/(xmax - b))*(x(i, j) - b);
          else 
              y(i, j) = 1;
          end
        end
    end
end