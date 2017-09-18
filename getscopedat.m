function [data, t] = getscopedat(GPIB, Channel)
%--------------------------------------------------------------------------
% MATLAB Driver for Inif(i)ium Scopes
% Last Update: 2.21.11
% Christopher Tilley, Philip Mease
%--------------------------------------------------------------------------
%
% This function will access the oscilloscope that is located at GPIB
% address 'GPIB(1,1)' and board index 'GPIB(1,2)' and plot the current wave
% form being displayed on channel 'Channel'.  The vector of amplitudes will
% be saved to the variable 'data', and the time vector will be saved to
% 't'. 
%
% GPIB can be sent in two forms.  If 'GPIB' is a single value variable then
% the function will interpuret 'GPIB' as the GPIB address of the scope and
% use the default board index of 8.  If the user wishes to designate the
% board index for the GPIB board in the computer they are using then 'GPIB'
% must be saved as a 1x2 vector, where 'GPIB(1,1)' is the GPIB address of
% the instrument and 'GPIB(1,2)' is the board index of the GPIB adapter in
% the computer.  This board index can be found by opening the Agilent
% Control Panel in Windows.
% 
% The following are the acceptable syntax for this function:
%
%
%       [data, t] = getscopedat(GPIB)
%
%           This syntax uses the default channel 1 of the scope at GPIB
%           address 'GPIB(1,1)' and board index 'GPIB(1,2)'
%           eg (bi = 8, gpibaddY = 7): [d t] = getscopedat([7 8])
%
%
%       [data, t] = getscopedat(GPIB, Channel)
%
%           This syntax uses the channel 'Channel' of the scope at GPIB
%           address 'GPIB(1,1)' and board index 'GPIB(1,2)'.
%--------------------------------------------------------------------------


    %Determine number of inputs provided by user
    if nargin > 2, error('Invalid Number of Arguments for viewscope().  Please type help getscopedat for for proper syntax!'); end
    if nargin < 2, Channel = 1; end
    if nargin < 1, error('Invalid Number of Arguments for viewscope().  Must enter the GPIB Address of the Scope!'); end

    %Create a variable name for the scope object
    if (length(GPIB) > 1)
        board = num2str(GPIB(1,2));
        name = ['obj', num2str(GPIB(1,1))];
        obj_name = genvarname(name);
    else
        board = '8';
        name = ['obj', num2str(GPIB)];
        obj_name = genvarname(name);
    end

    % Create a GPIB object:
    eval([obj_name, ' = instrfind(','''Type''', ',', '''gpib''', ',', '''BoardIndex''', ',', '''', board, '''', ',', '''PrimaryAddress''', ',', num2str(GPIB(1,1)), ',', '''Tag''', ',', '''''', ');'])

    % Create the GPIB object if it does not exist
    % otherwise use the object that was found.
    if isempty(eval(obj_name))
        eval([obj_name, ' = gpib(', '''AGILENT''', ', ', board, ', ', num2str(GPIB(1,1)), ');']);
    else
        fclose(eval(obj_name));
        eval([obj_name, ' = ', obj_name, '(1)'])
    end

    %Set the Input Buffer size:
    % NOTE: this is arbitrary until we check.  But you cannot set this
    % while the object is open... can only be set with objs closed.
    ibs = 2100100;
    set(eval(obj_name), 'InputBufferSize', ibs);
    
    % POINts sets req memory depth
    % WAVeform:POINts?
    % WAVeform:PREamble? query for 
    % :ACQuire:POINts? returns val of mem depth ctrl
    % :ACQuire:SRATe? returns current acquisition sa rate

    %Open Scope
    fopen(eval(obj_name));

    % Check memory:
    memdepth = str2double(query(eval(obj_name),':ACQuire:POINts?'));
    str = ['You are acquiring ', num2str(memdepth), ' points.']
    
    if (memdepth >= ibs)
        disp('READ MEMORY BUFFER TOO SMALL, WAIT WHILE WE INCREASE IT');
        ibs = memdepth + 1;  % update ibs to fit aquired data
        open = instrfind('Status', 'open');
        fclose(open);
        set(eval(obj_name), 'InputBufferSize', ibs);
        fopen(eval(obj_name));  % Reopen the object now buffer is set correctly
    end

    %Set the Source of the Scope
    %fprintf(eval(obj_name), ':ACQ:SRAT 500 E+4');
    cha = [':WAVEFORM:SOURCE CHAN', num2str(Channel)];
    fprintf(eval(obj_name), cha);

    %Acquire X origin and X increment values
    xorg = str2double(query(eval(obj_name),':WAVEFORM:XOR?'));
    xinc = str2double(query(eval(obj_name),':WAVEFORM:XINC?'));

    %Acquire Y origin and Y increment Values
    yorg = str2double(query(eval(obj_name),':WAVEFORM:YOR?'));
    yinc = str2double(query(eval(obj_name),':WAVEFORM:YINC?'));

    %Setup the Scope for proper output format
    fprintf(eval(obj_name), 'WAVEFORM:FORMAT BYTE');
    fprintf(eval(obj_name), 'ACQUIRE:TYPE NORM');

    
    %Instruct the scope to make current data available to acquire
    fprintf(eval(obj_name), 'WAVEFORM:DATA?');
    data1 = binblockread(eval(obj_name), 'int8');
    
    %Create a time variable with the same lenght as "data"
    t1 = 0:(length(data1)-1);

    %Adjust data and time variables with x/y increments/origins
    t = t1 * xinc + xorg;
    data = data1 * yinc + yorg;

    plot(t,data);
    
    open = instrfind('Status', 'open');
    fclose(open);

end

