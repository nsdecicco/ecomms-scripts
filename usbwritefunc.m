function usbwritefunc(ADDR, DATA, AMP, FRQ, OFFSET, TERM)

%--------------------------------------------------------------------------
% Updated: 9/15/17
% Updated: 1.23.09
% This function will write the waveform stored in the vector Data to the
% device located at the VISA address 'ADDR'.  The waveform will be set
% the an Amplitude of 'AMP', a frequency of 'FRQ', and an offset of
% 'OFFSET'.  The vector 'DATA' must be normalized to range between the
% values -1 to 1.  This program will only work with Agilent
% technology at the moment.
%
% The Amplitude can range from 12.5mV to 10V (peak to peak).
% Depending on the wave contained in 'DATA', the function generator will
% adjust the maximum amplitude that can be used.
%
% In order to achieve the proper waveform, the vector that is specified by
% 'DATA' should represent the amplitudes of the wave for ONE period.  If
% the wave is not periodic the vector should represent the amplitudes from
% the begining of the wave to the end of the wave.  The function generator
% will then repeat this wave (essentially making the wave periodic).
% Another point to consider, if you start your time interval at 0 and have
% your end point at the first period of your wave, you are effectively
% adding one to many points to the vector 'DATA' which will be visably
% noticable when constructing waves with a low number of data points, but
% will not be able to be noticed when using a high number of data points.
% Although you can not see this inperfection in your wave, it will throw
% off any data collected by the oscilloscope or other data collection
% tools.  In order to avoid this problem, simply subtract the last point
% off your time interval vector before solving your wave vector.  For
% example:
%
%       If my wave has a period of 2 seconds, T1 = 2, and I want to
%       construct a time vector with 8000 points my time vector would
%       originally look like this:
%              
%           t = [0:2/8000:2]';          {WRONG FOR THIS PROGRAM}
%
%       This will result in that extra time step being incorporated into
%       your 'DATA' vector.  To avoid it simply change your time vector to
%       the following:
%
%           t = [0:2/8000:2-(2/8000)]'; {CORRECT FOR THIS PROGRAM}
%
%The following are the correct versions of the syntax that can be used with
%'writefunc':
%
%
%       writefunc(ADDR, DATA)
%
%           This syntax will output the data to the device located at VISA
%           address 'ADDR'.  The vector 'DATA' must be normalized to be
%           in the range of -1 to 1.  If it is not, an error will be
%           reported.  The following will be used as default settings for
%           the other inputs:  Amplitude: 1 Vpp, Frequency: 1 kHz, Offset:
%           0 Vpp.  The output termination is set to the default value of
%           50 Ohms.
%
%
%       writefunc(ADDR, DATA, AMP)
%
%           This syntax will output the data to the device located at VISA
%           address 'ADDR'.  The amplitude of the wave will be set to
%           'AMP'.  This is a peak to peak value, which means if 'AMP' =
%           10, then Vmax = 5 Volts and Vmin = -5 Volts.  The vector 'DATA'
%           must be normalized to be in the range of -1 to 1.  If it is
%           not, an error will be reported.  The following defaults will be
%           used for the other inputs:  Frequency: 1 kHz, Offset: 0 Vpp.
%
%
%       writefunc(ADDR, DATA, AMP, FRQ)
%
%           This syntax will output the data to the device located at VISA
%           address 'ADDR'.  The amplitude of the wave will be set to
%           'AMP'.  This is a peak to peak value, which means if 'AMP' =
%           10, then Vmax = 5 Volts and Vmin = -5 Volts.  The vector 'DATA'
%           must be normalized to be in the range of -1 to 1.  If it is
%           not, an error will be reported.  The frequency of the wave will
%           be set to the value 'FRQ'.  The following will be used as a
%           default for the offset: 0 Vpp.
%
%
%       writefunc(ADDR, DATA, AMP, FRQ, OFFSET)
%
%           This syntax will output the data to the device located at VISA
%           address 'ADDR'.  The amplitude of the wave will be set to
%           'AMP'.  This is a peak to peak value, which means if 'AMP' =
%           10, then Vmax = 5 Volts and Vmin = -5 Volts.  The vector 'DATA'
%           must be normalized to be in the range of -1 to 1.  If it is
%           not, an error will be reported.  The frequency of the wave will
%           be set to the value 'FRQ' and with an offset of 'OFFSET'.
%
%
%       writefunc(ADDR, DATA, AMP, FRQ, OFFSET, TERM)
%
%           This syntax does the same as the above, but allows the user to
%           set the output termination of the function generator.  There
%           are only 2 valid entries for this 50 or INF (case does matter).
%
%
%
%
%   If the value of 'DATA' is one of the following:
%       SIN, TRI, SQU, or RAMP
%   Then the program will switch the function generators output to the
%   specified wave type.  The amplitude, frequency and offset will be set
%   according to the inputs of the function unless not specified, which
%   will result in the default settings listed above.
%--------------------------------------------------------------------------

    %Determine the number of arguments sent to the function and set the missing
    %values to their default settings.
    if nargin < 6, TERM = 50; end
    if nargin < 5, OFFSET = 0; end
    if nargin < 4, FRQ = 1000; end
    if nargin < 3, AMP = 1; end
    

    if nargin < 2, error('Incorrect Syntax.  Must have at least 2 arguments for function to be proper'); end
    if nargin > 6, error('Incorrect Syntax.  Must have 5 or fewer arguments'); end
    %--------------------------------------------------------------------------


    %--------------------------------------------------------------------------
    
    
    open = instrfind('Status', 'open');
    if ~isempty(open)
        fclose(open);
    end
    
    dev = visa('agilent', ADDR);

    set(dev, 'OutputBufferSize', 1048576);
    set(dev, 'Timeout', 120);

    fopen(dev);

    %--------------------------------------------------------------------------


    %--------------------------------------------------------------------------
    % Manipulate the inputs to prepare them to be sent to the Function
    % Generator.

    if ischar(DATA)
        DATA = upper(DATA);
        if (strncmp(DATA, 'SIN', 3))
            %Changes the output of the Function Generator to a Sine wave with the
            %characteristics supplied by the user (or defaults if none are sent to
            %function.
            output = ['APPL:SIN ', num2str(FRQ), ',', num2str(AMP), ',', num2str(OFFSET)];
            fprintf(dev, output);
        elseif (strncmp(DATA, 'SQU', 3))
            %Changes the output of the Function Generator to a Square wave with the
            %characteristics supplied by the user (or defaults if none are sent to
            %function.
            output = ['APPL:SQU ', num2str(FRQ), ',', num2str(AMP), ',', num2str(OFFSET)];
            fprintf(dev, output);
        elseif (strncmp(DATA, 'TRI', 3))
            %Changes the output of the Function Generator to a Triangle wave with the
            %characteristics supplied by the user (or defaults if none are sent to
            %function.
            output = ['APPL:TRI ', num2str(FRQ), ',', num2str(AMP), ',', num2str(OFFSET)];
            fprintf(dev, output);
        elseif (strncmp(DATA, 'RAMP', 4))
            %Changes the output of the Function Generator to a Ramp wave with the
            %characteristics supplied by the user (or defaults if none are sent to
            %function.
            output = ['APPL:RAMP ', num2str(FRQ), ',', num2str(AMP), ',', num2str(OFFSET)];
            fprintf(dev, output);
        else
            error('Incorrect String value for DATA.  Options are SIN, SQU, RAMP or TRI');
        end
    else
        % Create a string using inputed vector.  Each field will be seperated 
        % with a comma followed by a white space.
        mstring = '';
        for i=1:length(DATA)
            string = num2str(DATA(i));
            mstring = [mstring, ', ', string];
        end

        %Concatinates the command word onto the string of values
        output = ['DATA VOLATILE', mstring];

        %Put Function Generator in proper Mode
        % is this the 33210A? setting up an arb is different on this model.
        if 1
            fprintf(dev, 'FUNC:USER VOLATILE');
        else
            fprintf(dev, 'FUNC:SHAP USER');
        end

        % Write data to volatile memory in function generator:
        disp('Please wait, this might take up to 1.5 minutes!!!');
        fprintf(dev, output);

        % Make function generator output waveform in volatile memory:
        fprintf(dev, 'FUNC:USER VOLATILE');

        % Set the Amplitude of the wave to the specified amount
        amp = ['VOLT ', num2str(AMP)];
        fprintf(dev, amp);

        % Set the Frequency of the wave to the specified amount
        freq = ['FREQ ', num2str(FRQ)];
        fprintf(dev, freq);

        % Set the Offset of the wave to the specified amount
        off = ['VOLT:OFFS ', num2str(OFFSET)];
        fprintf(dev, off);
    end
    
    if (ischar(TERM))
        TERM = upper(TERM);
        if (strcmp(TERM, 'INF'))
            load = ['OUTP:LOAD ', TERM];
            fprintf(dev, load);
        else
            error('Incorrect value for output Termination.  Must be either 50 or INFinity');
        end
    else
        if (TERM == 50)
            fprintf(dev, 'OUTP:LOAD 50');
        else
            error('Incorrect value for output Termination.  Must be either 50 or INFinity');
        end
    end

    fclose(dev);

end