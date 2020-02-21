%% main function for jump_n_run
clear all; %close all; clc;

%% loading stuff
opt = options();

%% simulating screen
scrSize = [0 0 640 360];

% get flip_intervall + fps for current screen
opt.game.fi = 0.02;
opt.game.fps = 50;

%% generate world
opt.world.px_x = scrSize(3)*opt.world.perc_x;
opt.world.px_y = scrSize(4)*opt.world.perc_y;

opt.world.frame(1,1) = scrSize(3)/2 - opt.world.px_x/2;   % left_line
opt.world.frame(3,1) = scrSize(3)/2 + opt.world.px_x/2;   % right_line
opt.world.frame(2,1) = scrSize(4)/2 - opt.world.px_y/2;   % top_line
opt.world.frame(4,1) = scrSize(4)/2 + opt.world.px_y/2;   % bottom_line

% move lower boundery of world to generate some "ground"
opt.world.frame(4,1) = opt.world.frame(4,1) + 30;                   % add constant pixels

% some world_dependent y_coordinates of stuff
opt.world.y.ground = scrSize(4)/2 + opt.world.px_y/2;
opt.world.y.title = opt.world.frame(2,1)/2;
opt.world.y.version = scrSize(4)-5;


%% PLAY_TIME

vx = opt.game.speed;    %       px / s

% personal maximum F
maxF = 1200;

% constants
maxL = opt.land.w(2) * 2;
maxH = opt.world.y.ground - opt.world.frame(2) - opt.hero.h;


% close all; 
figure(); hold on; axis equal;
for jumpF = linspace(maxF/10,maxF,10)
    % linear mapping of FORCE to HEIGHT and LENGTH of jump
    jumpL = maxL/maxF * jumpF;
    jumpH = maxH/maxF * jumpF;
    
    % fit parameters for parabel-like movement
    p = polyfit( [0 jumpL/2 jumpL] , [0 jumpH 0] , 2);
    g = -2 * p(1);
    v0 = p(2);
    c = p(3);
    
    % evaluate height for each timestep
    t = 0:1:jumpL;
    h = v0 .* t - g .* t.^2 / 2;
    h2 = polyval(p,t);
    
    % plotting
    plot(t,h)
end


