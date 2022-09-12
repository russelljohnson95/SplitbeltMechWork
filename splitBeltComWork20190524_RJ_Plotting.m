% process and plot the work from individual limbs on split belt treadmill
% walking at different step length asymmetries

clear
clc
close all


load('ILM_S413_Subj_RJ.mat')

% load('

n_subj = 1; 
n_trial = 5; 

mass = [83.8, 78.1, 63.4, 85.4, 68.7, 84.8, 74.1, 71.8, 56.6, 75.2, 57.3, 94.4, 59.9, 54.2];
leg_length = [0.9156; 0.8120; 0.7923; 0.8709; 0.8348; 0.8530; 0.8625; 0.8635;... 
                 0.7365; 0.8860; 0.7730; 0.9184; 0.8330; 0.8601];
             
g = 9.81; 

% data are normalized to m*l^0.5*g^1.5 - from Sanchez et al., 2019 JPhys

for s = 1:n_subj
    subj_result = subj{s,1};
    von = 1; 
    for t = 1:n_trial
        trial_result = subj_result{1,t};
        for stride = 1:21
            % net legs / kg
            net_legs(s,von) = trial_result.workRate21.net(stride)/ (mass(s) * (leg_length(s)^0.5) * (g^1.5));
            % total positive legs
            totpos_legs(s,von) = trial_result.workRate21.totpos(stride)/(mass(s) * (leg_length(s)^0.5) * (g^1.5));
            % total negative legs
            totneg_legs(s,von) = trial_result.workRate21.totneg(stride)/(mass(s) * (leg_length(s)^0.5) * (g^1.5));
            % net treadmill 
            net_treadmill(s,von) = trial_result.workRate21.nettread(stride)/(mass(s) * (leg_length(s)^0.5) * (g^1.5));
            % positive treadmill
            pos_treadmill(s,von) = trial_result.workRate21.treadpos(stride)/(mass(s) * (leg_length(s)^0.5) * (g^1.5));
            % negative treadmill
            neg_treadmill(s,von) = trial_result.workRate21.treadneg(stride)/(mass(s) * (leg_length(s)^0.5) * (g^1.5));
            
            SLA_output(s,von) = trial_result.SLA(stride); 

            von = von+1; 
        end
        
    end
    
end

%%

figure()
color22 = {'#F2570C','#FC200D','#E6178C','#C70DFC','#0D3CFC','#008EE6','#0DFCF3','#05F57F','#0AFC08','#0AFC08','#86E605','#FCF408','#F5C500','#F59405'};

% positive work rate by the legs
subplot(2,3,1)
for s = 1:n_subj
    plot(SLA_output(s,:),totpos_legs(s,:),'.','color',color22{s});
    hold on 
    ylabel('dimensionless')
end
% ylim([-12 12]);
% yticks([-12 -6 0 6 12]);
title('Positive Work Rate by Legs')
box off

% negative work rate by the legs
subplot(2,3,2)
for s = 1:n_subj
    plot(SLA_output(s,:),totneg_legs(s,:),'.','color',color22{s});
    hold on 
end
% ylim([-12 12]);
% yticks([-12 -6 0 6 12]);
title('Negative Work Rate by Legs')
box off

% total work rate by the legs
subplot(2,3,3)
for s = 1:n_subj
    plot(SLA_output(s,:),net_legs(s,:),'.','color',color22{s});
    hold on 
end
yline(0);
% ylim([-12 12]);
% yticks([-12 -6 0 6 12]);
title('Total Work Rate by Legs')
box off

% positive work by treadmill on the legs
subplot(2,3,4)
for s = 1:n_subj
    plot(SLA_output(s,:),pos_treadmill(s,:),'.','color',color22{s});
    hold on 
    ylabel('dimensionless')
end
% ylim([-1 1])
% yticks([-1 0 1])
title('Positive Work by Treadmill')
box off

% negative work by treadmill on the legs
subplot(2,3,5)
for s = 1:n_subj
    plot(SLA_output(s,:),neg_treadmill(s,:),'.','color',color22{s});
    hold on 
end
% ylim([-1 1])
% yticks([-1 0 1])
title('Negative Work by Treadmill')
box off

% total work by the treadmill on the legs
subplot(2,3,6)
for s = 1:n_subj
    plot(SLA_output(s,:),net_treadmill(s,:),'.','color',color22{s});
    hold on 
end
yline(0);
% ylim([-1 1])
% yticks([-1 0 1])
title('Total Work by Treadmill')
box off

% add treadmill and leg work 
total_work = net_treadmill + net_legs;

figure(11)
plot(total_work)

