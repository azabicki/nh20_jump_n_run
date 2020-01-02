%% options and settings 4 nh20_jnrKMP
function opt = options()
opt.txt.version = 'v0.1 / 01.01.20';

% colors
opt.color.black = [0,0,0];
opt.color.grey = [88,88,88];
opt.color.white = [255,255,255];
opt.color.orange = [255,102,0];

opt.color.background = opt.color.grey;
opt.color.frame = opt.color.orange;
opt.color.world = opt.color.black;
opt.color.land = opt.color.white;

% input 
opt.keys.Up = 38;
opt.keys.Return = 13;
opt.keys.Space = 32;
opt.keys.Quit = 81;     % press "q" to QUIT

% game settings
opt.game.duration = 10;  % seconds
opt.game.speed = 200;     % px/sec

% landscape
opt.land.color = opt.color.white;
opt.land.dist = [100 300];   % intervall for distance between obstacles
opt.land.h = [10 100];       % intervall for height of obstacles
opt.land.w = [10 40];        % intervall for height of obstacles

% world
opt.world.perc_x = .90; % world_width as % of sreen_width
opt.world.perc_y = .70; % world_height as % of sreen_height

% text
opt.txt.title = 'nemoHack2020 : jump_n_run';
opt.txt.coin = ' please insert coin \n\n\n press [space] to begin ';
opt.txt.space = 'weiter mit [Leertaste]';
opt.txt.size.version = 10;
opt.txt.size.title = 20;
opt.txt.size.coin = 28;
opt.txt.size.space = 20;

