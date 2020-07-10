%% Applied Estimation Main:
% ARTHURS: Ilian Corneliussen, Andrej Wilczek & Daniel Hirsch.
clear all; clf; close all; clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT PARAMETERS
VERSION = 2; % 1 or 2.        1:Particle   2:Kalman 
newRGB = 0;% 0 or 1.
warning_mode = 'off'; % 'off' or 'on'
mpFil = '1'; % '1' or '2'. The level number.
getTemplate = true; % true or false. 
plt = 0; % false; % true or false
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(0,'defaulttextinterpreter','latex')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PF: 
% Q = 9500
% R = 250
% lambda = 0.2
% MM = 1.5

% Error w/o motion:
%mean measurment error = 17.1333
%mean PF error = 13.5797
%nmr of outliers = 1021

% Error w motion:
%mean measurment error = 17.1333
%mean PF error = 13.879
%nmr of outliers = 1009


% KF: 
% Q = 1
% R = 1.5 
% MM = 1.5

% Error w/o motion:
%mean measurment error = 17.1333
%mean KF error = 16.4544


% Error w motion:
%mean measurment error = 17.1333
%mean KF error = 16.5118


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rng(10)
disp(['Version: ',num2str(VERSION)])
disp(['Color absmode: ',num2str(newRGB)])
disp(['Warning mode: ',warning_mode])
disp(['Level mode: ',mpFil])
disp(['Get template: ',num2str(getTemplate)])
disp(['plot per frame: ',num2str(plt)])
disp(' ')
disp('Visual Tracking of Mario - START')
disp('---------------------------------')
warning(warning_mode,'all') % Turning of warnings. 
vidObject = VideoReader([mpFil, 'level.mp4']);      % Loading video file.
vidObject.CurrentTime = 10;               % Skipping menu intro.


load('Mario_pos2.mat')
 

% Make color decision, 0 or 1. 
if newRGB == 0
    pants_RGB = [180,50,40];
    skin_RGB = [220,110,50];
    shirt_RGB = [100,100,0];
end

if newRGB == 1
    load(sprintf('%s\\%s\\pants_RGB',pwd,'Data'),'pants_RGB');
    load(sprintf('%s\\%s\\skin_RGB',pwd,'Data'),'skin_RGB');
    load(sprintf('%s\\%s\\shirt_RGB',pwd,'Data'),'shirt_RGB');
end

 


%% Version 1. 
% 1. RGB color detection for R, G, B. 
% 2. Median filtering.  (centerPoint.m)
% 3. Thresholding. (centerPoint.m)
% 4. Dilate.  (centerPoint.m)

if VERSION == 1

    firstEntry = true;
    
    
    % Global variables
    global N S lim Outlier
    % Sample uniformly from the state space bounds
    Outlier = 0;
    N = 1000;
    lim = [480,360];
    w = (1/N)*ones(1,N);
    S = [rand(1,N)*lim(1);rand(1,N)*lim(2);w];
    
    count = 0;
    while hasFrame(vidObject)
        count = count +1;
        
        vidFrame = readFrame(vidObject);
        vidFrame_pants = detect(vidFrame, pants_RGB,10);
        vidFrame_skin = detect(vidFrame, skin_RGB,10);
        vidFrame_shirt = detect(vidFrame, shirt_RGB,10);
        vidFrame_masked = vidFrame_pants + vidFrame_skin + vidFrame_shirt;% 
        [CP, Frame] = centerPoint(vidFrame_masked);
        
        if firstEntry == true
            xold = CP(1);
            yold = CP(2);
            firstEntry = false;
        end
        
        if isnan(CP) == 1 
            CP(1) = xold;
            CP(2) = yold;
        end
        
        for i = 1:1
            [estimate, pos_outlier] = Particle_filter(vidFrame_masked);
        end
        
        if plt == 1
            % Ploting stuff. 
            subplot(1,2,1)
            imshow(vidFrame); 
            title(['Estimate, Frame = ', num2str(count)],'FontSize', 18)
            hold on;
            plot(estimate(1),estimate(2),'g+','MarkerSize',10, 'LineWidth', 1);   hold off;

            subplot(1,2,2)
            imshow(vidFrame); hold on;
            title(['Particles, Frame = ', num2str(count)],'FontSize', 18)
            scatter(S(1,:),S(2,:),'b.', 'LineWidth', 0.5);
            plot(estimate(1),estimate(2),'g+','MarkerSize',10, 'LineWidth', 1);   hold off;
        end
        if count < 1662%278
            CV_error(count) = sqrt(sum((CP-possition(count,:)).^2));
            PF_error(count) = sqrt(sum((estimate'-possition(count,:)).^2));
            x_s(count) = max(S(1,:))-min(S(1,:));
            y_s(count) = max(S(2,:))-min(S(2,:));
            X = count;
        elseif count == 1662%278
            
            figure(10)
            plot(1:X, CV_error,'r','linewidth',1.5), hold on;
            plot(1:X, PF_error,'k','linewidth',1.5), hold off;
            legend('Measurement','PF','FontSize', 10)
            title('Particle Filter Error','FontSize', 18)
            xlabel('Frame','FontSize', 18)
            ylabel('Error','FontSize', 18)
            xlim([1 1662]);
            grid on
            
            figure(20)
            plot(1:X, x_s,'k','linewidth',1.5), hold on;
            plot(1:X, y_s,'r','linewidth',1.5), hold off;
            legend('X direction','Y direction','FontSize', 10)
            title('Particle Filter Spread','FontSize', 18)
            xlabel('Frame','FontSize', 18)
            ylabel('Spread','FontSize', 18)
            xlim([1 1662]);
            grid on
            
            disp(['mean measurment error = ', num2str(mean(CV_error))])
            disp(['mean PF error = ', num2str(mean(PF_error))])
            disp(['nmr of outliers = ', num2str(Outlier)])
            
            pause(1000)
        end
        
%         if count == 223
%             pause(200)
%         end
%         
        yold = CP(2);
        xold = CP(1);
            
        if plt == 1
            pause(0.00000001) % Needed for plot update. 
        end
    end
end




%% Verison 2. Kalman Filter
% 1. RGB color detection for R, G, B. 
% 2. Median filtering.  (centerPoint.m)
% 3. Thresholding. (centerPoint.m)
% 4. Dilate.  (centerPoint.m)
% 5. Correlation with template. 

if VERSION == 2
    % Distance tolerance
    distTol = 150;
    firstEntry = true;
    
    % Global variables
    global mu Sigma 

    count = 0; % Frame count.
    while hasFrame(vidObject)
        count = count + 1; 
        %Same as for Ver.1. 
        vidFrame = readFrame(vidObject);
        vidFrame_pants = detect(vidFrame, pants_RGB,10);
        vidFrame_skin = detect(vidFrame, skin_RGB,10);
        vidFrame_shirt = detect(vidFrame, shirt_RGB,10);
        vidFrame_masked = vidFrame_pants + vidFrame_skin + vidFrame_shirt;% 
        [CP, Frame] = centerPoint(vidFrame_masked);

        if firstEntry == true
            xold = CP(1);
            yold = CP(2);
            % Initialize parametes
            Sigma = eye(2);
            mu = [83 298]'; %[(xmax-size(T,2)) (ymax-size(T,1))]';
            firstEntry = false;
        end
        
        if  isnan(CP) == 1 % distTol < sqrt( abs(CP(1)-xold) + abs(CP(2) - yold) ) |
%             disp(CP)
            CP(1) = xold;
            CP(2) = yold;
        end
        
        z = [CP(1) CP(2)]';
        for i = 1:1
            [~] = Kalmanfilter(z,mu,Sigma);
        end
        
        [X, Y] = ellipseDraw(mu,Sigma);
        
        %Ploting stuff.
        if plt == 1
            subplot(2,2,1)
            imshow(vidFrame); hold on;
            title(['Original - Tracking - Frame = ', num2str(count)])
            plot(X,Y,'g','MarkerSize',10, 'LineWidth', 1); 
            plot(mu(1),mu(2),'b+','MarkerSize',10, 'LineWidth', 1);
            plot(z(1),z(2),'r+','MarkerSize',10, 'LineWidth', 1); hold off;
    %         rectangle('position',[z(1) z(2) 50 50],...
    %                   'edgecolor','r','linewidth',2); hold off;
    %         rectangle('position',[mu(1) mu(2) 30 30],...
    %                   'edgecolor','g','linewidth',2); hold off

    %         subplot(2,2,2)
    %         imshow(correlation); hold on;
    %         title('Correlation - Tracking');
    % %         scatter(z(1),z(2),'r+', 'LineWidth', 1); hold off;

            subplot(2,2,3)
            imshow(Frame); hold on;
            title('Filterd - Tracking')
    %         rectangle('position',[z(1) z(2) 50 50],...
    %                   'edgecolor','r','linewidth',2); hold off;
    %         rectangle('position',[mu(1) mu(2) 30 30],...
    %                   'edgecolor','g','linewidth',2); hold off

    %         rectangle('position',[mu(1) mu(2) 50*Sigma(1) 50*Sigma(4)],...
    %                   'curvature',[1,1],'edgecolor','g','linewidth',2);
    %         scatter(mu(1),mu(2),'r+', 'LineWidth', 1);
    %         plot(estimate(1),estimate(2),'g+','MarkerSize',10, 'LineWidth', 1); hold off;
        end
        
        if count < 1662%278
            CV_error(count) = abs(sqrt(sum((CP-possition(count,:)).^2)));
            KF_error(count) = abs(sqrt(sum((mu'-possition(count,:)).^2)));
%             x_s(count) = mmu = mu_bar  + K*(z-mu_bar);ax(S(1,:))-min(S(1,:));
%             y_s(count) = max(S(2,:))-min(S(2,:));
            Xc = count;
        elseif count == 1662%278
            figure(10)

            plot(1:Xc, CV_error,'r','linewidth',1.5), hold on;
            plot(1:Xc, KF_error,'k','linewidth',1.5), hold off;
            legend('Measurement','KF','FontSize', 10)
            title('Kalman Filter Error','FontSize', 18)
            xlabel('Frame','FontSize', 18)
            ylabel('Error','FontSize', 18)
            grid on
            xlim([1 1662]);
            disp(['mean measurment error = ', num2str(mean(CV_error))])
            disp(['mean KF error = ', num2str(mean(KF_error))])
            
%             figure(20)
%             -+
%             plot(1:X, x_s,'k','linewidth',1.5), hold on;
%             plot(1:X, y_s,'r','linewidth',1.5), hold off;
%             legend('X direction','Y direction','FontSize', 10)
%             title('Particle Filter Spread','FontSize', 18)
%             xlabel('Frame','FontSize', 18)
%             ylabel('Spread','FontSize', 18)
             pause(1000)
        end
        
        
        yold = CP(2);
        xold = CP(1);
        
        if plt == 1
            pause(0.0000000001) % Needed for plot update. 
        end
    end
end



disp('DONE.')