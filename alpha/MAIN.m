%% main function for jump_n_run
clear all; close all; clc;

%% cosing and simulating
wo_bin_ich = 3;     % 1 = EXPERIMENT --> ein Screen
                    % 2 = Büro, 2 Screens, Experiment auf Laptop
                    % 3 = Laptop, Experiment in kleinem Fenster



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
            [scr, scrSize] = Screen('OpenWindow',2,opt.color.background);        % im Büro auf dem 2nd Screen
        case 3
            tmpx = 950; tmpy = 180;
            [scr, scrSize] = Screen('OpenWindow',0,opt.color.background,[tmpx tmpy 640+tmpx 360+tmpy]);   % zu hause NUR am laptop
    end
    Screen('TextStyle', scr, 0);
    ListenChar(2);
    
    % get flip_intervall + fps for current screen
    opt.game.fi = Screen('GetFlipInterval',scr);    
    opt.game.fps = round(1/Screen('GetFlipInterval',scr));
    
    %% generate world
    opt.world.x = scrSize(3)*opt.world.perc_x;
    opt.world.y = scrSize(4)*opt.world.perc_y;
    
    world(1,1) = scrSize(3)/2 - opt.world.x/2;   % left_line
    world(3,1) = scrSize(3)/2 + opt.world.x/2;   % right_line
    world(2,1) = scrSize(4)/2 - opt.world.y/2;   % top_line
    world(4,1) = scrSize(4)/2 + opt.world.y/2;   % bottom_line
    
    % move lower boundery of world to generate some "ground"
%     world(4,1) = world(4,1) + scrSize(4) * 0.04;    % add fraction of screen_height
    world(4,1) = world(4,1) + 30;                   % add constant pixels
    
    % some world_dependent y_coordinates of stuff
    y.ground = scrSize(4)/2 + opt.world.y/2;
    y.title = world(2,1)/2;
    y.version = scrSize(4)-5;
    
    %% generate random landscape
    [~,obstacles,landscape] = create_landscape(opt,world,y);
    
    %% intro screen
    go_on = 0;
    blink_t = tic;
    blink_const = 0.5;
    while go_on == 0
        % draw world
        draw_world(scr,opt,world,y,[])
        
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
        
        % Falls die richtige Taste gedrückt wurde, wird die while-Schleife beendet
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
        draw_world(scr,opt,world,y,[]);
        
        % countdown
        Screen('TextStyle', scr, 0);
        Screen('TextSize', scr, opt.txt.size.coin + 20*(3-t));
        DrawFormattedText(scr, num2str(t), 'center',  'center', opt.color.white);
        
        % flip
        Screen('Flip', scr);
        
        % waiting a sec
        pause(1);
    end
    
    %% GO GO GO
    draw_world(scr,opt,world,y,[]);
    Screen('TextSize', scr, opt.txt.size.coin + 20*(3-t));
    DrawFormattedText(scr, 'L O S', 'center',  'center', opt.color.white);
    Screen('Flip', scr);
    pause(.5);
    
    %% PLAY_TIME
    % init
    frame = 1;
    waitframes = 1;
    
    % loop as long as "alive" and "not finished"
    alive = true;
    finish = false;
    
    vbl=Screen('Flip', scr);
    t_total = tic;
    while alive && ~finish
        % draw world + landscape
        draw_world(scr,opt,world,y,landscape.(['f' num2str(frame)]));

        % draw hero
        
        % check for collision
        
        % check if finished
        if frame == numel(fieldnames(landscape))
            finish = true;
        end
        
        % flip
        vbl = Screen('Flip', scr, vbl + (waitframes - 0.5) * opt.game.fi);
        
        % next frame
        frame = frame + 1;
    end
    duration = toc(t_total);
        
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

%% Screen schließen und Tastatur verfügbar machen
ListenChar(0);
if wo_bin_ich == 1, ShowCursor; end
Screen('CloseAll');


%% sub_function *********************************************************************
% ************************************************************************
% *** plot world ***
function draw_world(scr,opt,world,y,land)
% title
Screen('TextStyle', scr, 1);
Screen('TextSize', scr, opt.txt.size.title);
DrawFormattedText(scr, opt.txt.title, 'center',  y.title, opt.color.orange);

% version
Screen('TextStyle', scr, 0);
Screen('TextSize', scr, opt.txt.size.version);
DrawFormattedText(scr, opt.txt.version, 'right', y.version , opt.color.white);

% filled frame
Screen('FillRect', scr, opt.color.world, world);

% landscape
if isempty(land)
    coord_x = [world(1) world(1) world(3) world(3)]';
    coord_y = [world(4) y.ground y.ground world(4)]';
    Screen('FillPoly',scr,opt.color.land,[coord_x,coord_y]);
else
    Screen('FillPoly',scr,opt.color.land,land);
end

% frame
Screen('FrameRect', scr, opt.color.frame, world, 2);
end

% ************************************************************************
% *** create landscape ***
function [w, obs, w_poly] = create_landscape(opt,world,y)
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

% add margins left + right
w = [zeros(1,opt.world.x) , w]; % , zeros(1,opt.world.x)];

% convert landscape into xy-coordinates for each single frame
nFrames = opt.game.duration * opt.game.fps;
ppf = opt.game.speed / opt.game.fps;

for f = 1:nFrames
    ix = (f) * ppf + 1;
    iy = ix + opt.world.x - 1;
    
    tmp_landscape = w(ix:iy);
    
    
    tmp_x = find(abs(diff(tmp_landscape))) + 1;
    
    coord_x = [world(1) ; world(1) ; nan(2*numel(tmp_x),1) ; world(3) ; world(3)];
    coord_y = [world(4) ; y.ground - tmp_landscape(1) ; nan(2*numel(tmp_x),1) ; y.ground - tmp_landscape(end) ; world(4)];
    for j = 1:numel(tmp_x)
        coord_x(2*j-1+2 : 2*j+2) = world(1) + tmp_x(j);
        coord_y(2*j-1+2) = y.ground - tmp_landscape(tmp_x(j)-1);
        coord_y(2*j+2) = y.ground - tmp_landscape(tmp_x(j));
    end
    
    w_poly.(['f' num2str(f)]) = [coord_x,coord_y];
end
end

% ************************************************************************
% ****** QUIT ??? ******
function sub_quit(scr)
DrawFormattedText(scr, 'abort', 'center', 'center', [255, 0, 0]);
Screen('Flip', scr);
WaitSecs(.5);
Screen('CloseAll');
end


