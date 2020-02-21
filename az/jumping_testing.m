%% main function for jump_n_run
clear all; close all; clc;

%% loading stuff
opt = options();

% + updating due to location
opt.txt.size.version = 12;
opt.txt.size.title = 20;
opt.txt.size.coin = 24;
opt.txt.size.space = 20;


%% Das Experiment wird versucht; wenn etwas schief geht, wird es gecatcht
try
    %% Window wird definiert
    Screen('Preference', 'SkipSyncTests', 1);
    tmpx = 950; tmpy = 180;
    [scr, scrSize] = Screen('OpenWindow',0,opt.color.background,[tmpx tmpy 640+tmpx 360+tmpy]);   % zu hause NUR am laptop
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
    
    % jumping parameters
    opt.jump.maxL = opt.land.w(2) * 2;
    opt.jump.maxH = opt.world.y.ground - opt.world.frame(2) - opt.hero.h;
    
    % personal maximum F  ********** !!! needs to be collected at beginning !!! **********
    opt.jump.maxF = 1200;

    % loop as long as "alive" and "not finished"
    vbl=Screen('Flip', scr);
    while alive
        % fetch input
        [ ~, ~, keyCode ] = KbCheck;
        
        % this jump will be precalculated, based on input value
        if ~airtime && any(keyCode(opt.keys.jump))
            
            % get Force in order to calculate height of jump
            jump.F = find(keyCode(opt.keys.jump))/10 * opt.jump.maxF;       % !!! update with FORCEPLATE !!!
            disp(['F = ' num2str(jump.F)]);
                
            % mapping of FORCE to HEIGHT and LENGTH of jump
            jump.L = opt.jump.maxL/opt.jump.maxF * jump.F;      % linear mapping
            jump.H = opt.jump.maxH/opt.jump.maxF * jump.F;      % linear mapping
            
            % fit parameters for parabel-like movement
            jump.fitp = polyfit( [0 jump.L/2 jump.L] , [0 jump.H 0] , 2);
            
            % evaluate height for each timestep
            jump.y = polyval(jump.fitp , 0:1:jump.L);
            
            % set airtime
            airtime = true;
            airframe = 1;
        end
        
        % end airtime 
        if airtime && airframe > numel(jump.y)
            airtime = false;
        end
        
        % fetch height of hero for this frame, if height is positiv
        if airtime %&& jump.y(airframe) > 0     % only when there is really a positiv height
            hero = jump.y(airframe);
            airframe = airframe + opt.game.ppf;
        else
            hero = 0;
        end
        
        % draw world + landscape + hero
        draw_world(scr,opt,hero);
        
        % check for collision
        
        % flip
        vbl = Screen('Flip', scr, vbl + opt.game.fi * 0.5);
                
        % next frame
        frame = frame + 1;
        
        % quit
        if ~airtime && keyCode(opt.keys.Quit)
            alive = false;
        end
            
    end
    
catch ups
    % Wir catchen, falls etwas schief gelaufen ist
    disp('! ! ! ! ! ! ! ! !');disp('... E R R O R ...');disp('! ! ! ! ! ! ! ! !');
    ListenChar(0);Screen('CloseAll');rethrow(ups);
end

%% Screen schließen und Tastatur verfügbar machen
ListenChar(0);
Screen('CloseAll');


%% ********* sub_functions *************************************************************************
% *********************************************************************************
% *** draw world ***
function draw_world(scr,opt,height)

% filled frame
Screen('FillRect', scr, opt.color.world, opt.world.frame);

% landscape
coord_x = [opt.world.frame(1) opt.world.frame(1) opt.world.frame(3) opt.world.frame(3)]';
coord_y = [opt.world.frame(4) opt.world.y.ground opt.world.y.ground opt.world.frame(4)]';
Screen('FillPoly',scr,opt.color.land,[coord_x,coord_y]);

% frame
Screen('FrameRect', scr, opt.color.frame, opt.world.frame, 2);

% hero
hero(1,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) - (opt.hero.w / 2));
hero(2,1) = ceil(opt.world.y.ground - opt.hero.h - height);
hero(3,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) + (opt.hero.w / 2));
hero(4,1) = ceil(opt.world.y.ground - height);

Screen('FillRect', scr, opt.hero.color, hero);

% if isempty(hero)
%     hero(1,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) - (opt.hero.w / 2));
%     hero(2,1) = ceil(opt.world.y.ground - opt.hero.h);
%     hero(3,1) = ceil((opt.world.px_x * opt.hero.position_x) + opt.world.frame(1) + (opt.hero.w / 2));
%     hero(4,1) = ceil(opt.world.y.ground);
%     Screen('FillRect', scr, opt.hero.color, hero);
% else
%     DrawFormattedText(scr, 'hero is jumping', 'center', 'center', opt.color.orange);
% end
end


