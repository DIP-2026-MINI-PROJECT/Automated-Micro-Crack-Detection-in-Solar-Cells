clc; clear; close all;

dataDir = 'elpv_dataset/data';   % folder that holds labels.csv and images/
P = struct('k',4, 'D0',40, 'r',5, 'K',8, 'minLen',130, 'minBlob',250, 'margin',8);

%% 1. Read dataset labels
fid = fopen(fullfile(dataDir,'labels.csv'));
C = textscan(fid,'%s %f %s');
fclose(fid);
files = C{1};  prob = C{2};  types = C{3};

%% 2. Demonstration on one cell (shows every stage)
I = imread(fullfile(dataDir,'images/cell0003.png'));
[isCrack, ~, S] = detectCracks(I, P);

figure('Name','Micro-crack detection pipeline');
subplot(3,3,1); imshow(S.I0);                     title('1. Original EL image');
subplot(3,3,2); imhist(S.I0, 64);                 title('2. Histogram (original)');
subplot(3,3,3); imshow(S.Ieq);                    title('3. Median + CLAHE');
subplot(3,3,4); imshow(S.B, []);                  title('4. SVD background (k=4)');
subplot(3,3,5); imshow(S.R, []);                  title('5. Residual  I - B');
subplot(3,3,6); imshow(log(1 + abs(S.F)), []);    title('6. DFT spectrum of residual');
subplot(3,3,7); imshow(S.Rs, []);                 title('7. Gaussian LPF output');
subplot(3,3,8); imshow(S.heat);                   title('8. Black-hat (pseudocolor)');
subplot(3,3,9); imshow(S.overlay);
lbl = {'NO CRACK','CRACK DETECTED'};
title(sprintf('9. %s (length %d px)', lbl{isCrack + 1}, S.len));

%% 3. Evaluate on the whole ELPV dataset
n = numel(files);
pred = false(n,1);
for i = 1:n
    pred(i) = detectCracks(imread(fullfile(dataDir,files{i})), P);
end

truth = prob >= 0.5;                 % 0.67 and 1.0 -> defective
sure  = prob == 0 | prob == 1;       % confidently labelled cells only
groups = {'mono','poly','all'};
for g = 1:3
    sel = sure & (strcmp(types,groups{g}) | g == 3);
    TP = sum(pred(sel) & truth(sel));   FP = sum(pred(sel) & ~truth(sel));
    FN = sum(~pred(sel) & truth(sel));  TN = sum(~pred(sel) & ~truth(sel));
    fprintf('%-4s  Acc %.3f  Prec %.3f  Rec %.3f  F1 %.3f\n', groups{g}, ...
        (TP+TN)/sum(sel), TP/(TP+FP), TP/(TP+FN), 2*TP/(2*TP+FP+FN));
end
figure; confusionchart(double(truth(sure)), double(pred(sure)));
title('Confusion matrix (0 = good, 1 = cracked)');

%% ------------------------------------------------------------------------
function [isCrack, crackMask, S] = detectCracks(I, P)
if size(I,3) == 3, I = rgb2gray(I); end
I = imresize(im2double(I), [300 300]);
S.I0 = I;

I = medfilt2(I, [3 3], 'symmetric');
I = adapthisteq(I, 'ClipLimit', 0.01);
S.Ieq = I;

[U, Sg, V] = svd(I);
S.B = U(:,1:P.k) * Sg(1:P.k,1:P.k) * V(:,1:P.k)';
S.R = I - S.B;

[M, N] = size(S.R);
[u, v] = meshgrid(-floor(N/2):ceil(N/2)-1, -floor(M/2):ceil(M/2)-1);
H = exp(-(u.^2 + v.^2) / (2 * P.D0^2));
S.F = fftshift(fft2(S.R));
S.Rs = real(ifft2(ifftshift(H .* S.F)));

BH = imbothat(S.Rs, strel('disk', P.r, 0));
m = median(BH(:));
s = 1.4826 * median(abs(BH(:) - m));
bw = BH > m + P.K * s;
e = P.margin;
bw([1:e, end-e+1:end], :) = false;
bw(:, [1:e, end-e+1:end]) = false;
bw = bwareaopen(bw, 30, 8);

st = regionprops(bw, 'Area','MajorAxisLength','Eccentricity','Orientation','PixelIdxList');
isLine = [st.MajorAxisLength] >= 25 & [st.Eccentricity] >= 0.95 & abs([st.Orientation]) > 8;
isBlob = [st.Area] > P.minBlob;

lineMask = false(M, N);
lineMask(vertcat(st(isLine).PixelIdxList)) = true;
crackMask = lineMask;
crackMask(vertcat(st(isBlob).PixelIdxList)) = true;

S.len = nnz(bwskel(lineMask));
isCrack = S.len > P.minLen || any(isBlob);

if nargout > 2
    S.heat = ind2rgb(gray2ind(mat2gray(BH), 256), jet(256));
    S.overlay = imoverlay(S.I0, imdilate(crackMask, strel('disk',1)), [1 0 0]);
end
end
