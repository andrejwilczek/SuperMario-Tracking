clc
clear all

%% Test Japan 
RGB = [236,0,51];

japan = imread('japan.jpg');
size(japan)
figure(1)
imshow(japan)
H = size(japan,1);
W = size(japan,2);

japan = reshape(japan,H*W,3);

mask = zeros(W*H,1);
tol = 20; 

dist = pdist2(japan,RGB);

mask(dist<tol) = 0.5;

mask = reshape(mask,H,W,1);


[I, J] = find(mask == 0.5);

I_mean = round(mean(I));
J_mean = round(mean(J));

pos = [I_mean,J_mean];

mask(I_mean,J_mean) = 40;
%mask(pos)

figure(2)
imshow(mask)
%hold on 
%imshow(pos)

%% Level 1
% 
% 
% v = VideoReader('Firstlevel.mp4');







