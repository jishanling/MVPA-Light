% mv_classify_timextime unit test
%
rng(42)
tol = 10e-10;
mf = mfilename;

%% Create a dataset where classes can be perfectly discriminated for only some time points [two-class]
% 

nsamples = 100;
ntime = 300;
nfeatures = 10;
nclasses = 2;
prop = [];
scale = 0.0001;
do_plot = 0;

can_discriminate = 50:100;
cannot_discriminate = setdiff(1:ntime, can_discriminate);

% Generate data
X = zeros(nsamples, nfeatures, ntime);
[~,clabel] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);

for tt=1:ntime
    if ismember(tt, can_discriminate)
        scale = 0.0001;
        if tt==can_discriminate(1)
            [X(:,:,tt),~,~,M]  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
        else
            % reuse the class centroid to make sure that the performance
            % generalises
            X(:,:,tt)  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot, M);
        end
    else
        scale = 10e1; 
        X(:,:,tt) = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
    end
end

cfg = [];
cfg.feedback = 0;

[acc, result] = mv_classify_timextime(cfg, X, clabel);

% imagesc(acc), title(mf,'interpreter','none')
mv_plot_result(result);

% performance should be around 100% for the discriminable time points, and
% around 50% for the non-discriminable ones
acc_discriminable = mean(mean( acc(can_discriminate, can_discriminate)));
acc_nondiscriminable = mean(mean( acc(cannot_discriminate, cannot_discriminate)));

tol = 0.03;
print_unittest_result('[two-class] CV discriminable times = 1?', 1, acc_discriminable, tol);
print_unittest_result('[two-class] CV non-discriminable times = 0.5?', 0.5, acc_nondiscriminable, tol);

%% Create a dataset where classes can be perfectly discriminated for only some time points [4 classes]
nsamples = 100;
ntime = 100;
nfeatures = 10;
nclasses = 4;
prop = [];
scale = 0.0001;
do_plot = 0;

can_discriminate = 30:60;
cannot_discriminate = setdiff(1:ntime, can_discriminate);

% Generate data
X = zeros(nsamples, nfeatures, ntime);
[~,clabel] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);

for tt=1:ntime
    if ismember(tt, can_discriminate)
        scale = 0.0001;
        if tt==can_discriminate(1)
            [X(:,:,tt),~,~,M]  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
        else
            % reuse the class centroid to make sure that the performance
            % generalises
            X(:,:,tt)  = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot, M);
        end
    else
        scale = 10e1;
        X(:,:,tt) = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
    end
end

cfg = [];
cfg.feedback = 0;
cfg.classifier = 'multiclass_lda';

acc = mv_classify_timextime(cfg, X, clabel);

% performance should be around 100% for the discriminable time points, and
% around 25% for the non-discriminable ones
acc_discriminable = mean(mean( acc(can_discriminate, can_discriminate)));
acc_nondiscriminable = mean(mean( acc(cannot_discriminate, cannot_discriminate)));

tol = 0.03;
print_unittest_result('[4 classes] CV discriminable times = 1?', 1, acc_discriminable, tol);
print_unittest_result('[4 classes] CV non-discriminable times = 0.5?', 0.25, acc_nondiscriminable, tol);

%% Check different metrics and classifiers -- just run to see if there's errors
nsamples = 60;
ntime = 2;
nfeatures = 10;
nclasses = 2;
prop = [];
scale = 0.0001;
do_plot = 0;

% Generate data
[X,clabel] = simulate_gaussian_data(nsamples, nfeatures, nclasses, prop, scale, do_plot);
X(:,:,2) = X;

cfg = [];
cfg.feedback = 0;

for metric = {'acc','auc','f1','precision','recall','confusion','tval','dval'}
    for classifier = {'lda', 'logreg', 'multiclass_lda', 'svm', 'ensemble','kernel_fda','naive_bayes'}
        if any(ismember(classifier,{'kernel_fda' 'multiclass_lda','naive_bayes'})) && any(ismember(metric, {'tval','dval','auc'}))
            continue
        end
        fprintf('%s - %s\n', metric{:}, classifier{:})
        
        cfg.metric      = metric{:};
        cfg.classifier  = classifier{:};
        cfg.k           = 5;
        cfg.repeat      = 1;
        tmp = mv_classify_timextime(cfg, X, clabel);
    end
end