%% initialization
if ~exist('data','var')
    toso2021_wrapper;
end

%% construct Si-aligned, Ti- & Ii-split psths
ti_padd = [-500,0];
action_padd = [-1,1] * 450;

% iterate through neurons
for nn = 1 : n_neurons
    progressreport(nn,n_neurons,'parsing neural data');
    neuron_flags = data.NeuronNumb == flagged_neurons(nn);
    
    % figure initialization
    fig = figure(figopt,...
        'windowstate','maximized',...
        'name',sprintf('neuron_%i',nn));
    n_rows = 3;
    n_cols = 3;
    n_sps = (n_rows - 1) * n_cols;
    sps = gobjects(n_sps,1);
    for ii = 1 : n_cols
        sps(ii) = subplot(n_rows,n_cols,ii);
        sps(ii+n_cols) = subplot(n_rows,n_cols,[1,2]*n_cols+ii);
    end
    xxtick = unique([ti_padd(1);-pre_t1_delay;0;t_set;t_set(end)+ti_padd(2)]);
    xxticklabel = num2cell(xxtick);
    xxticklabel(xxtick > 0 & xxtick < 1e3) = {''};
    set(sps,...
        axesopt.default,...
        'layer','top',...
        'plotboxaspectratiomode','auto',...
        'xlim',[0,max(t_set)]+ti_padd,...
        'xtick',xxtick,...
        'xticklabel',xxticklabel);
    xxtick = unique([0,action_padd,-500]);
    xxticklabel = num2cell(xxtick);
    set(sps([3,6]),...
        'xlim',[xxtick(1),xxtick(end)],...
        'xtick',xxtick,...
        'xticklabel',xxticklabel);
    xlabel(sps(1+n_cols),'Time since T_1 onset (s)');
    xlabel(sps(2+n_cols),'Time since T_2 onset (s)');
    xlabel(sps(3+n_cols),'Time since go cue (s)');
    ylabel(sps(1),'Firing rate (Hz)');
    ylabel(sps(2),'Firing rate (Hz)');
    ylabel(sps(3),'Firing rate (Hz)');
    ylabel(sps(1+n_cols),'Trial #');
    ylabel(sps(2+n_cols),'Trial #');
    ylabel(sps(3+n_cols),'Trial #');
    
    % preallocation
    s1_n_trial_counter = 0;
    s2_n_trial_counter = 0;
    go_n_trial_counter = 0;
    
    % iterate through intensities
    for ii = 1 : n_i
        i1_flags = i1 == i_set(ii);
        i2_flags = i2 == i_set(ii);
        s1_spike_flags = ...
            valid_flags & ...
            neuron_flags & ...
            i1_flags;
        s2_spike_flags = ...
            valid_flags & ...
            neuron_flags & ...
            i2_flags;
        if (sum(s1_spike_flags) == 0) || ...
                (sum(s2_spike_flags) == 0)
            continue;
        end
        
        % fetch spike counts & compute spike rates
        s1_spike_counts = data.FR(s1_spike_flags,:);
        s2_spike_counts = data.FR(s2_spike_flags,:);
        s1_spike_rates = conv2(...
            1,kernel.pdf,s1_spike_counts,'valid')' / psthbin * 1e3;
        s2_spike_rates = conv2(...
            1,kernel.pdf,s2_spike_counts,'valid')' / psthbin * 1e3;
        s1_n_trials = size(s1_spike_counts,1);
        s2_n_trials = size(s2_spike_counts,1);
        
        % T1-aligned spike rates
        s1_alignment_onset = ...
            pre_init_padding + ...
            pre_t1_delay(s1_spike_flags);
        s1_alignment_flags = ...
            valid_time >= s1_alignment_onset + ti_padd(1) & ...
            valid_time < s1_alignment_onset + t1(s1_spike_flags);
        s1_chunk_flags = ...
            valid_time >= s1_alignment_onset + ti_padd(1)& ...
            valid_time < s1_alignment_onset + max(t1_set) + ti_padd(2);
        s1_spkrates = s1_spike_rates;
        s1_spkrates(~s1_alignment_flags') = nan;
        s1_spkrates = reshape(...
            s1_spkrates(s1_chunk_flags'),[n_tbins+range(ti_padd),s1_n_trials])';
        
        % T2-aligned spike rates
        s2_alignment_onset = ...
            pre_init_padding + ...
            pre_t1_delay(s2_spike_flags) + ...
            t1(s2_spike_flags) + ...
            inter_t1t2_delay;
        s2_alignment_flags = ...
            valid_time >= s2_alignment_onset + ti_padd(1) & ...
            valid_time < s2_alignment_onset + t2(s2_spike_flags);
        s2_chunk_flags = ...
            valid_time >= s2_alignment_onset + ti_padd(1) & ...
            valid_time < s2_alignment_onset + max(t2_set) + ti_padd(2);
        s2_spkrates = s2_spike_rates;
        s2_spkrates(~s2_alignment_flags') = nan;
        s2_spkrates = reshape(...
            s2_spkrates(s2_chunk_flags'),[n_tbins+range(ti_padd),s2_n_trials])';
        
        % flag current stimulus period
        time2plot = ti_padd(1) + psthbin : psthbin : max(t_set) + ti_padd(2);
        time_flags = time2plot <= t_set(tt) + ti_padd(2);
        onset_flags = time2plot <= 0 & ...
            [time2plot(2:end),nan] > 0;
        offset_flags = time2plot < t_set(tt) & ...
            [time2plot(2:end),nan] >= t_set(tt);
        flagged_time = time2plot(time_flags);
        
        % compute mean spike density function
        s1_mu = nanmean(s1_spkrates(:,time_flags),1);
        s1_std = nanstd(s1_spkrates(:,time_flags),0,1);
        s1_sem = s1_std ./ sqrt(sum(~isnan(s1_spkrates),1));
        s2_mu = nanmean(s2_spkrates(:,time_flags),1);
        s2_std = nanstd(s2_spkrates(:,time_flags),0,1);
        s2_sem = s2_std ./ sqrt(sum(~isnan(s2_spkrates),1));
        
        % patch s.e.m.
        xpatch = [flagged_time,fliplr(flagged_time)];
        s1_ypatch = [s1_mu-s1_sem,fliplr(s1_mu+s1_sem)];
        s2_ypatch = [s2_mu-s2_sem,fliplr(s2_mu+s2_sem)];
        patch(sps(1),xpatch,s1_ypatch,i1_clrs(ii,:),...
            'facealpha',.25,...
            'edgecolor','none');
        patch(sps(2),xpatch,s2_ypatch,i2_clrs(ii,:),...
            'facealpha',.25,...
            'edgecolor','none');
        
        % plot average activity
        plot(sps(1),flagged_time,s1_mu,...
            'color',i1_clrs(ii,:),...
            'linestyle','-',...
            'linewidth',1.5);
        plot(sps(1),time2plot(onset_flags),s1_mu(onset_flags),...
            'linewidth',1.5,...
            'marker','o',...
            'markersize',7.5,...
            'markerfacecolor','w',...
            'markeredgecolor',i1_clrs(ii,:));
        plot(sps(1),time2plot(offset_flags),s1_mu(offset_flags),...
            'linewidth',1.5,...
            'marker','o',...
            'markersize',7.5,...
            'markerfacecolor',i1_clrs(ii,:),...
            'markeredgecolor','w');
        plot(sps(2),flagged_time,s2_mu,...
            'color',i2_clrs(ii,:),...
            'linestyle','-',...
            'linewidth',1.5);
        plot(sps(2),time2plot(onset_flags),s2_mu(onset_flags),...
            'linewidth',1.5,...
            'marker','o',...
            'markersize',7.5,...
            'markerfacecolor','w',...
            'markeredgecolor',i2_clrs(ii,:));
        plot(sps(2),time2plot(offset_flags),s2_mu(offset_flags),...
            'linewidth',1.5,...
            'marker','o',...
            'markersize',7.5,...
            'markerfacecolor',i2_clrs(ii,:),...
            'markeredgecolor','w');
        
        % plot T1 raster
        s1_time_mat = padded_time - (...
            pre_init_padding + ...
            pre_t1_delay(s1_spike_flags));
        s1_trial_idcs = (1 : s1_n_trials)' + s1_n_trial_counter;
        s1_trial_mat = repmat(s1_trial_idcs,1,n_paddedtimebins);
        s1_spike_trials = s1_trial_mat(s1_spike_counts >= 1);
        s1_spike_times = s1_time_mat(s1_spike_counts >= 1);
        trial_sorter = [t1(s1_spike_flags),prev_choices(s1_spike_flags)];
        [~,sorted_idcs] = sortrows(trial_sorter,[1,-2]);
        [~,resorted_idcs] = sortrows(sorted_idcs);
        resorted_idcs = resorted_idcs + s1_n_trial_counter;
        s1_sorted_trials = resorted_idcs(s1_spike_trials - s1_n_trial_counter);
        plot(sps(4),s1_spike_times,s1_sorted_trials,...
            'color','k',...
            'marker','|',...
            'markersize',2.5,...
            'linestyle','none');
        
        % plot T2 raster
        s2_time_mat = padded_time - (...
            pre_init_padding + ...
            pre_t1_delay(s2_spike_flags) + ...
            t1(s2_spike_flags) + ...
            inter_t1t2_delay);
        s2_trial_idcs = (1 : s2_n_trials)' + s2_n_trial_counter;
        s2_trial_mat = repmat(s2_trial_idcs,1,n_paddedtimebins);
        s2_spike_trials = s2_trial_mat(s2_spike_counts >= 1);
        s2_spike_times = s2_time_mat(s2_spike_counts >= 1);
        trial_sorter = [t2(s2_spike_flags),choices(s2_spike_flags)];
        [~,sorted_idcs] = sortrows(trial_sorter,[1,-2]);
        [~,resorted_idcs] = sortrows(sorted_idcs);
        resorted_idcs = resorted_idcs + s2_n_trial_counter;
        s2_sorted_trials = resorted_idcs(s2_spike_trials - s2_n_trial_counter);
        plot(sps(5),s2_spike_times,s2_sorted_trials,...
            'color','k',...
            'marker','|',...
            'markersize',2.5,...
            'linestyle','none');
        
        % plot raster bands
        xpatch = ti_padd(1) + [0,.05,.05,0] .* range(xlim(sps(1)));
        ypatch = [.5,.5,s1_n_trials+.5,s1_n_trials+.5] + s1_n_trial_counter;
        patch(sps(4),xpatch,ypatch,i1_clrs(ii,:),...
            'linewidth',1.5,...
            'facealpha',.75,...
            'edgecolor','none');
        xpatch = ti_padd(1) + [0,.05,.05,0] .* range(xlim(sps(2)));
        ypatch = [.5,.5,s2_n_trials+.5,s2_n_trials+.5] + s2_n_trial_counter;
        patch(sps(5),xpatch,ypatch,i2_clrs(ii,:),...
            'linewidth',1.5,...
            'facealpha',.75,...
            'edgecolor','none');
        
        % update trial counters
        s1_n_trial_counter = s1_n_trial_counter + s1_n_trials;
        s2_n_trial_counter = s2_n_trial_counter + s2_n_trials;
    end
    
    % iterate through intensities
    for ii = 1 : n_i
        i2_flags = i2 == i_set(ii);
        go_spike_flags = ...
            valid_flags & ...
            neuron_flags & ...
            i2_flags;
        if sum(go_spike_flags) == 0
            continue;
        end
        
        % fetch spike counts & compute spike rates
        spike_counts = data.FR(go_spike_flags,:);
        spike_rates = conv2(...
            1,kernel.pdf,spike_counts,'valid')' / psthbin * 1e3;
        n_trials = size(spike_counts,1);
        
        % go-aligned spike rates
        go_alignment_onset = ...
            pre_init_padding + ...
            pre_t1_delay(go_spike_flags) + ...
            t1(go_spike_flags) + ...
            inter_t1t2_delay + ...
            t2(go_spike_flags) + ...
            post_t2_delay;
        go_alignment_flags = ...
            valid_time >= go_alignment_onset + action_padd(1) & ...
            valid_time < go_alignment_onset + action_padd(2);
        go_chunk_flags = ...
            valid_time >= go_alignment_onset + action_padd(1) & ...
            valid_time < go_alignment_onset + action_padd(2);
        go_spkrates = spike_rates;
        go_spkrates(~go_alignment_flags') = nan;
        go_spkrates = reshape(...
            go_spkrates(go_chunk_flags'),[range(action_padd),n_trials])';
        
        % flag current stimulus period
        time2plot = ...
            action_padd(1) + psthbin : psthbin : action_padd(2);
        time_flags = time2plot <= 0;
        onset_flags = time2plot <= 0 & ...
            [time2plot(2:end),nan] > 0;
        
        % compute mean spike density function
        go_mu = nanmean(go_spkrates,1);
        go_std = nanstd(go_spkrates,0,1);
        go_sem = go_std ./ sqrt(sum(~isnan(go_spkrates),1));
        
        % patch s.e.m.
        xpatch = [time2plot(time_flags),fliplr(time2plot(time_flags))];
        ypatch = [go_mu(time_flags)-go_sem(time_flags),fliplr(go_mu(time_flags)+go_sem(time_flags))];
        patch(sps(3),xpatch,ypatch,i2_clrs(ii,:),...
            'facealpha',.25,...
            'edgecolor','none');
        
        % plot average activity
        plot(sps(3),time2plot(time_flags),go_mu(time_flags),...
            'color',i2_clrs(ii,:),...
            'linestyle','-',...
            'linewidth',1.5);
    end
    
    % iterate through choices
    for ch = 1 : n_choices
        choice_flags = choices == choice_set(ch);
        light_clrs = colorlerp([choices_clrs(ch,:);[1,1,1]],5);
        dark_clrs = colorlerp([choices_clrs(ch,:);[1,1,1]*0],5);
        clrs = [dark_clrs(3,:);choices_clrs(ch,:);light_clrs(3,:);];
        
        % iterate through intensities
        for ii = 1 : n_i
            i2_flags = i2 == i_set(ii);
            go_spike_flags = ...
                valid_flags & ...
                neuron_flags & ...
                choice_flags & ...
                i2_flags;
            if sum(go_spike_flags) == 0
                continue;
            end
            
            % fetch spike counts & compute spike rates
            spike_counts = data.FR(go_spike_flags,:);
            spike_rates = conv2(...
                1,kernel.pdf,spike_counts,'valid')' / psthbin * 1e3;
            n_trials = size(spike_counts,1);
            
            % go-aligned spike rates
            go_alignment_onset = ...
                pre_init_padding + ...
                pre_t1_delay(go_spike_flags) + ...
                t1(go_spike_flags) + ...
                inter_t1t2_delay + ...
                t2(go_spike_flags) + ...
                post_t2_delay;
            go_alignment_flags = ...
                valid_time >= go_alignment_onset + action_padd(1) & ...
                valid_time < go_alignment_onset + action_padd(2);
            go_chunk_flags = ...
                valid_time >= go_alignment_onset + action_padd(1) & ...
                valid_time < go_alignment_onset + action_padd(2);
            go_spkrates = spike_rates;
            go_spkrates(~go_alignment_flags') = nan;
            go_spkrates = reshape(...
                go_spkrates(go_chunk_flags'),[range(action_padd),n_trials])';
            
            % flag current stimulus period
            time2plot = ...
                action_padd(1) + psthbin : psthbin : action_padd(2);
            time_flags = time2plot >= 0;
            onset_flags = time2plot <= 0 & ...
                [time2plot(2:end),nan] > 0;
            
            % compute mean spike density function
            go_mu = nanmean(go_spkrates,1);
            go_std = nanstd(go_spkrates,0,1);
            go_sem = go_std ./ sqrt(sum(~isnan(go_spkrates),1));
            
            % patch s.e.m.
            xpatch = [time2plot(time_flags),fliplr(time2plot(time_flags))];
            ypatch = [go_mu(time_flags)-go_sem(time_flags),fliplr(go_mu(time_flags)+go_sem(time_flags))];
            patch(sps(3),xpatch,ypatch,clrs(ii,:),...
                'facealpha',.25,...
                'edgecolor','none');
            
            % plot average activity
            plot(sps(3),time2plot(time_flags),go_mu(time_flags),...
                'color',clrs(ii,:),...
                'linestyle','-',...
                'linewidth',1.5);
            plot(sps(3),time2plot(onset_flags),go_mu(onset_flags),...
                'linewidth',1.5,...
                'marker','o',...
                'markersize',7.5,...
                'markerfacecolor','w',...
                'markeredgecolor',clrs(ii,:));
            
            % plot go cue raster
            time_mat = padded_time - (...
                pre_init_padding + ...
                pre_t1_delay(go_spike_flags) + ...
                t1(go_spike_flags) + ...
                inter_t1t2_delay + ...
                t2(go_spike_flags) + ...
                post_t2_delay);
            trial_idcs = (1 : n_trials)' + go_n_trial_counter;
            trial_mat = repmat(trial_idcs,1,n_paddedtimebins);
            go_spike_trials = trial_mat(spike_counts >= 1);
            go_spike_times = time_mat(spike_counts >= 1);
            trial_sorter = [t2(go_spike_flags),i2(go_spike_flags)];
            [~,sorted_idcs] = sortrows(trial_sorter,[1,2]);
            [~,resorted_idcs] = sortrows(sorted_idcs);
            resorted_idcs = resorted_idcs + go_n_trial_counter;
            go_sorted_trials = resorted_idcs(go_spike_trials - go_n_trial_counter);
            plot(sps(6),go_spike_times,go_sorted_trials,...
                'color','k',...
                'marker','|',...
                'markersize',2.5,...
                'linestyle','none');
            
            % plot raster bands
            xpatch = min(xlim(sps(3))) + [0,.05,.05,0] .* range(xlim(sps(3)));
            ypatch = [.5,.5,n_trials+.5,n_trials+.5] + go_n_trial_counter;
            patch(sps(6),xpatch,ypatch,clrs(ii,:),...
                'linewidth',1.5,...
                'facealpha',.75,...
                'edgecolor','none');
            
            % update trial counters
            go_n_trial_counter = go_n_trial_counter + n_trials;
        end
    end
    
    % save figure
    if want2save
        
        % update axes
        set(sps(4),...
            'ylim',[1,s1_n_trial_counter]);
        set(sps(5),...
            'ylim',[1,s2_n_trial_counter]);
        set(sps(6),...
            'ylim',[1,go_n_trial_counter]);
        
        % save settings
        save_file = fullfile(save_path,'rasters',[get(fig,'name'),'.png']);
        print(fig,save_file,'-dpng','-r300','-painters');
        close(fig);
    else
        pause(1);
        close(fig);
    end
end