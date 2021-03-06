%% main function for jump_n_run
clear all; close all; clc;

%% cosing and simulating
wo_bin_ich = 3;     % 1 = EXPERIMENT --> ein Screen
                    % 2 = B?ro, 2 Screens, Experiment auf Laptop
                    % 3 = Laptop, Experiment in kleinem Fenster

%% debug modus anschalten um dann mehr informationen auf dem screnn angezeigt zu bekommen
debug = false;

if debug == true
    tmp_debug1 = false;
end

%% loading stuff
opt = options();

% + updating due to location
switch wo_bin_ich
    case 2
        opt.txt.size.version = 10;
        opt.txt.size.title = 20;
        opt.txt.size.coin = 28;
        opt.txt.size.space = 20;
    case 3
        opt.txt.size.version = 12;
        opt.txt.size.title = 20;
        opt.txt.size.coin = 24;
        opt.txt.size.space = 20;
end

%% Das Experiment wird versucht; wenn etwas schief geht, wird es gecatcht
try
    %% Window wird definiert
    Screen('Preference', 'SkipSyncTests', 1);
    switch wo_bin_ich
        case 1
            [scr, scrSize] = Screen('OpenWindow',0,opt.color.background);        % das EIGENTLICH EXPERIMENT, nur ein Screen
            HideCursor;
        case 2
            [scr, scrSize] = Screen('OpenWindow',1,opt.color.background);        % im B?ro auf dem 2nd Screen
        case 3
            tmpx = 950; tmpy = 180;
            [scr, scrSize] = Screen('OpenWindow',0,opt.color.background,[tmpx tmpy 640+tmpx 360+tmpy]);   % zu hause NUR am laptop
    end
    Screen('TextStyle', scr, 0);
    ListenChar(2);
    
    % get "flip_intervall" + "fps" for current screen + calculate "pixels per frame"
    opt.game.fi = Screen('GetFlipInterval',scr);    
    opt.game.fps = round(1/Screen('GetFlipInterval',scr));
    opt.game.ppf = opt.game.speed / opt.game.fps;

    %% generate world
    opt.world.px_x = scrSize(3)*opt.world.perc_x;
    opt.world.px_y = scrSize(4)*opt.world.perc_y;
    
    opt.world.frame(1,1) = scrSize(3)/2 - opt.world.px_x/2;   % left_line
    opt.world.frame(3,1) = scrSize(3)/2 + opt.world.px_x/2;   % right_line
    opt.world.frame(2,1) = scrSize(4)/2 - opt.world.px_y/2;   % top_line
    opt.world.frame(4,1) = scrSize(4)/2 + opt.world.px_y/2;   % bottom_line
    
    % move lower boundery of world to generate some "ground"
%     opt.world.frame(4,1) = opt.world.frame(4,1) + scrSize(4) * 0.04;    % add fraction of screen_height
    opt.world.frame(4,1) = opt.world.frame(4,1) + 30;                   % add constant pixels
    
    % some world_dependent y_coordinates of stuff
    opt.world.y.ground = scrSize(4)/2 + opt.world.px_y/2;
    opt.world.y.title = opt.world.frame(2,1)/2;
    opt.world.y.version = scrSize(4)-5;
    
	% calculate x-position in pixels of hero, necessary for collision detection
    opt.hero.location_on_x(1,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) - (opt.hero.w / 2));
    opt.hero.location_on_x(1,2) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) + (opt.hero.w / 2));

    
    %% generate random landscape
    [~,obstacles,landscape] = create_landscape(opt);
    
    %% intro screen
    go_on = 0;
    blink_t = tic;
    blink_const = 0.5;
    while go_on == 0
        % draw world
        draw_world(scr,opt,[],0)
        
        % insert coin
        Screen('TextStyle', scr, 0);
        Screen('TextSize', scr, opt.txt.size.coin);
        if mod(floor(toc(blink_t)/blink_const),2) == 0
            DrawFormattedText(scr, opt.txt.coin, 'center',  'center', opt.color.white);
        end
                
        % flip
        Screen('Flip', scr);
        
        % Es erfolgt ein Keyboard-Check
        [ ~, ~, keyCode ] = KbCheck;
        
        % Falls die richtige Taste gedr?ckt wurde, wird die while-Schleife beendet
        if keyCode(opt.keys.Return) || keyCode(opt.keys.Space) || keyCode(opt.keys.Quit)
            go_on = 1;
            if keyCode(opt.keys.Quit), go_on = 2; end
        end
    end
    
    % quit?
    if go_on == 2, sub_quit(scr); end
    
    %% countdown
    for t = 3:-1:1
        % draw world
        draw_world(scr,opt,[],0);
        
        % countdown
        Screen('TextStyle', scr, 0);
        Screen('TextSize', scr, opt.txt.size.coin + 20*(3-t));
        DrawFormattedText(scr, num2str(t), 'center',  'center', opt.color.white);
        
        % flip
        Screen('Flip', scr);
        
        % waiting a sec
        pause(.5);
    end
    
    %% GO GO GO
    draw_world(scr,opt,[],0);
    Screen('TextSize', scr, opt.txt.size.coin + 20*(3-t));
    DrawFormattedText(scr, 'L O S', 'center',  'center', opt.color.white);
    Screen('Flip', scr);
    pause(.5);
    
    %% PLAY_TIME
    % init
    frame = 1;
    alive = true;
    finish = false;
    airtime = false;
    
    % jumping parameters
    opt.jump.maxL = opt.land.w(2) * 2;
    opt.jump.maxH = opt.world.y.ground - opt.world.frame(2) - opt.hero.h;
    
    % personal maximum F  ********** !!! needs to be collected at beginning !!! **********
    opt.jump.maxF = 1200;

    % loop as long as "alive" and "not finished"    
    vbl=Screen('Flip', scr);
    t_total = tic;
    while alive && ~finish
        % fetch input -> actually it is a keystroke from 1 -> 0, determining the power of the jump
        [ ~, ~, keyCode] = KbCheck;
        
        % this jump will be pre-calculated, based on input value
        if ~airtime && any(keyCode(opt.keys.jump))
            
            % get Force in order to calculate height of jump
            jump.F = find(keyCode(opt.keys.jump))/10 * opt.jump.maxF;       % !!! update with FORCEPLATE !!!
                
            % mapping of FORCE to HEIGHT and LENGTH of jump
%             jump.L = opt.jump.maxL * (jump.F / opt.jump.maxF);    % linear mapping
            jump.L = opt.land.w(2)*3;                                 % constant mapping
            jump.H = opt.jump.maxH * (jump.F / opt.jump.maxF);      % linear mapping
            
            % fit parameters for parabel-like movement
            jump.fitp = polyfit( [0 jump.L/2 jump.L] , [0 jump.H 0] , 2);
            
            % evaluate height for each timestep
            jump.y = polyval(jump.fitp , 0:opt.game.ppf:jump.L);
            
            % fixing values lower zero
            jump.y(jump.y < 0) = 0;
            
            % set airtime==true, when hero starts jumping
            airtime = true;
            airframe = 1;   % air_frame to know, which timepoint of the jump to plot
            
            if debug == true
                disp(['F = ' num2str(jump.F) ' - L = ' num2str(jump.L) ' px']);
                disp(['starting frame = ' num2str(frame)]);
                tmp_debug1 = true;
            end
        end
        
        % end airtime 
        if airtime && airframe > numel(jump.y)
            airtime = false;
            if debug == true
                disp(['landing frame = ' num2str(frame)]);
                tmp_debug1 = false;
            end
        end
        
        % fetch height of hero for this frame, if height is positiv
        if airtime %&& jump.y(airframe) > 0     % only when there is really a positiv height
            hero = jump.y(airframe);
            airframe = airframe + 1;
        else
            hero = 0;
        end
        
        % draw world + landscape
        draw_world(scr,opt,landscape.(['f' num2str(frame)]),hero);
        
        % visual debugging information      *** ATTENTION : BUGGY ***
        if debug == true
            % draw debug-line each 10 frames [10:10:end]
            tmp123 = (10:10:opt.world.px_x) - round(mod(frame,10) * opt.game.ppf) + opt.world.frame(1);
            for tmp = tmp123
                Screen('DrawLine', scr, [255 108 0], tmp, opt.world.y.ground, tmp, opt.world.y.ground-20 ,1);
            end
        
            if tmp_debug1
                tmp_xx = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) - (opt.hero.w / 2));
                tmp_x = tmp_xx - round((airframe-2)*opt.game.ppf);
                Screen('DrawLine', scr, [0 255 108], tmp_x, opt.world.y.ground, tmp_x, opt.world.y.ground-40 ,1);
            end
        end
            
        % flip
        vbl = Screen('Flip', scr, vbl + opt.game.fi * 0.5);
        
        % check for collision
        alive = collision_detection(opt, landscape.(['f' num2str(frame)]), hero, alive);

        % check if finished
        if frame == numel(fieldnames(landscape))
            finish = true;
            pause(1);
        end
        
        % next frame
        frame = frame + 1;
    end
    duration = toc(t_total);
    
    %% first scrren after ending: dead or alive?
    
    
    %% good-bye screen
    Screen('TextSize', scr, opt.txt.size.coin);
    DrawFormattedText(scr, '***   G A M E   O V E R   ***', 'center', 'center', opt.color.white);
    Screen('Flip', scr);
    WaitSecs(1);

catch ups
    % Wir catchen, falls etwas schief gelaufen ist
    disp('! ! ! ! ! ! ! ! !');disp('... E R R O R ...');disp('! ! ! ! ! ! ! ! !');
    ListenChar(0);Screen('CloseAll');rethrow(ups);
end

%% Screen schlie?en und Tastatur verf?gbar machen
ListenChar(0);
if wo_bin_ich == 1, ShowCursor; end
Screen('CloseAll');


%% ********* sub_functions *************************************************************************
% *********************************************************************************
% *** create landscape ***
function [w, obs, w_poly] = create_landscape(opt)
% calculate length in px
L = opt.game.speed * opt.game.duration;

% create obstacles repetively
obs(1,1:3) = [1 , 1 + randi(opt.land.w) , randi(opt.land.h)];

while obs(end,2) < L
    idx = size(obs,1) + 1;
    
    tmp = obs(idx-1,2) + randi(opt.land.dist);
    obs(idx,:) = [tmp , tmp + randi(opt.land.w) , randi(opt.land.h)];
end
obs(end,:) = [];

% draw line
w = zeros(1,L);
for i = 1:size(obs,1)
    w(obs(i,1):obs(i,2)) = obs(i,3);
end

% add flat_line at start
ww = [zeros(1,opt.world.px_x) , w];

% convert landscape into xy-coordinates for each single frame
add = ceil( opt.world.px_x * (1-opt.hero.position_x) / opt.game.ppf);
nFrames = opt.game.duration * opt.game.fps + add;

for f = 1:nFrames
    ix = round(f * opt.game.ppf) + 1;
    iy = ix + opt.world.px_x - 1;
    
    if numel(ww) < iy % add WALL at end
        nNaN = iy - numel(ww);
        tmp_landscape = [ww(ix:end) ones(1,nNaN)*opt.world.px_y];
    else % cutout picture for frame out of world
        tmp_landscape = ww(ix:iy);
    end
    tmp_x = find(abs(diff(tmp_landscape))) + 1;
    
    coord_x = [opt.world.frame(1) ; opt.world.frame(1) ; nan(2*numel(tmp_x),1) ; opt.world.frame(3) ; opt.world.frame(3)];
    coord_y = [opt.world.frame(4) ; opt.world.y.ground - tmp_landscape(1) ; nan(2*numel(tmp_x),1) ; opt.world.y.ground - tmp_landscape(end) ; opt.world.frame(4)];
    for j = 1:numel(tmp_x)
        coord_x(2*j-1+2 : 2*j+2) = opt.world.frame(1) + tmp_x(j);
        coord_y(2*j-1+2) = opt.world.y.ground - tmp_landscape(tmp_x(j)-1);
        coord_y(2*j+2) = opt.world.y.ground - tmp_landscape(tmp_x(j));
    end
    
    w_poly.(['f' num2str(f)]) = [coord_x,coord_y];
end
end

% *********************************************************************************
% *** draw world ***
function draw_world(scr,opt,land,height)
% title
Screen('TextStyle', scr, 1);
Screen('TextSize', scr, opt.txt.size.title);
DrawFormattedText(scr, opt.txt.title, 'center',  opt.world.y.title, opt.color.orange);

% version
Screen('TextStyle', scr, 0);
Screen('TextSize', scr, opt.txt.size.version);
DrawFormattedText(scr, opt.txt.version, 'right', opt.world.y.version , opt.color.white);

% filled frame
Screen('FillRect', scr, opt.color.world, opt.world.frame);

% landscape
if isempty(land)
    coord_x = [opt.world.frame(1) opt.world.frame(1) opt.world.frame(3) opt.world.frame(3)]';
    coord_y = [opt.world.frame(4) opt.world.y.ground opt.world.y.ground opt.world.frame(4)]';
    Screen('FillPoly',scr,opt.color.land,[coord_x,coord_y]);
else
    Screen('FillPoly',scr,opt.color.land,land);
end

% frame
Screen('FrameRect', scr, opt.color.frame, opt.world.frame, 2);

% hero
hero(1,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) - (opt.hero.w / 2));
hero(2,1) = ceil(opt.world.y.ground - opt.hero.h - height);
hero(3,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) + (opt.hero.w / 2));
hero(4,1) = ceil(opt.world.y.ground - height);

Screen('FillRect', scr, opt.hero.color, hero);
end

% *********************************************************************************
% *** collision detection ***
function alive = collision_detection(opt, land, hero, alive)
% get height of interessting landmarks
land_h(1) = opt.world.y.ground - land(find( land(:,1) < opt.hero.location_on_x(1,1),1,'last'),2);
land_h(2) = opt.world.y.ground - land(find( land(:,1) > opt.hero.location_on_x(1,2),1,'first'),2);

% checking
if any(hero < land_h)
    alive = false;
end
end

% *********************************************************************************
% *** quit ??? ***
function sub_quit(scr)
DrawFormattedText(scr, 'abort', 'center', 'center', [255, 0, 0]);
Screen('Flip', scr);
WaitSecs(.5);
Screen('CloseAll');
end


