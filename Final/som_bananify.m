global r tau_r alpha0 tau_alpha;

%Tunable Parameters
num_bins = 5;
training_time = 10000;
r = .25; %Influence Radius
tau_r = 200; %Influence Radius Decay Time Constant
alpha0 = .05; %Influence at distance=0
tau_alpha = 1000; %Influence Decay Time Constant
%End Tunable Parameters

[n_pats pat_length] = size(patterns);

%Create bins and initialize with random patterns (initializing randomly
%results in all patterns being binned together)
bins = zeros(num_bins, pat_length);
pat_list = zeros(num_bins,1);
%pick a random pattern number:
for i = 1:num_bins
    %Randomly choose a pattern
    ipat = random('unid',n_pats);
    %If the pattern is already in a bin, try again
    while ~isempty(find(pat_list==ipat ))
        ipat = random('unid',n_pats);
    end
    %Add the pattern to the list
    pat_list(i) = ipat;
    %Initialize the bin
    bins(i,:) = ipat;
end

%Normalize Bin Feature Vectors
for i = 1:num_bins
    bins(i,:) = bins(i,:) ./ norm(bins(i,:));
end

%Train Bins
time=0;
while (time<training_time)
    time = time+1;
    ipat = ceil(rand*n_pats); %pick a pattern at random
    testvec = patterns(ipat,:); %extract the corresponding row vector
    
    %For the selected pattern, find the closest bin
    bin_index = som_find_closest_bin(testvec, bins);
    
    %Update the indentified bin and its neighbors
    for i = 1:num_bins
        alpha = som_alpha(i, bin_index, time);
        bins(i,:) = bins(i,:) + alpha * (testvec - bins(i,:));
        bins(i,:) = bins(i,:) ./ norm(bins(i,:));
    end
end

%Assign Training Patterns and Calculate Attribute Values
bin_list = zeros(n_pats, 1);
for i = 1:n_pats
    bin_list(i) = som_find_closest_bin(patterns(i,:),bins);
end

bin_attributes = zeros(num_bins,1);
bin_sd = zeros(num_bins,1);
for i=1:num_bins
    bin_members = bin_list==i;
    if(sum(bin_members)>0)
        bin_attributes(i) = mean(targets(bin_members,:),1);
        bin_sd(i) = std(targets(bin_members,:),1);
    end
end
bin_attributes
bin_sd

%Assign validation patterns to bins
[num_validation_pats ~] = size(validation);
bin_list_val = zeros(num_validation_pats, 1);
for i = 1:num_validation_pats
    bin_list_val(i) = som_find_closest_bin(validation(i,:),bins);
end

%Debug results
result_eval = bin_attributes(bin_list_val)-val_targets;
disp('Bin; Target Value(1=r, 2=u, 3=o); Calculated Value');
cat(2,bin_list_val,val_targets,bin_attributes(bin_list_val))