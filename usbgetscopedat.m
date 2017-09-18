function [data, t] = usbgetscopedat(deviceId, Channel)
%--------------------------------------------------------------------------
% MATLAB script for obtaining data from Agilent oscilloscopes
% Based on code dated 2/21/11 by Christopher Tilley, Philip Mease
% Modified 9/15/17 by Nicholas DeCicco
%--------------------------------------------------------------------------
%
% This function will access the oscilloscope that is located at VISA address
% 'deviceId' and obtain data from channel 'Channel'.  The vector of amplitudes
% will be saved to the variable 'data', and the time vector will be saved to
% 't'. 
%
% The following are the acceptable syntax for this function:
%
%
%       [data, t] = getscopedat(deviceId)
%
%           This syntax uses the default channel 1 of the scope at VISA
%           address 'deviceId'.
%
%
%       [data, t] = getscopedat(GPIB, Channel)
%
%           This syntax uses the channel 'Channel' of the scope at VISA
%           address 'deviceId'.
%
% Note that 'Channel' is a string such as 'CHAN1', 'CHAN2', etc.; this is to
% permit also accessing MATH functions on the oscilliscope. If, for example,
% MATH1 is displaying an FFT of a channel, you can pass 'FUNC1' for 'Channel'.
%--------------------------------------------------------------------------

    open = instrfind('Status', 'open');
    if ~isempty(open)
        fclose(open);
    end

    dev = visa('agilent', deviceId);
    fopen(dev);

    %Determine number of inputs provided by user
    if nargin > 2
        error(['Invalid Number of Arguments for getscopedat(). ', ...
               'Please type help getscopedat for for proper syntax!']);
    elseif nargin < 2
        Channel = 'CHAN1';
    elseif nargin < 1
        error(['Invalid Number of Arguments for getscopedat(). ', ...
               'Must enter the GPIB Address of the Scope!']);
    end

    % Check memory:
    % DSO1012A have a model id of 0x0588:
    % USB0::0x0957::0x0588::CN50382775::0::INSTR
    deviceIdParts = strsplit(deviceId,':');
    if strcmp(deviceIdParts{3},'0x0588')
        memdepth = str2double(query(dev,':WAVeform:POINts?'));
    else
        memdepth = str2double(query(dev,':ACQuire:POINts?'));
    end
    disp(['Acquiring ', num2str(memdepth), ' points.']);
    
    if (memdepth >= dev.InputBufferSize)
        disp('Increasing insufficient input buffer size.');
        fclose(dev);
        dev.InputBufferSize = memdepth+1;
        fopen(dev);
    end

    %Set the Source of the Scope
    fprintf(dev, [':WAVEFORM:SOURCE ', Channel]);

    %Acquire X origin and X increment values
    xorg = str2double(query(dev, ':WAVEFORM:XOR?'));
    xinc = str2double(query(dev, ':WAVEFORM:XINC?'));

    %Acquire Y origin and Y increment Values
    yorg = str2double(query(dev, ':WAVEFORM:YOR?'));
    yinc = str2double(query(dev, ':WAVEFORM:YINC?'));
    yref = str2double(query(dev, ':WAVEFORM:YREF?'));

    %Setup the Scope for proper output format
    fprintf(dev, 'WAVEFORM:FORMAT BYTE');
    fprintf(dev, 'ACQUIRE:TYPE NORM');

    %Instruct the scope to make current data available to acquire
    fprintf(dev, 'WAVEFORM:DATA?');
    data1 = binblockread(dev, 'uint8');
    
    %Create a time variable with the same lenght as "data"
    t1 = 0:(length(data1)-1);

    %Adjust data and time variables with x/y increments/origins
    t = t1 * xinc + xorg;
    data = (data1-yref) * yinc + yorg;
    
    fclose(dev);
end

