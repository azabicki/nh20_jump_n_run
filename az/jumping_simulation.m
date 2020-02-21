%% main function for jump_n_run
clear all; close all; clc;

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
% init
frame = 1;
alive = true;
finish = false;
airtime = false;

% constants
g = 9.81;       % gravitation:  px / s^2
m = 1;          % mass:         kg
Fg = m*g;       % g-force down: kg * px / s^2
delta_t = 1;    % timestep in:  s

vx = opt.game.speed;    %       px / s

%% mapping: input -> v0
% [~,keyCode,~] = KbPressWait();
% FlushEvents('keyDown');

F = 10;                 % Force in:                 kg * px / s^2
v0 = F * delta_t / m;   % initial velocity in:      px / s
v0 = v0 * 40;

close all; figure(); hold on; axis equal;
for v0 = 10:10:100 %1:10
    %% calculating motion
    % total time
    t_t = 2 * v0 / g;       % motion time in:           s
    
    % #_frames in motion
    nF =  ceil(t_t * opt.game.fps);
    t = (0:nF) / 50; % linspace(0 , t_t ,  t_t * opt.game.fps);
    
    h = v0 .* t - g .* t.^2 / 2;
    
    data(v0,1) = max(h);
    data(v0,2) = max(t);
    data(v0,3) = data(v0,1)/data(v0,2);
    
%     x_t = t_t * vx;
    
    plot(t,h)
end




