clc
clear
close all

% fp = 'G:/My Drive/WCoM';
%  fp = uigetdir(cd,'Select the Directory Where the Individual Data are Stored');
fp = 'C:\Users\russe\Google Drive\USC\R01_JointWork\Data\Data_Mat_ILM_v2';
% fp = '/Volumes/GoogleDrive/My Drive/Projects/Split-Belt Walking Mechanics/WCoM_2019/Long_Adapt/';
% fns = dir(fullfile(fp,'2019*'));
fns = dir(fullfile(fp,'Data_S*'));
folderInd = [fns.isdir]';
fns = fns(folderInd);

varIN.g = 9.81;
varIN.minStepDur = 0.4;

%% Select one for the following depending on the test you want to run.

% This interpolates every stride to be equal length and computes the
% average force, velocity and power across the last 100 stride. Use this
% when we want to see the avearge FVP plots for the last 100 strides. I
% think this doesn't help as much with debugging since it is an average but
% is a useful to visualize and maybe present to others to explain FVP
% plots.
test.fvpInterp = 0; % This interpolates every stride to be equal length and computes the average force, velocity and power across the last 100 stride.
test.fvpInterpPlot = 0; % This plots the interpolated data

% This generates an fvp plot with the x-axis just being time. This is very
% useful for debugging. It gives the time series data for each participant,
% one by one. Using this, we can check that:
% 1. The forces look correct. For ex: there should not be any drift in the
% forces over time, the vertical force should not go below zero. In general
% that the profile looks right such as there is double peak for walking.
% 2. The velocity looks correct. Main thing to check is that the velocity
% at the end of a stride is equal to the velcocity at the start of the next
% stride. Also, compare the profile and magnitude to literature.
% 3. The power looks correct. It should be the dot product of the force and
% velocity for every time step. Compare profile with literature.
test.fvpTimeSeries = 1; % This generates an fvp plot with the x-axis just being time.

% This outputs the force per stride avearged across all strides. This is
% also a very useful tool for debugging. The average force in the x and y
% axes should be zero, and in the z-axis it should be equal to body weight.
% These are the ideal conditions. But I've never seen this to be exactly
% true. In my experience, upto 2N away from the ideal is still fine. When
% comparing the vertical force with body weight, make sure that the manner
% in which body weight itself was measured is realiable and not without
% errors/ noise/ drift etc. It is possible that this trial is fine but the
% recorded body weight is wrong.
test.forceperstride = 0; % This outputs the force per stride avearged across all strides and should ideally be zero

% Select this to save data for further analysis using
% AnalyseProcessedData<date>.m
savedata = 1;


% preallocation
M = zeros(length(fns),1); %mass
legLength = zeros(length(fns),1);
% standMet = struct; subj = cell(length(fns),1); rawSLA = cell(length(fns),1);

for i=1:1 % 1 subject data pool for testing
%     length(fns)
    load(fullfile(fp,fns(i).name,'Data_v2.mat'));
    varIN.Fs = Data.Fs.Force;
    if i==1||i==2, varIN.Fs=100; end
    M(i,1) = Data.Demographics.Mass;
%     legLength(i,1) = str2num(Data.Demographics.Leg_Length)./1000; % in metres
    trials = Data.Trials;
    trialData = fieldnames(trials);
    for k = 1:length(trialData)
        switch(trialData{k})
%             case('StandingBaseline'); trialOrder(i,k) = -1;
            case('Minus_10'); trialOrder(i,k) = 1;
            case('Minus_5'); trialOrder(i,k)  = 2;
            case('Sym'); trialOrder(i,k)      = 3;
            case('Plus_5'); trialOrder(i,k)   = 4;
            case('Plos_10'); trialOrder(i,k)  = 5;
        end
    end
    % Standing Trial  - to obtain mass and compare; and obtain metabolic
    % power for standing
    zfl_stand = Data.Trials.(trialData{1}).zGRF_L;
    zfr_stand = Data.Trials.(trialData{1}).zGRF_R;
    mass = mean(zfl_stand+zfr_stand)/varIN.g;
%     VO2 = Data.Trials.StandingBaseline.AcumVO2_L;
%     VCO2 = Data.Trials.StandingBaseline.AcumVCO2_L;
%     t_met = Data.Trials.StandingBaseline.Time_Vector_MetCost;
%     [standMet(i).RER,standMet(i).Emet,standMet(i).Pmet] = computeMetPower(t_met, VO2, VCO2, 2);
    
    % Analysis of all walking trials
    [subj{i},rawSLA{i}] = analyzeSubject(Data,varIN,trialData,test,M(i));
    
    % Interpolation and FVP plots
    for q=1:length(subj{i})
        if test.fvpInterp
            [avgforce(i,q),avgvel(i,q),avgpower(i,q)] = computeStrideAvg(i,subj{i}{q}.fStride,...
                subj{i}{q}.vStride,subj{i}{q}.pStride,varIN.Fs,test,fns(i).name,trialData{q+1});
        end
        if test.fvpTimeSeries
            fvpTimeSeries(subj{i}{q}.fStride,subj{i}{q}.vStride,subj{i}{q}.pStride);
        end
    end
    i
end
%% This creates an 2D array of only the variables that we want to save.
if savedata
    clear p q
%     RER = zeros(length(subj),1); Emet = zeros(length(subj),1); Pmet = zeros(length(subj),1);
    % avg100workRate = struct;
    for p=1:length(subj)
        for q=1:length(subj{p,1})
%             RER(p,q) = subj{p,1}{1,q}.RER;
%             Emet(p,q) = subj{p,1}{1,q}.Emet;
%             Pmet(p,q) = subj{p,1}{1,q}.Pmet;
            workRate21(p,q) = subj{p,1}{1,q}.workRate21;
            avgWorkRate21(p,q) = subj{p,1}{1,q}.avgWorkRate21;
            SLA_Out(p,q) = {subj{p,1}{1,q}.SLA};
%             wnetRate{p,q} = subj{p,1}{1,q}.wnetRate;
%             wtotposRate{p,q} = subj{p,1}{1,q}.wtotposRate;
%             wtotnegRate{p,q} = subj{p,1}{1,q}.wtotnegRate;
%             wlposRate{p,q} = subj{p,1}{1,q}.wlposRate;
%             wrposRate{p,q} = subj{p,1}{1,q}.wrposRate;
%             wlnegRate{p,q} = subj{p,1}{1,q}.wlnegRate;
%             wrnegRate{p,q} = subj{p,1}{1,q}.wrnegRate;
%             wltreadposRate{p,q} = subj{p,1}{1,q}.wltreadposRate;
%             wrtreadposRate{p,q} = subj{p,1}{1,q}.wrtreadposRate;
%             wltreadnegRate{p,q} = subj{p,1}{1,q}.wltreadnegRate;
%             wrtreadnegRate{p,q} = subj{p,1}{1,q}.wrtreadnegRate;
            Mass{p,q} = subj{p,1}{1,q}.mass;
            L_prop_Imp{p,q} = subj{p,1}{1,q}.prop_imp_L;
            R_prop_Imp{p,q} = subj{p,1}{1,q}.prop_imp_R;
            L_brake_Imp{p,q} = subj{p,1}{1,q}.brake_imp_L;
            R_brake_Imp{p,q} = subj{p,1}{1,q}.brake_imp_R;
            L_prop_peak{p,q} = subj{p,1}{1,q}.peak_prop_L;
            R_prop_peak{p,q} = subj{p,1}{1,q}.peak_prop_R;
            L_brake_peak{p,q} = subj{p,1}{1,q}.peak_brake_L;
            R_brake_peak{p,q} = subj{p,1}{1,q}.peak_brake_R;
            TimeStride{p,q} = subj{p,1}{1,q}.tStride;
%             wLcompos{p,q} = subj{p,1}{1,q}.wlcompos;
%             wRcompos{p,q} = subj{p,1}{1,q}.wrcompos;
%             wLcomneg{p,q} = subj{p,1}{1,q}.wlcomneg;
%             wRcomneg{p,q} = subj{p,1}{1,q}.wrcomneg;
            
            pLcom{p,q} = subj{p,1}{1,q}.pStride.lcom;
            pRcom{p,q} = subj{p,1}{1,q}.pStride.rcom;
            pLtread{p,q} = subj{p,1}{1,q}.pStride.ltread;
            pRtread{p,q} = subj{p,1}{1,q}.pStride.rtread;
            pL{p,q} = subj{p,1}{1,q}.pStride.l;
            pR{p,q} = subj{p,1}{1,q}.pStride.r;
            
            vStride{p,q} = subj{p,1}{1,q}.vStride.com;

%             lStepLength{p,q}

        end
    end
    save('ILM_S413_RJ.mat',...
        'M','legLength','fns','rawSLA','trialOrder','workRate21','avgWorkRate21','SLA_Out',...
        'mass','L_prop_Imp','R_prop_Imp',...
        'L_brake_Imp','R_brake_Imp','TimeStride','L_brake_peak','R_brake_peak','L_prop_peak','R_prop_peak',...
        'pLcom','pRcom','pLtread','pRtread','pL','pR','vStride');
%     save('G:\My Drive\FinleyDataAnalyseCode\ProcessedDataS1to16_071918.mat',...
%         'M','legLength','fns','trialOrder','standMet','rawSLA','RER','Emet','Pmet','avg100workRate','avgpower')
end

%% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to analyse all trials of a single subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [trial,rawSLA] = analyzeSubject(Data,varIN,trialData,test,M)

for j=1:length(trialData) % this cycles through the differnet walking trials for each subject
    
    SLA = Data.Trials.(trialData{j}).SLA(1:end-1)'; %measured step length asymmetry
    rawSLA(j,1:length(SLA)) = SLA;
    [SLA_21Out{j}] = SLA(1:21);  % first 21 trials
%     VO2 = Data.Trials.(trialData{j}).AcumVO2_L(1:end-1); %measured volume of oxygen in liters
%     VCO2 = Data.Trials.(trialData{j}).AcumVCO2_L(1:end-1); %measured volume of CO2 in litres
    
    time.force = Data.Trials.(trialData{j}).Time_Vector_Force(1:end-1); %time vector for GRF
    time.lHS_kinematics = Data.Trials.(trialData{j}).HS_Time_Left(1:end-1)'; %time of each left heel strike based on video capture
%     time.met = Data.Trials.(trialData{j}).Time_Vector_MetCost(1:end-1); %time vector for metabolics
    
    speed.L = -1*Data.Trials.(trialData{j}).SpeedLeft; % multiply by -1 since the belts are moving in the
    speed.R = -1*Data.Trials.(trialData{j}).SpeedRight; % -y direction according to treadmill cordinate frame
    
    % storing the ground reaction forces into intuitive variable names
    grf.xl = Data.Trials.(trialData{j}).xGRF_L(1:end-1);
    grf.yl = Data.Trials.(trialData{j}).yGRF_L(1:end-1);
    grf.zl = Data.Trials.(trialData{j}).zGRF_L(1:end-1);
    grf.xr = Data.Trials.(trialData{j}).xGRF_R(1:end-1);
    grf.yr = Data.Trials.(trialData{j}).yGRF_R(1:end-1);
    grf.zr = Data.Trials.(trialData{j}).zGRF_R(1:end-1);
    
%     cop.L = Data.Trials.(trialData{j}).Filtered_COP_L_FA;
%     cop.R = Data.Trials.(trialData{j}).Filtered_COP_R_FA;
    
%     [trial{j-1}] = analyzeTrial(varIN,VO2,VCO2,time,speed,grf,cop,test,M);
    [trial{j}] = analyzeTrial(varIN,time,speed,grf,test,M,SLA);
    j
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to analyse a single walking trial for a single subject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [varOut] = analyzeTrial(varIN,time,speed,grf,test,M,SLA)

t_force = time.force;
t_lHS_kinematics = time.lHS_kinematics;
% t_met = time.met;
Fs = varIN.Fs;
g = varIN.g;
minStepNo = varIN.minStepDur;

% This gives the metabolic energy and power for this trial
% [varOut.RER,varOut.Emet,varOut.Pmet] = computeMetPower(t_met, VO2, VCO2);

% This breaks up the force vectors into strides
[varOut.rStepIndperStride,varOut.fStride,varOut.tStride,varOut.lStrideEndIndGood,varOut.rStrideEndIndGood,...
    varOut.t_lHeelStrike,varOut.t_rHeelStrike] =...
    forceperStride(grf,test,g,minStepNo,t_force,M);

% This gives out the SLA and the total stride length calculated using force
% plates
% [varOut.slaFP,varOut.totalSL,varOut.lStepLength,varOut.rStepLength] =...
%     computeSL(cop,varOut.lStrideEndIndGood,varOut.rStrideEndIndGood);

% This is the function that calcualtes velocity from force and then
% computes power
[varOut.dFastStep, varOut.dSlowStep, varOut.vStride, varOut.pStride, varOut.mass,...
    varOut.prop_imp_L,varOut.prop_imp_R,varOut.brake_imp_L,varOut.brake_imp_R,...
    varOut.peak_brake_L,varOut.peak_prop_L,varOut.peak_brake_R,varOut.peak_prop_R] =...
    computepower(varOut.rStepIndperStride,varOut.fStride,Fs,speed,M);

% This computes work from power
[varOut.workRate21,varOut.avgWorkRate21,varOut.wnetRate,varOut.wnet] =...
    workperStride(varOut.pStride,varOut.tStride,Fs);

varOut.SLA = SLA(1:21); % adding SLA to the outputs - but only 21 strides

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fucntion to break up the force vectors into strides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rStrideEndInd,fStride,tStride,lStrideEndIndGood,rStrideEndIndGood,t_lHeelStrike,...
    t_rHeelStrike] = forceperStride(grf,test,g,minStepNo,t_force,M)
% % i'm just multiplying the fore-aft forces by -1 for the sign to
% % make sense.
% grf.yl(:,1) = -1*grf.yl;
% grf.yr(:,1) = -1*grf.yr;

% this combines all left forces into one variable and all right
% forces into one.
flMatched = [grf.xl, grf.yl, grf.zl];
frMatched = [grf.xr, grf.yr, grf.zr];

% It appears that there are forces measured even when there is no
% feet on the force plate indicating that there is some offset and
% this offset changes over time and between trials. So, I'm just
% getting a mean value for this offset for each trial and
% subtracting that value from all data. I considered subtracting a
% different value for each stride but then this means that the
% starting force of one stride might not equal the ending force of
% the previous stride.
derfl = diff(flMatched(:,3)); %derivative of force to see when its unchanging.
derfr = diff(frMatched(:,3));

derLZero = abs(derfl)<10;
% 1e-1; %testing when the derivative of force is zero
flZero = abs(flMatched(1:end-1,3))<0.025*max(flMatched(:,3)); %testing when the value of force isless than 5% body weight. to ensure that there is no foot on the belt.
flBaseRqd = derLZero.*flZero; %finding points in time when derivative of force is constant && force <5% body weight

% asdf=(flBaseRqd(flBaseRqd==1));
% size(asdf)
% size(flMatched)
% indices = find(flBaseRqd==1);
% plot(flMatched(:,3)); hold on; plot([indices indices], ylim,'k-')
% calculate the trend in the baseline force. This happens when its not a constant
% offset but there is also a drift
xflBaseDrift = [ones(length(t_force(logical(flBaseRqd))),1),t_force(logical(flBaseRqd))]\flMatched(logical(flBaseRqd),1);
yflBaseDrift = [ones(length(t_force(logical(flBaseRqd))),1),t_force(logical(flBaseRqd))]\flMatched(logical(flBaseRqd),2);
zflBaseDrift = [ones(length(t_force(logical(flBaseRqd))),1),t_force(logical(flBaseRqd))]\flMatched(logical(flBaseRqd),3);

flMatched(:,1) = (flMatched(:,1)- (t_force*xflBaseDrift(2))) - xflBaseDrift(1);
flMatched(:,2) = (flMatched(:,2)- (t_force*yflBaseDrift(2))) - yflBaseDrift(1);
flMatched(:,3) = (flMatched(:,3)- (t_force*zflBaseDrift(2))) - zflBaseDrift(1);

% repeat the same process for the right belt
derRZero = abs(derfr)<10;
% 1e-1;
frZero = abs(frMatched(1:end-1,3))<0.025*max(frMatched(:,3));
frBaseRqd = derRZero.*frZero;

% calculate the trend in the baseline force. This happens when its not a constant
% offset but there is also a drift
xfrBaseDrift = [ones(length(t_force(logical(frBaseRqd))),1),t_force(logical(frBaseRqd))]\frMatched(logical(frBaseRqd),1);
yfrBaseDrift = [ones(length(t_force(logical(frBaseRqd))),1),t_force(logical(frBaseRqd))]\frMatched(logical(frBaseRqd),2);
zfrBaseDrift = [ones(length(t_force(logical(frBaseRqd))),1),t_force(logical(frBaseRqd))]\frMatched(logical(frBaseRqd),3);

frMatched(:,1) = (frMatched(:,1)- (t_force*xfrBaseDrift(2))) - xfrBaseDrift(1);
frMatched(:,2) = (frMatched(:,2)- (t_force*yfrBaseDrift(2))) - yfrBaseDrift(1);
frMatched(:,3) = (frMatched(:,3)- (t_force*zfrBaseDrift(2))) - zfrBaseDrift(1);

% Determine mass of the subject. Right now, I override this by
% calculating mass at each stirde within the computework function
% but if you comment that out, this will be the mass used.
% mass = (mean(flMatched(:,3)+frMatched(:,3)))/g;

% Choose the end of the stride by finding the time when the
% vertical force crosses 32N(Young-Hui Chang 2017) in the positive
% direction i.e. right after heel strike. Ignore steps detected
% that are less than 400ms long.
lstepEndInd = (flMatched(:,3)-32)<0.5;
lstepEndInd = lstepEndInd*1000;
changeInd = find(diff(lstepEndInd)~=0);
for p=1:length(changeInd)-1
    if (changeInd(p+1)-changeInd(p))<minStepNo
        lstepEndInd(changeInd(p):changeInd(p+1))=1000;
    end
end
lStrideEndInd = find(diff(lstepEndInd)<0);
lStrideEndInd = lStrideEndInd+1;

% Repeat the same to find the right heel strike. This is used for
% detecting step length and SLA later.
for i=2:length(lStrideEndInd)
    rStepEndInd = (frMatched(lStrideEndInd(i-1):lStrideEndInd(i),3)-32)<0.5;
    if ~rStepEndInd, rStrideEndInd(i-1)=nan; continue; end
    rStepEndInd = rStepEndInd*1000;
    rChangeInd = find(diff(rStepEndInd)~=0);
    for p=1:length(rChangeInd)-1
        if (rChangeInd(p+1)-rChangeInd(p))<minStepNo
            rStepEndInd(rChangeInd(p):rChangeInd(p+1))=1000;
        end
    end
    rStrideEndInd(i-1) = find(diff(rStepEndInd)<0,1);
    rStrideEndInd(i-1) = rStrideEndInd(i-1)+1;
    if ~rStrideEndInd(i-1), rStrideEndInd(i-1)=nan; end
end

% rstepEndInd = (frMatched(:,3)-32)<0.5;
% rstepEndInd = rstepEndInd*1000;
% changeInd = find(diff(rstepEndInd)~=0);
% for p=1:length(changeInd)-1
%     if (changeInd(p+1)-changeInd(p))<minStepNo
%         rstepEndInd(changeInd(p):changeInd(p+1))=1000;
%     end
% end
% rHeelStrikeInd = find(diff(rstepEndInd)<0);
% rHeelStrikeInd = rHeelStrikeInd+1;

goodSteps = 1;
for p=1:length(lStrideEndInd)-1
    if isnan(rStrideEndInd(p)), continue; end
    t_lHeelStrike(goodSteps) = t_force(lStrideEndInd(p));
    t_rHeelStrike(goodSteps) = t_force(lStrideEndInd(p)+rStrideEndInd(p));
    lStrideEndIndGood(goodSteps) = lStrideEndInd(p);
    rStrideEndIndGood(goodSteps) = lStrideEndInd(p)+rStrideEndInd(p);
    goodSteps=goodSteps+1;
end

tStride = diff(t_force(lStrideEndInd));

% break up data of left and right leg into strides
fxBiasStride=zeros(length(lStrideEndInd)-1,1);
fyBiasStride=zeros(length(lStrideEndInd)-1,1);
flyBiasStride=zeros(length(lStrideEndInd)-1,1);
fryBiasStride=zeros(length(lStrideEndInd)-1,1);
for m=2:length(lStrideEndInd)
    fStride.l{m-1,:} = flMatched(lStrideEndInd(m-1):lStrideEndInd(m),:);
    fStride.r{m-1,:} = frMatched(lStrideEndInd(m-1):lStrideEndInd(m),:);
    fStride.total{m-1,:} = [fStride.l{m-1,1}(:,1:3)+fStride.r{m-1,1}(:,1:3)];
    
    % i can sum up the total force over each stride. ideally this
    % should be zero fro each stride for the x and y directions.
    % this is to test if there is something causing non-zero forces
    % during the trial.
    fxBiasStride(m-1) = mean(fStride.total{m-1,1}(:,1));
    fyBiasStride(m-1) = mean(fStride.total{m-1,1}(:,2));
    fzBiasStride(m-1) = mean(fStride.total{m-1,1}(:,3));
    flyBiasStride(m-1) = mean(fStride.l{m-1,1}(:,2));
    fryBiasStride(m-1) = mean(fStride.r{m-1,1}(:,2));

end
if test.forceperstride==1
    % i can sum up the total force over each stride. here i jsut
    % avearge this force across all strides. ideally this should be
    % zero fro each stride for the x and y directions. this is to test
    % if there is something causing non-zero forces during the trial.
    meanfxBiasStride = mean(fxBiasStride)
%     figure(1);hold on;plot(fxBiasStride);pause
    meanfyBiasStride = mean(fyBiasStride)
%     meanfzBiasStride = mean(fzBiasStride)-(M*g)
%     figure(2);hold on;plot(fyBiasStride);grid on;pause
%     meanflyBiasStride = mean(flyBiasStride)
%     figure(3);hold on;plot(flyBiasStride);pause
%     meanfryBiasStride = mean(fryBiasStride)
%     figure(4);hold on;plot(fryBiasStride);pause
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute power
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dFastStep, dSlowStep, vStride, pStride, mass,...
    prop_imp_L,prop_imp_R,brake_imp_L,brake_imp_R,peak_brake_L,peak_prop_L,peak_brake_R,peak_prop_R]...
    = computepower(rStepIndperStride,fStride,Fs,speed,M)

ftot = fStride.total;
fl = fStride.l;
fr = fStride.r;
speedL = speed.L;
speedR = speed.R;
g = 9.81;
% vcom = cell(length(ftot)); vltread = cell(length(ftot)); vrtread = cell(length(ftot));
% plcom = cell(length(ftot)); prcom = cell(length(ftot)); pltread = cell(length(ftot));
% prtread = cell(length(ftot)); pl = cell(length(ftot)); pr = cell(length(ftot));

% Integrates total forces over a stride to get center of mass velocity.
for i=1:length(ftot)
    % estimate mass for each stride. otherwise the error in mass causes the
    % velocity at the end of one stride to not match the velocity at the
    % beginning of the next stride
%     mass=M;
    mass = mean(ftot{i,1}(:,3))/g;
    temp = -fl{i,1}(:,2);
    temp1 = temp(1:round(length(temp)/2)); %make sure we are only taking braking force at beginign of GC
    temp2 = temp(round(length(temp)/4):end); % make sure we are only taking prop at TO
    prop_imp_L{i,1}(:,1) = trapz(temp2(temp2>0))/(mass*Fs);
    brake_imp_L{i,1}(:,1) = trapz(temp1(temp1<0))/(mass*Fs);
    peak_brake_L{i,1}(:,1) = min(temp1)/mass;
    peak_prop_L{i,1}(:,1) = max(temp2)/mass;
    
    temp = -fr{i,1}(:,2);
    temp2 = temp(round(length(temp)/4):end); % make sure we are only taking prop at TO
    brake_imp_R{i,1}(:,1) = trapz(temp2(temp2<0))/(mass*Fs);
    peak_brake_R{i,1}(:,1) = min(temp)/mass;
    [~, indexr] = min(temp);

    temp1 = temp(1:round(length(temp)/4)); % make sure we are only taking prop at TO
    temp3 = temp(indexr:end); % make sure we are only taking prop at TO
    prop_imp_R{i,1}(:,1) = trapz(temp1(temp1>0))/(mass*Fs) + trapz(temp3(temp3>0))/(mass*Fs);
    peak_prop_R{i,1}(:,1) = max(temp1)/mass;
    
    % velocity of the center of mass.
    % medio-lateral velocity
    vcom{i,1}(:,1) = (cumtrapz(ftot{i,1}(:,1))/(mass*Fs));
    vcom{i,1}(:,1) = vcom{i,1}(:,1) - mean(vcom{i,1}(:,1));
    % fore-aft velcoity
    vcom{i,1}(:,2) = (cumtrapz(ftot{i,1}(:,2))/(mass*Fs));
    vcom{i,1}(:,2) = vcom{i,1}(:,2) - mean(vcom{i,1}(:,2));
    % vertical velocity
    vcom{i,1}(:,3) = (cumtrapz(ftot{i,1}(:,3)-(mass*g))/(mass*Fs));
    vcom{i,1}(:,3) = vcom{i,1}(:,3) - mean(vcom{i,1}(:,3));
    
    vcomy_tot(i,1) = mean(vcom{i,1}(:,2));
    vcomz_tot(i,1) = mean(vcom{i,1}(:,3));
    
    % CoM displacement
    dcom{i,1}(:,1) = cumtrapz(vcom{i,1}(:,1))/Fs;
    dcom{i,1}(:,2) = cumtrapz(vcom{i,1}(:,2))/Fs;
    dcom{i,1}(:,3) = cumtrapz(vcom{i,1}(:,3))/Fs;
    
    % velocity of the left belt
    vltread{i,1}(:,1) = zeros(length(ftot{i,1}(:,1)),1);
    vltread{i,1}(:,2) = ones(length(ftot{i,1}(:,1)),1) * speedL;
    vltread{i,1}(:,3) = zeros(length(ftot{i,1}(:,1)),1);
    
    % velocity of the right belt
    vrtread{i,1}(:,1) = zeros(length(ftot{i,1}(:,1)),1);
    vrtread{i,1}(:,2) = ones(length(ftot{i,1}(:,1)),1) * speedR;
    vrtread{i,1}(:,3) = zeros(length(ftot{i,1}(:,1)),1);
    
    % compute external mechanical power
    plcom{i,1} = dot(fl{i,1}(:,1:3),vcom{i,1}(:,1:3),2);
    prcom{i,1} = dot(fr{i,1}(:,1:3),vcom{i,1}(:,1:3),2);
    pltread{i,1} = dot(fl{i,1}(:,1:3),vltread{i,1}(:,1:3),2);
    prtread{i,1} = dot(fr{i,1}(:,1:3),vrtread{i,1}(:,1:3),2);
    pl{i,1} = plcom{i} + pltread{i};
    pr{i,1} = prcom{i} + prtread{i};
    
%     plot(plcom{i,1},'r-');hold on
%     plot(pltread{i,1},'g-')
%     plot(pl{i,1},'b-')
end

n=1;
for m=1:length(dcom)
    if isnan(rStepIndperStride(m))|| rStepIndperStride(m)==0, continue; end
    dFastStep{n}.com = dcom{m}(1:rStepIndperStride(m),1:3);
    dSlowStep{n}.com = dcom{m}(rStepIndperStride(m):end,1:3);
    n=n+1;
end

vStride.com = vcom;
vStride.ltread = vltread;
vStride.rtread = vrtread;
pStride.lcom = plcom;
pStride.rcom = prcom;
pStride.ltread = pltread;
pStride.rtread = prtread;
pStride.l = pl;
pStride.r = pr;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to compute work
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [workRate21,avgWorkRate21,wnet,wnetRate] = workperStride(pStride,tStride,Fs)

     
   
%% Compute work done per stride
for q=1:length(pStride.lcom)
    plcomstride = pStride.lcom{q};
    prcomstride = pStride.rcom{q};
    pltreadstride = pStride.ltread{q};
    prtreadstride = pStride.rtread{q};
    plstride = pStride.l{q};
    prstride = pStride.r{q};
    
    wlcompos(q) = trapz(plcomstride(plcomstride>0))*(1/Fs);
    wlcomneg(q) = trapz(plcomstride(plcomstride<0))*(1/Fs);
    
    wrcompos(q) = trapz(prcomstride(prcomstride>0))*(1/Fs);
    wrcomneg(q) = trapz(prcomstride(prcomstride<0))*(1/Fs);
    
    wltreadpos(q) = trapz(pltreadstride(pltreadstride>0))*(1/Fs);
    wltreadneg(q) = trapz(pltreadstride(pltreadstride<0))*(1/Fs);
    
    wrtreadpos(q) = trapz(prtreadstride(prtreadstride>0))*(1/Fs);
    wrtreadneg(q) = trapz(prtreadstride(prtreadstride<0))*(1/Fs);
    
    wlpos(q) = trapz(plstride(plstride>0))*(1/Fs);
    wlneg(q) = trapz(plstride(plstride<0))*(1/Fs);
    
    wrpos(q) = trapz(prstride(prstride>0))*(1/Fs);
    wrneg(q) = trapz(prstride(prstride<0))*(1/Fs);
    
    wtotpos(q) = wlpos(q)+wrpos(q);
    wtotneg(q) = wlneg(q)+wrneg(q);
    wtotposRate(q) = wtotpos(q)/tStride(q);
    wtotnegRate(q) = wtotneg(q)/tStride(q);

    wnet(q) = wtotpos(q) + wtotneg(q);
    wnetRate(q) = wnet(q)/tStride(q);
    
    %work rate by individual legs
    wlposRate(q) = wlpos(q)/tStride(q);
    wlnegRate(q) = wlneg(q)/tStride(q);
    wrposRate(q) = wrpos(q)/tStride(q);
    wrnegRate(q) = wrneg(q)/tStride(q);
    
    wltreadposRate(q) = wltreadpos(q)/tStride(q);
    wltreadnegRate(q) = wltreadneg(q)/tStride(q);
    wrtreadposRate(q) = wrtreadpos(q)/tStride(q);
    wrtreadnegRate(q) = wrtreadneg(q)/tStride(q);
    
    %work done by leg on belt
    wtreadpos(q) = wltreadpos(q)+wrtreadpos(q);
    wtreadneg(q) = wltreadneg(q)+wrtreadneg(q);
    wnettread(q) = wtreadpos(q)+wtreadneg(q);
    
    wtreadposRate(q) = wtreadpos(q)/tStride(q);
    wtreadnegRate(q) = wtreadneg(q)/tStride(q);
    wnettreadRate(q) = wnettread(q)/tStride(q);
    
    %work done by leg on com
    wcompos(q) = wlcompos(q)+wrcompos(q);
    wcomneg(q) = wlcomneg(q)+wrcomneg(q);
    wnetcom(q) = wcompos(q)+wcomneg(q);
    
    wcomposRate(q) = wcompos(q)/tStride(q);
    wcomnegRate(q) = wcomneg(q)/tStride(q);
    wnetcomRate(q) = wnetcom(q)/tStride(q);
end
% average the work done across all strides.
% avgwork.lcompos = mean(wlcompos);
% avgwork.lcomneg = mean(wlcomneg);
% 
% avgwork.rcompos = mean(wrcompos);
% avgwork.rcomneg = mean(wrcomneg);
% 
% avgwork.ltreadpos = mean(wltreadpos);
% avgwork.ltreadneg = mean(wltreadneg);
% 
% avgwork.rtreadpos = mean(wrtreadpos);
% avgwork.rtreadneg = mean(wrtreadneg);
% 
% avgwork.lpos = mean(wlpos);
% avgwork.lneg = mean(wlneg);
% 
% avgwork.rpos = mean(wrpos);
% avgwork.rneg = mean(wrneg);
% 
% avgwork.totpos = mean(wtotpos);
% avgwork.totneg = mean(wtotneg);
% 
% avgwork.net = mean(wnet);
% avgwork.nettread = mean(wnettread);
% avgwork.netcom = mean(wnetcom);
% avgwork.treadpos = mean(wtreadpos);
% avgwork.compos = mean(wcompos);
% avgwork.treadneg = mean(wtreadneg);
% avgwork.comneg = mean(wcomneg);
% 
% avgworkRate.net = mean(wnetRate);
% avgworkRate.totpos = mean(wtotposRate);
% avgworkRate.totneg = mean(wtotnegRate);
% avgworkRate.nettread = mean(wnettreadRate);
% avgworkRate.netcom = mean(wnetcomRate);
% avgworkRate.treadpos = mean(wtreadposRate);
% avgworkRate.compos = mean(wcomposRate);
% avgworkRate.treadneg = mean(wtreadnegRate);
% avgworkRate.comneg = mean(wcomnegRate);
% avgworkRate.lpos = mean(wlposRate);
% avgworkRate.lneg = mean(wlnegRate);
% avgworkRate.rpos = mean(wrposRate);
% avgworkRate.rneg = mean(wrnegRate);
% avgworkRate.ltreadpos = mean(wltreadposRate);
% avgworkRate.ltreadneg = mean(wltreadnegRate);
% avgworkRate.rtreadpos = mean(wrtreadposRate);
% avgworkRate.rtreadneg = mean(wrtreadnegRate);

%% average work rate: done across the first 21 strides (before perturbations begin)
workRate21.net = (wnetRate(1:21));
workRate21.totpos = (wtotposRate(1:21));
workRate21.totneg = (wtotnegRate(1:21));
workRate21.lpos = (wlposRate(1:21));
workRate21.lneg = (wlnegRate(1:21));
workRate21.rpos = (wrposRate(1:21));
workRate21.rneg = (wrnegRate(1:21));

workRate21.nettread = (wnettreadRate(1:21));
workRate21.treadpos = (wtreadposRate(1:21));
workRate21.treadneg = (wtreadnegRate(1:21));
workRate21.ltreadpos = (wltreadposRate(1:21));
workRate21.ltreadneg = (wltreadnegRate(1:21));
workRate21.rtreadpos = (wrtreadposRate(1:21));
workRate21.rtreadneg = (wrtreadnegRate(1:21));

workRate21.netcom = (wnetcomRate(1:21));
workRate21.compos = (wcomposRate(1:21));
workRate21.comneg = (wcomnegRate(1:21));
% workRate21.lcompos = (wlcomposRate(1:21));
% workRate21.lcomneg = (wlcomnegRate(1:21));
% workRate21.rcompos = (wrcomposRate(1:21));
% workRate21.rcomneg = (wrcomnegRate(1:21));

% average 
avgWorkRate21.net = mean(wnetRate(1:21));
avgWorkRate21.totpos = mean(wtotposRate(1:21));
avgWorkRate21.totneg = mean(wtotnegRate(1:21));
avgWorkRate21.lpos = mean(wlposRate(1:21));
avgWorkRate21.lneg = mean(wlnegRate(1:21));
avgWorkRate21.rpos = mean(wrposRate(1:21));
avgWorkRate21.rneg = mean(wrnegRate(1:21));

avgWorkRate21.nettread = mean(wnettreadRate(1:21));
avgWorkRate21.treadpos = mean(wtreadposRate(1:21));
avgWorkRate21.treadneg = mean(wtreadnegRate(1:21));
avgWorkRate21.ltreadpos = mean(wltreadposRate(1:21));
avgWorkRate21.ltreadneg = mean(wltreadnegRate(1:21));
avgWorkRate21.rtreadpos = mean(wrtreadposRate(1:21));
avgWorkRate21.rtreadneg = mean(wrtreadnegRate(1:21));

avgWorkRate21.netcom = mean(wnetcomRate(1:21));
avgWorkRate21.compos = mean(wcomposRate(1:21));
avgWorkRate21.comneg = mean(wcomnegRate(1:21));
% avgWorkRate21.lcompos = mean(wlcomposRate(1:21));
% avgWorkRate21.lcomneg = mean(wlcomnegRate(1:21));
% avgWorkRate21.rcompos = mean(wrcomposRate(1:21));
% avgWorkRate21.rcomneg = mean(wrcomnegRate(1:21));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calcualte the average step length asymmetry (SLA) for each trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanSLA] = computeSLA(t_force,strideEndInd,t_lHS_kinematics,SLA)
t_force_LstrideStart = t_force(strideEndInd);

% i'm comparing the time for each left heel strike according to
% kinematic data with the time for when i detect heel strike using
% GRF. i find the kinematics time that matches closest to the time
% i get from GRF and store the Step Length Asymmetry (SLA) for the
% step immediately preceeding that time to be that what is given by
% the kinematics data. Sometimes I think that the kinenmatics
% misses a heel strike since i detect a heel strike but there is no
% time to go with it from the kinematics data. Then, i store a NaN
% for that stride.
for q=1:length(t_force_LstrideStart)
    for r=1:length(t_lHS_kinematics)
        if (abs(t_force_LstrideStart(q)-t_lHS_kinematics(r))<0.1) && r>1
            SLA_forceAligned(q) = SLA(r-1);
            break;
        else SLA_forceAligned(q) = NaN;
        end
    end
end
[~,slaAvgBegin] = min(abs(t_force_LstrideStart-(t_force_LstrideStart(end)-(3*60))));
meanSLA = nanmean(SLA_forceAligned(slaAvgBegin:end));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calcualte the average step length asymmetry (SLA) for each trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sla_fp,totalSL,lStepLength,rStepLength] = computeSL(cop,lStrideEndIndGood,rStrideEndIndGood)

% lStepLength=abs(stepLength.L);
% rStepLength=abs(stepLength.R);
for i=1:length(lStrideEndIndGood)
    lStepLength(i) = cop.L(lStrideEndIndGood(i))-cop.R(lStrideEndIndGood(i));
    rStepLength(i) = cop.R(rStrideEndIndGood(i))-cop.L(rStrideEndIndGood(i));
    totalSL(i) = lStepLength(i)+rStepLength(i);
    sla_fp(i) = (lStepLength(i)-rStepLength(i))/totalSL(i);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to calcualte the metabolic power for each trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [RER,Emet, Pmet] = computeMetPower(t_met, VO2, VCO2,Dur)
% if ~exist('Dur','var'), Dur = 3; end
% [~,metAvgBegin] = min(abs(t_met-(t_met(end)-Dur)));
% VO2tot = VO2(end)-VO2(metAvgBegin);
% VCO2tot = VCO2(end)-VCO2(metAvgBegin);
% Emet = (VO2tot*1000*16.48) + (VCO2tot*1000*4.48);
% Tavg = ((t_met(end)-t_met(metAvgBegin))*60);
% Pmet = Emet/Tavg;
% RER = VCO2tot/VO2tot;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to interpolate and compute average (across last 100 strides) force, velocity and power within a stride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [avgforce,avgvel,avgpower] = computeStrideAvg(m,fStride,vStride,pStride,Fs,test,fn,trialData)

fl = fStride.l;
fr = fStride.r;
vcom = vStride.com;
vltread = vStride.ltread;
vrtread = vStride.rtread;
plcom = pStride.lcom;
prcom = pStride.rcom;
pltread = pStride.ltread;
prtread = pStride.rtread;
pl = pStride.l;
pr = pStride.r;

% Preallocate
flxinterp=zeros(1000,length(plcom)); frxinterp=zeros(1000,length(plcom));
flyinterp=zeros(1000,length(plcom)); fryinterp=zeros(1000,length(plcom));
flzinterp=zeros(1000,length(plcom)); frzinterp=zeros(1000,length(plcom));
vxcominterp=zeros(1000,length(plcom)); vlxtreadinterp=zeros(1000,length(plcom));
vrxtreadinterp=zeros(1000,length(plcom)); vycominterp=zeros(1000,length(plcom));
vlytreadinterp=zeros(1000,length(plcom)); vrytreadinterp=zeros(1000,length(plcom));
vzcominterp=zeros(1000,length(plcom)); vlztreadinterp=zeros(1000,length(plcom));
vrztreadinterp=zeros(1000,length(plcom)); plcominterp=zeros(1000,length(plcom));
prcominterp=zeros(1000,length(plcom)); pltreadinterp=zeros(1000,length(plcom));
prtreadinterp=zeros(1000,length(plcom)); plinterp=zeros(1000,length(plcom));
printerp=zeros(1000,length(plcom)); tvals=zeros(1000,length(plcom));


for i=1:length(plcom)
    % This stores the power over a stride from a cell array to a double to
    % make calcuations easier.
    plcomstride = plcom{i};
    prcomstride = prcom{i};
    pltreadstride = pltread{i};
    prtreadstride = prtread{i};
    plstride = pl{i};
    prstride = pr{i};
    
    flxstride = fl{i}(:,1);
    frxstride = fr{i}(:,1);
    flystride = fl{i}(:,2);
    frystride = fr{i}(:,2);
    flzstride = fl{i}(:,3);
    frzstride = fr{i}(:,3);
    
    vxcomstride = vcom{i}(:,1);
    vlxtreadstride = vltread{i}(:,1);
    vrxtreadstride = vrtread{i}(:,1);
    vycomstride = vcom{i}(:,2);
    vlytreadstride = vltread{i}(:,2);
    vrytreadstride = vrtread{i}(:,2);
    vzcomstride = vcom{i}(:,3);
    vlztreadstride = vltread{i}(:,3);
    vrztreadstride = vrtread{i}(:,3);
    
    strideLen = length(frzstride)-1;
    tvals(:,i) = linspace(0,strideLen,1000);
    
    % This is interpolating across a stride to contain 1000 points.
    flxinterp(:,i) = interp1(flxstride,tvals(:,i));
    frxinterp(:,i) = interp1(frxstride,tvals(:,i));
    flyinterp(:,i) = interp1(flystride,tvals(:,i));
    fryinterp(:,i) = interp1(frystride,tvals(:,i));
    flzinterp(:,i) = interp1(flzstride,tvals(:,i));
    frzinterp(:,i) = interp1(frzstride,tvals(:,i));
    
    vxcominterp(:,i) = interp1(vxcomstride,tvals(:,i));
    vlxtreadinterp(:,i) = interp1(vlxtreadstride,tvals(:,i));
    vrxtreadinterp(:,i) = interp1(vrxtreadstride,tvals(:,i));
    vycominterp(:,i) = interp1(vycomstride,tvals(:,i));
    vlytreadinterp(:,i) = interp1(vlytreadstride,tvals(:,i));
    vrytreadinterp(:,i) = interp1(vrytreadstride,tvals(:,i));
    vzcominterp(:,i) = interp1(vzcomstride,tvals(:,i));
    vlztreadinterp(:,i) = interp1(vlztreadstride,tvals(:,i));
    vrztreadinterp(:,i) = interp1(vrztreadstride,tvals(:,i));
    
    plcominterp(:,i) = interp1(plcomstride,tvals(:,i));
    prcominterp(:,i) = interp1(prcomstride,tvals(:,i));
    pltreadinterp(:,i) = interp1(pltreadstride,tvals(:,i));
    prtreadinterp(:,i) = interp1(prtreadstride,tvals(:,i));
    plinterp(:,i) = interp1(plstride,tvals(:,i));
    printerp(:,i) = interp1(prstride,tvals(:,i));
end

%% Calculating average values of power over a stride

avgforce.lx = mean(flxinterp(:,end-100:end),2);
avgforce.rx = mean(frxinterp(:,end-100:end),2);
avgforce.ly = mean(flyinterp(:,end-100:end),2);
avgforce.ry = mean(fryinterp(:,end-100:end),2);
avgforce.lz = mean(flzinterp(:,end-100:end),2);
avgforce.rz = mean(frzinterp(:,end-100:end),2);

avgvel.xcom = mean(vxcominterp(:,end-100:end),2);
avgvel.lxtread = mean(vlxtreadinterp(:,end-100:end),2);
avgvel.rxtread = mean(vrxtreadinterp(:,end-100:end),2);
avgvel.ycom = mean(vycominterp(:,end-100:end),2);
avgvel.lytread = mean(vlytreadinterp(:,end-100:end),2);
avgvel.rytread = mean(vrytreadinterp(:,end-100:end),2);
avgvel.zcom = mean(vzcominterp(:,end-100:end),2);
avgvel.lztread = mean(vlztreadinterp(:,end-100:end),2);
avgvel.rztread = mean(vrztreadinterp(:,end-100:end),2);

avgpower.lcom = mean(plcominterp(:,end-100:end),2);
avgpower.rcom = mean(prcominterp(:,end-100:end),2);
avgpower.ltread = mean(pltreadinterp(:,end-100:end),2);
avgpower.rtread = mean(prtreadinterp(:,end-100:end),2);
avgpower.l = mean(plinterp(:,end-100:end),2);
avgpower.r = mean(printerp(:,end-100:end),2);

if test.fvpInterpPlot==1
    % Plot the positive, negative, and net power from slow and fast belts
    xvals = linspace(0,1,1000);
    figure(m); hold on;
    subplot(3,2,1); hold on; title(strcat(fn,trialData,'Left'))
    plot(xvals,avgforce.lx,'r-');
    plot(xvals,avgforce.ly,'g-');
    plot(xvals,avgforce.lz,'b-');
    ylabel('Force (N)'); ylim([-200 900])
    legend('x','y','z')
    
    subplot(3,2,2); hold on; title(strcat(fn,trialData,'Right'))
    plot(xvals,avgforce.rx,'r-');
    plot(xvals,avgforce.ry,'g-');
    plot(xvals,avgforce.rz,'b-');
    ylabel('Force (N)'); ylim([-200 900])
    legend('x','y','z')
    
    subplot(3,2,3); hold on
    plot(xvals,avgvel.xcom,'r-');
    plot(xvals,avgvel.ycom,'g-');
    plot(xvals,avgvel.zcom,'b-');
    plot(xvals,avgvel.lytread,'g-');
    ylabel('Velocity (m/s)'); ylim([-0.5 1.5])
    legend('x','y','z')
    
    subplot(3,2,4); hold on
    plot(xvals,avgvel.xcom,'r-');
    plot(xvals,avgvel.ycom,'g-');
    plot(xvals,avgvel.zcom,'b-');
    plot(xvals,avgvel.rytread,'g-');
    ylabel('Velocity (m/s)'); ylim([-0.5 1.5])
    legend('x','y','z')
    
    subplot(3,2,5); hold on
    plot(xvals,avgpower.l,'r-');
%     plot(xvals,avgpower.lcom,'g-');
%     plot(xvals,avgpower.ltread,'b-');
    ylabel('Power (W)'); ylim([-300 200])
    xlabel('Fraction of Stride')
    
    subplot(3,2,6); hold on
    plot(xvals,avgpower.r,'r-')
%     plot(xvals,avgpower.rcom,'g-')
%     plot(xvals,avgpower.rtread,'b-')
    ylabel('Power (W)'); ylim([-300 200]); pause
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to plot the fvp time series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fvpTimeSeries(fStride,vStride,pStride)
% This can be used to trouble shoot by looking at individual FVP
% plots for each subject. Choose fvpplot = 1 at the beginning if
% you want to look at this.
% Combine all stride by stride values into a vector for easy
% plotting. Note that the _all variables only store one trial at a
% time. So, the final workspace varibale will only have the data of
% the final trial but the individual variables store the data from
% each trial.
fl_all=[]; fr_all=[];vcom_all=[];vltread_all=[];vrtread_all=[];plcom_all=[];
prcom_all=[];pltread_all=[];prtread_all=[];pl_all=[];pr_all=[];
meanPowerLPerStride=[];meanPowerRPerStride=[];
for n=1:length(pStride.l)
    fl_all = [fl_all;fStride.l{n,:}];
    fr_all = [fr_all;fStride.r{n,:}];
    vcom_all = [vcom_all;vStride.com{n,1}];
    vltread_all = [vltread_all;vStride.ltread{n,1}];
    vrtread_all = [vrtread_all;vStride.rtread{n,1}];
    plcom_all = [plcom_all;pStride.lcom{n,1}];
    prcom_all = [prcom_all;pStride.rcom{n,1}];
    pltread_all = [pltread_all;pStride.ltread{n,1}];
    prtread_all = [prtread_all;pStride.rtread{n,1}];
    pl_all = [pl_all;pStride.l{n,1}];
    pr_all = [pr_all;pStride.r{n,1}];
    meanPowerLPerStride = [meanPowerLPerStride;mean((pStride.l{n,1}))];
    meanPowerRPerStride = [meanPowerRPerStride;mean((pStride.r{n,1}))];
end
ftot_all = fl_all+fr_all;
plcom_all = [plcom_all];
prcom_all = [prcom_all];
pltread_all = [pltread_all];
prtread_all = [prtread_all];
pl_all = [pl_all];
pr_all = [pr_all];

figure(1); clf; hold on;
subplot(3,2,1); hold on; grid on; ylim([-200 900]); grid on; 
plot(fl_all(:,1),'r-')
plot(fl_all(:,2),'g-')
plot(fl_all(:,3),'b-')
ylabel('Force (N)');
legend('x','y','z')
subplot(3,2,2); hold on; grid on; ylim([-200 900]); grid on;
plot(fr_all(:,1),'r-')
plot(fr_all(:,2),'g-')
plot(fr_all(:,3),'b-')
ylabel('Force (N)');
subplot(3,2,3); hold on; grid on; ylim([-1.5 0.5]); grid on; 
plot(vcom_all(:,1),'r-')
plot(vcom_all(:,2),'g-')
plot(vcom_all(:,3),'b-')
plot(vltread_all(:,2),'g--')
ylabel('Velocity (m/s)')
subplot(3,2,4); hold on; grid on; ylim([-1.5 0.5]); grid on; 
plot(vcom_all(:,1),'r-')
plot(vcom_all(:,2),'g-')
plot(vcom_all(:,3),'b-')
plot(vrtread_all(:,2),'g--')
ylabel('Velocity (m/s)')
subplot(3,2,5); hold on; grid on; ylim([-300 200]); grid on; 
plot(pl_all(:,1),'r-');
%         plot(plcom_all(:,1),'r-');
ylabel('Velocity (m/s)')
ylabel('Power')
subplot(3,2,6); hold on; grid on; ylim([-300 200]); grid on; 
plot(pr_all(:,1),'r-');
%         plot(prcom_all(:,1),'r-');
ylabel('Power')
pause

end