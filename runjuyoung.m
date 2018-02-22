% Main psychToolbox experiment control script
%
% manages stimulus generation and metadata for Baccus lab experiments
%
% (c) 2015 Niru Maheswaranathan
% 
%   based off of Ben Naecker's setup:
%   https://github.com/bnaecker/basic-stimulus
%
% 28 Apr 2015 - initial version
commandwindow
addpath('jsonlab/')
addpath('utils/')
addpath('functions/')
addpath('HelperFunctions/')

% turn the `debug` flag on when testing
debug_exp = false;

try

  % Construct an experimental structure array
  ex = initexptstruct(debug_exp);

  % Initialize the keyboard
  ex = initkb(ex);

  % bg color
  ex.disp.bgcol = 0; 
  % Initalize the visual display w/ offset position
  ex = initdisp(ex, 1000, 300);
  
  % wait for trigger
  ex = waitForTrigger(ex);

  % Parse this day's experiment config file
  basedir = fullfile('logs/', ex.today);
  stimuli = loadjson(fullfile(basedir, 'config.json'));

  % Run the stimuli
  for stimidx = 1:length(stimuli)

    % get the function name for this stimulus
    ex.stim{stimidx}.function = stimuli{stimidx}.function;

    % get the user-specified parameters
    ex.stim{stimidx}.params = rmfield(stimuli{stimidx}, 'function');
    
    % run this stimulus
    eval(['ex = ' ex.stim{stimidx}.function '(ex, false);']);
    
    % intermediate screen btw functions
    if stimidx < length(stimuli)
        %ex = interleavedscreen(ex, stimidx);
    end

  end
  
  % Check for ESC keypress during the experiment
  ex = checkesc(ex)

  % Close windows and textures, clean up
  endexpt();

  if ~debug_exp

    % Save the experimental metadata
    savejson('', ex, fullfile(basedir, 'expt.json'));
    save(fullfile(basedir, 'exlog.mat'), 'ex');

    % Send results via Pushover
    sendexptresults(ex);
    
    % commit and push
    %commitStr = sprintf(':checkered_flag: Finished experiment on %s', datestr(now));
    %evalc(['!git add -A; git commit -am "' commitStr '"; git push;']);
    
  end

% catch errors
catch my_error

  % store the error
  ex.my_error = my_error;
  
  % display the error
  disp(my_error);
  struct2table(rmfield(ex.my_error.stack,'file'))

  % Close windows and textures, clean up
  endexpt();

  % Send results via Pushover
  if ~debug_exp
    %sendexptresults(ex);
  end

end
