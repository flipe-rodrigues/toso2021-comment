%% initialization
if ~exist('data','var')
    toso2021_wrapper;
end

%% choice GLM (complete model)
X = [s1,s2,d1,d2];
X = log(X);
Z = (X - nanmean(X)) ./ nanstd(X);
% Z = [Z, Z(:,1) .* Z(:,2), Z(:,2) .* Z(:,4)];
% mdl = fitglm(Z,choices,'interactions',...
%     'predictorvars',{s1_lbl,s2_lbl,d1_lbl,d2_lbl},...
%     'distribution','binomial',...
%     'intercept',true);
mdl = fitglm(Z(valid_flags,:),choices(valid_flags,:),'linear',...
    'predictorvars',{s1_lbl,s2_lbl,d1_lbl,d2_lbl},...,'T_1:T_2','T_2:I_2'},...
    'distribution','binomial',...
    'intercept',true);
betas = mdl.Coefficients.Estimate;
beta_s1 = betas(2);
beta_s2 = betas(3);
n_betas = numel(betas);
beta_labels = mdl.CoefficientNames;
beta_labels{1} = '\beta_0';
fig = figure(figopt,...
    'name','choice_GLM');
axes(axesopt.default,...
    'xlim',[0,n_betas+1],...
    'xtick',1:n_betas,...
    'xticklabel',beta_labels);
title(sprintf('%s > %s ~ Binomial(\\phi(\\betaX))',s2_lbl,s1_lbl));
xlabel('X');
ylabel('\beta');

% plot coefficients
p = stem(1:numel(betas),betas,...
    'color','k',...
    'marker','o',...
    'markersize',10,...
    'markerfacecolor','k',...
    'markeredgecolor','w',...
    'linewidth',1.5);
p.BaseLine.LineWidth = p.LineWidth;

% save figure
if want2save
    svg_file = fullfile(panel_path,[fig.Name,'.svg']);
    print(fig,svg_file,'-dsvg','-painters');
end