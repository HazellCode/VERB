classdef reverb_plugin < audioPlugin
    %VERB
    %   Reverb PLugin - Based on Schroder Reverberator
    %   SID:2105221
    
    properties
        fs = 192000; % Set Sample Rate

        RT60 = 1; % Define RT60

        drywet = 0.8; % Define DryWet
        drywet_log = 0; % Define Drywet as Log

        % COMB FILTERS - LEFT
        Lcf1 = 0; 
        Lcf2 = 0;
        Lcf3 = 0;
        Lcf4 = 0;
        Lcf5 = 0;
        Lcf6 = 0;
        Lcf7 = 0;

        % COMB FILTERS - RIGHT
        Rcf1 = 0; 
        Rcf2 = 0;
        Rcf3 = 0;
        Rcf4 = 0;
        Rcf5 = 0;
        Rcf6 = 0;
        Rcf7 = 0;


        % ALL PASS FILTERS - INPUT
        Lap1 = 0;
        Lap2 = 0;
        
        Rap1 = 0;
        Rap2 = 0;

        % ALL PASS FILTERS - OUTPUT
        Lap3 = 0;
        Lap4 = 0;

        Rap3 = 0;
        Rap4 = 0;

        % TOTAL DELAY COMPENSATION
        Lt_delay = 0;
        Ldel_out = 0;
        Lod_idx = 1;

        Rt_delay = 0;
        Rdel_out = 0;
        Rod_idx = 1;

        total_delay = true; % enable TDC
    end
    properties(Constant)
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('RT60', 'Mapping', {'lin',0,5},'DisplayName', 'RT60', 'Label','s', 'DisplayNameLocation', 'above', 'Layout', [2,2], 'Style','rotaryknob'), ...
            audioPluginParameter('drywet', 'Mapping', {'lin',0,1},'DisplayName', 'Dry/Wet','DisplayNameLocation', 'above', 'Layout', [2,4], 'Style','hslider'), ...
            audioPluginParameter('total_delay', 'DisplayName', 'Total Delay Compensation', 'Style', 'vrocker', 'Layout',[2,6],'DisplayNameLocation', 'above'), ...
            audioPluginGridLayout('RowHeight', [20,130,20], 'ColumnWidth', [20,100,20,100,5,150,20]),...
                'VendorName', 'Hazell Design', 'PluginName', 'VERB', 'VendorVersion', '1.0.1', 'InputChannels',2,'OutputChannels',2);
         % Define UI Elements
    end
    
    methods
        function plugin = reverb_plugin()
             % DEFINE COMB FILTERS - LEFT
            plugin.Lcf1 = COMB(1693, plugin.RT60, plugin.fs); 
            plugin.Lcf2 = COMB(2083, plugin.RT60, plugin.fs);
            plugin.Lcf3 = COMB(1609, plugin.RT60, plugin.fs);
            plugin.Lcf4 = COMB(2089, plugin.RT60, plugin.fs);
            plugin.Lcf5 = COMB(1709, plugin.RT60, plugin.fs);
            plugin.Lcf6 = COMB(1523, plugin.RT60, plugin.fs);
            plugin.Lcf7 = COMB(2287, plugin.RT60, plugin.fs);
                
             % DEFINE COMB FILTERS - RIGHT
            plugin.Rcf1 = COMB(1103, plugin.RT60, plugin.fs);
            plugin.Rcf2 = COMB(1621, plugin.RT60, plugin.fs);
            plugin.Rcf3 = COMB(2063, plugin.RT60, plugin.fs);
            plugin.Rcf4 = COMB(1987, plugin.RT60, plugin.fs);
            plugin.Rcf5 = COMB(1409, plugin.RT60, plugin.fs);
            plugin.Rcf6 = COMB(1709, plugin.RT60, plugin.fs);
            plugin.Rcf7 = COMB(2447, plugin.RT60, plugin.fs);

            % DEFINE ALL PASS FILTERS - INPUT
            plugin.Lap1 = APF(round(0.0025 * plugin.fs),0.5);
            plugin.Lap2 = APF(round(0.0014 * plugin.fs),0.5);

            
            plugin.Rap1 = APF(round(0.0036 * plugin.fs),0.5);
            plugin.Rap2 = APF(round(0.0005 * plugin.fs),0.5);
    
            % DEFINE ALL PASS FILTERS - OUTPUT
            plugin.Lap3 = APF(round(0.005 * plugin.fs), 0.5);
            plugin.Lap4 = APF(round(0.004 * plugin.fs), 0.5);
    
            plugin.Rap3 = APF(round(0.009 * plugin.fs), 0.5);
            plugin.Rap4 = APF(round(0.005 * plugin.fs), 0.5);
        end
        function out = process(plugin, in)
            % Get buffer length
            [N,M] = size(in);
            % Define output array
            out = zeros(N,M);
            % Buffer time loop
            for n = 1:N
                % LEFT
                % Calculate input APF (APF1 -> APF2)
                plugin.Lap1.calc(in(n,1));
                plugin.Lap2.calc(plugin.Lap1.read);
                
                % get output of APF2
                Lcomb_in = plugin.Lap2.read;
                % Read Comb Filters and store value
                Lcomb_out = plugin.Lcf1.read() + plugin.Lcf2.read() + plugin.Lcf3.read() + plugin.Lcf4.read() + plugin.Lcf5.read() + plugin.Lcf6.read() + plugin.Lcf7.read();
                
                % Calculate Comb Filters
                plugin.Lcf1.calc(Lcomb_in);
                plugin.Lcf2.calc(Lcomb_in);
                plugin.Lcf3.calc(Lcomb_in);
                plugin.Lcf4.calc(Lcomb_in);
                plugin.Lcf5.calc(Lcomb_in);
                plugin.Lcf6.calc(Lcomb_in);
                plugin.Lcf7.calc(Lcomb_in);

                % Using output of comb filters calculate (APF3 -> APF4)
                plugin.Lap3.calc(Lcomb_out);
                plugin.Lap4.calc(plugin.Lap3.read());

                %% LEFT INCREMENTORS
                % INC APF1,2
                plugin.Lap1.inc; 
                plugin.Lap2.inc;
                % INC COMB1,2,3,4,5,6,7
                plugin.Lcf1.inc;
                plugin.Lcf2.inc;
                plugin.Lcf3.inc;
                plugin.Lcf4.inc;
                plugin.Lcf5.inc;
                plugin.Lcf6.inc;
                plugin.Lcf7.inc;
                % INC APF3,4
                plugin.Lap3.inc;
                plugin.Lap4.inc;


                % RIGHT
                % Calculate Input APF (APF1 -> APF2)
                plugin.Rap1.calc(in(n,2));
                plugin.Rap2.calc(plugin.Rap1.read());
                
                % egt output of APF2
                Rcomb_in = plugin.Rap2.read();
                % Read Comb Filters and store value
                Rcomb_out = plugin.Rcf1.read() + plugin.Rcf2.read() + plugin.Rcf3.read() + plugin.Rcf4.read() + plugin.Rcf4.read() + plugin.Rcf5.read() + plugin.Rcf6.read() + plugin.Rcf7.read();

                % Calculate Comb Filters
                plugin.Rcf1.calc(Rcomb_in);
                plugin.Rcf2.calc(Rcomb_in);
                plugin.Rcf3.calc(Rcomb_in);
                plugin.Rcf4.calc(Rcomb_in);
                plugin.Rcf5.calc(Rcomb_in);
                plugin.Rcf6.calc(Rcomb_in);
                plugin.Rcf7.calc(Rcomb_in);

                % using output of comb filters calculate (APF3 -> APF4)
                plugin.Rap3.calc(Rcomb_out);
                plugin.Rap4.calc(plugin.Rap3.read());

                %% RIGHT INCREMENTORS
                %INC APF1,2
                plugin.Rap1.inc; 
                plugin.Rap2.inc;
                %INC COMB1,2,3,4,5,6,7
                plugin.Rcf1.inc; 
                plugin.Rcf2.inc; 
                plugin.Rcf3.inc; 
                plugin.Rcf4.inc; 
                plugin.Rcf5.inc;
                plugin.Rcf6.inc;
                plugin.Rcf7.inc;
                %INC APF3,4
                plugin.Rap3.inc;
                plugin.Rap4.inc;

                %% OUTPUT 
                if (plugin.total_delay) % - total_delay = enabled
                    out(n,1) = ((plugin.Ldel_out(plugin.Lod_idx) * (1-plugin.drywet_log)) + (plugin.Lap4.read * plugin.drywet_log)) * 0.5;
                    out(n,2) = ((plugin.Rdel_out(plugin.Rod_idx) * (1-plugin.drywet_log)) + (plugin.Rap4.read * plugin.drywet_log)) * 0.5;
                else % - total_delay = disabled
                    out(n,1) = ((in(n,1) * (1-plugin.drywet_log)) + (plugin.Lap4.read * plugin.drywet_log)) * 0.5;
                    out(n,2) = ((in(n,2) * (1-plugin.drywet_log)) + (plugin.Rap4.read * plugin.drywet_log)) * 0.5;
                end
                % Write input to TDC delay line 
                plugin.Ldel_out(plugin.Lod_idx) = in(n,1);
                plugin.Rdel_out(plugin.Rod_idx) = in(n,2);
                
                % TDC INCREMENTORS
                %LEFT
                plugin.Lod_idx = plugin.Lod_idx + 1;
                
                if plugin.Lod_idx > plugin.Lt_delay
                    plugin.Lod_idx = 1;
                end
                %RIGHT
                plugin.Rod_idx = plugin.Rod_idx + 1;
                if plugin.Rod_idx > plugin.Rt_delay
                    plugin.Rod_idx = 1;
                end
            end
        end
        % SET DRYWET
        function set.drywet(plugin, val)
            plugin.drywet = val;
            % Calculate drywet as log
            plugin.drywet_log = (.001*10^(3*plugin.drywet));
        end

        function set.RT60(plugin, val)
            % WHEN RT60 IS UPDATED THE COMB FILTERS NEED TO BE UPDATED
            plugin.RT60 = val;
            plugin.Lcf1.update_RT60(val)
            plugin.Lcf2.update_RT60(val)
            plugin.Lcf3.update_RT60(val)
            plugin.Lcf4.update_RT60(val)
            plugin.Lcf5.update_RT60(val)
            plugin.Lcf6.update_RT60(val)
            plugin.Lcf7.update_RT60(val)

            plugin.Rcf1.update_RT60(val)
            plugin.Rcf2.update_RT60(val)
            plugin.Rcf3.update_RT60(val)
            plugin.Rcf4.update_RT60(val)
            plugin.Rcf5.update_RT60(val)
            plugin.Rcf6.update_RT60(val)
            plugin.Rcf7.update_RT60(val)

            % RECALCULATE TDC

            plugin.Lt_delay = round((plugin.Lcf1.get_del + plugin.Lcf2.get_del + plugin.Lcf3.get_del + plugin.Lcf4.get_del + plugin.Lcf5.get_del + plugin.Lcf6.get_del + plugin.Lcf7.get_del)/7 + plugin.Lap1.get_del + plugin.Lap2.get_del + plugin.Lap3.get_del + plugin.Lap4.get_del);
            plugin.Rt_delay = round((plugin.Rcf1.get_del + plugin.Rcf2.get_del + plugin.Rcf3.get_del + plugin.Rcf4.get_del + plugin.Rcf5.get_del + plugin.Rcf6.get_del + plugin.Rcf7.get_del) / 7 + plugin.Rap1.get_del + plugin.Rap2.get_del + plugin.Rap3.get_del + plugin.Rap4.get_del);

        end

        function reset(plugin)
            plugin.fs = plugin.getSampleRate;
            plugin.drywet_log = (.001*10^(3*plugin.drywet));
            % THE FILTERS HAVE TO BE INITALISED HERE AS MATLAB DOESN'T
            % ALLOW FOR VARIABLES TO BE INITALISED AS A CLASS IN THE
            % PROPERTIES SECTION
            
            plugin.Lcf1.update(plugin.RT60, plugin.fs);
            plugin.Lcf2.update(plugin.RT60, plugin.fs);
            plugin.Lcf3.update(plugin.RT60, plugin.fs);
            plugin.Lcf4.update(plugin.RT60, plugin.fs);
            plugin.Lcf5.update(plugin.RT60, plugin.fs);
            plugin.Lcf6.update(plugin.RT60, plugin.fs);
            plugin.Lcf7.update(plugin.RT60, plugin.fs);

            plugin.Rcf1.update(plugin.RT60, plugin.fs);
            plugin.Rcf2.update(plugin.RT60, plugin.fs);
            plugin.Rcf3.update(plugin.RT60, plugin.fs);
            plugin.Rcf4.update(plugin.RT60, plugin.fs);
            plugin.Rcf5.update(plugin.RT60, plugin.fs);
            plugin.Rcf6.update(plugin.RT60, plugin.fs);
            plugin.Rcf7.update(plugin.RT60, plugin.fs);

        
           


            %% TOTAL DELAY
            % CALCULATE TDC LEFT
            plugin.Lt_delay = round((plugin.Lcf1.get_del + plugin.Lcf2.get_del + plugin.Lcf3.get_del + plugin.Lcf4.get_del + plugin.Lcf5.get_del + plugin.Lcf6.get_del + plugin.Lcf7.get_del)/7 ...
                + plugin.Lap1.get_del + plugin.Lap2.get_del ...
                + plugin.Lap3.get_del + plugin.Lap4.get_del);
            % DEFINE LEFT TDC DELAY LINE
            plugin.Ldel_out = zeros(plugin.Lt_delay,1);
            % RESET LEFT TDC INDEX
            plugin.Lod_idx = 1;

            % CALCULATE TDC RIGHT
            plugin.Rt_delay = round((plugin.Rcf1.get_del + plugin.Rcf2.get_del + plugin.Rcf3.get_del + plugin.Rcf4.get_del + plugin.Rcf5.get_del + plugin.Rcf6.get_del + plugin.Rcf7.get_del) / 7 ...
                + plugin.Rap1.get_del + plugin.Rap2.get_del ...
                + plugin.Rap3.get_del + plugin.Rap4.get_del);
            % DEFINE RIGHT TDC DELAY LINE
            plugin.Rdel_out = zeros(plugin.Rt_delay,1);
            % RESET RIGHT TDC INDEX
            plugin.Rod_idx = 1;
        end
    end
end

