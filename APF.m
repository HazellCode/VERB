%
%
%  FileName: APF.m
%  Date: 11-Feb-2024
%  Author: SID 2105221
%  Description: ALL PASS
%  
%
%
classdef APF < handle
    properties
        sdel = 0; % Sample delay
        ddl = 0; % delay line
        idx = 1; % index
        g = 0; % g value
        apf_out = 0; % all pass output
        temp_in = 0; % temporary storage value
    end
    methods(Access = private)

    end
    methods(Access = public)
        function obj = APF(sample_delay, g)
               obj.sdel = sample_delay; % set sample delay
               obj.ddl = zeros(obj.sdel, 1); % define delay line
               obj.g = g; % set g
        end
        function out = calc(obj,in)
            % Calculate all pass filter
            obj.temp_in = in + (obj.ddl(obj.idx) * obj.g);
            obj.apf_out = (obj.temp_in * -obj.g) + obj.ddl(obj.idx);
            obj.ddl(obj.idx) = obj.temp_in;
            out = obj.apf_out;
        end
        
        function inc(obj)
            % Increment index
            obj.idx = obj.idx + 1;
            if obj.idx > obj.sdel
                obj.idx = 1;
            end
        end
        % GETTERS
        function out = get_del(obj)
            % return sample delay
            out = obj.sdel;
        end
        function out = read(obj)
            % return all pass output 
            out = obj.apf_out;
        end
        function out = get_idx(obj)
            % return index
            out = obj.idx;
        end

        function update(obj, sdel)
            % Update sample delay and thus delay line
            obj.sdel = sdel;
            obj.ddl = zeros(obj.sdel, 1);
            obj.idx = 1;
        end 
    end
end