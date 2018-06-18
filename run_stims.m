% Script for running stimulus from struct array 'params'.
% 
% How is different from 'runme' or 'runjuyoung'?
%   1. stimuli as struct array, not cell array.
%   2. create today's directory
%
    commandwindow
    %%
    addpath('jsonlab/')
    addpath('utils/')
    addpath('functions/')
    addpath('HelperFunctions/')
    %%
    % turn the `debug` flag on when testing
    debug_exp = false;

    try
      
      % Construct an experimental structure array
      ex = initexptstruct(debug_exp);

      % Initialize the keyboard
      ex = initkb(ex);
      
      % 'params' in workspace
      stimuli = params;
        %stimuli = loadjson(fullfile(basedir, 'config.json'));
      
      % today's directory. Create if it doesn't exist for ex history log.
      basedir = fullfile('logs/', ex.today);
      if exist(basedir,'dir') ==0
          mkdir(basedir);
      end
        
      % bg color
      ex.disp.bgcol = 0; 
      % Initalize the visual display w/ offset position
      ex = initdisp(ex, 1500, -100);

      % wait for trigger
      ex = waitForTrigger(ex);
      
      
      % Run the stimuli
      for stimidx = 1:length(stimuli)

        % get the function name for this stimulus
        ex.stim{stimidx}.function = stimuli(stimidx).function;

        % get the user-specified parameters
        ex.stim{stimidx}.params = rmfield(stimuli(stimidx), 'function');
        
        % run this stimulus
        if strcmp(ex.stim{stimidx}.function, 'naturalmovie2')
            eval(['ex = ' ex.stim{stimidx}.function '(ex, false, movies);']);
        else
            eval(['ex = ' ex.stim{stimidx}.function '(ex, false);']);
        end


        % intermediate screen btw functions
        if stimidx < length(stimuli)
            %ex = interleavedscreen(ex, stimidx);
        end

      end

      % Check for ESC keypress during the experiment
      ex = checkesc(ex) % if ESC pressed, throws MEception. Don't save. 
      
      %
      ex.t_end = datestr(now, 'HH:MM:SS');
      ex.duration_secs = etime(clock, ex.t1);
      
      % Close windows and textures, clean up
      endexpt();

      if ~debug_exp
        if isfield(ex, 'name')
            str_name = ex.name; % FOV name or ex note?
        else
            str_name = '';
        end
          
        % Save the experimental metadata
        savejson('', ex, fullfile(basedir, [datestr(now, 'HH_MM_SS'), '_expt_', str_name,'.json']));
                    save(fullfile(basedir, [datestr(now, 'HH_MM_SS'), '_exlog', str_name,'.mat']), 'ex');

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
      
      %  
      
      
      % Close windows and textures, clean up
      endexpt();

      % Send results via Pushover
      if ~debug_exp
        %sendexptresults(ex);
        save(fullfile(basedir, ['error_', datestr(now, 'HH_MM_SS'), '_exlog.mat']), 'my_error'); % or 'ex'
      end

    end
