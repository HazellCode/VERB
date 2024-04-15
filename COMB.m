 %
%
%  FileName: COMB.m
%  Date: 11-Feb-2024
%  Author: SID 2105221
%  Description: COMB FIlters
%  
%
%
classdef COMB < handle
    properties
        sdel = 0; % Sample Delay
        ddl = 0; % Delay Line
        idx = 1; % index
        g = 0; % G value
        RT60 = 0; % RT60
        fs = 0; % Sample Rate
    end
    methods(Access = private)

    end
    methods(Access = public)
        function obj = COMB(sample_delay, RT60, fs)
               obj.sdel = sample_delay; % Set Sample Delay 
               obj.RT60 = RT60; % Set RT60
               obj.fs = fs; % Set Sample rate
               obj.ddl = zeros(obj.sdel, 1); % Define Delay Line
               obj.g = 10 ^ ((-3 * length(obj.ddl)) / (obj.RT60*obj.fs)); % Define G Value
        end
        function out = calc(obj,in)
            obj.ddl(obj.idx) = in + (obj.g * obj.ddl(obj.idx)); % calculate Comb Filter
        end
        function inc(obj)
            % Increment Index
            obj.idx = obj.idx + 1;
            if obj.idx > obj.sdel
                obj.idx = 1;
            end
        end
        function out = read(obj)
            % Return comb filter output
            out = obj.ddl(obj.idx);
        end
        function out = get_del(obj)
            % get sample delay
            out = obj.sdel;
        end
        function update_RT60(obj, RT60)
            % update g with new rt60
            obj.g = 10 ^ ((-3 * length(obj.ddl)) / (RT60*obj.fs));
        end

        function update(obj, RT60, fs)
            % update fs
            obj.fs = fs;
            % update G with new RT60
            obj.g = 10 ^ ((-3 * length(obj.ddl)) / (RT60*obj.fs));
        end
        
        
    end
end