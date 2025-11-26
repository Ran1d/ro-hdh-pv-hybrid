% CPV/T subsystem code
clc
clear
close all
format shortG

%% Input data
II = [500 600 700 800]; % solar radiation (W/m^2)
Ta = 20; % ambient temperature (C)
flow_rate = [0.011 0.013 0.016 0.02 0.024 0.027 0.029 0.032 0.035 0.038 0.041]; % mass flow rate (kg/sec)
T_in = [50.9 47.22 45 43.78 41.22 41.12 40.96 40.91 40.88 40.82 39];% inlet fluid temperature
tilt = 15; % tilt angle degree

% experimental results
Tc1 = [50.15 50.04 49.56 48.84 48.53 48.17 48.35 48.06 47.85 47.67 47.28;...
       51.75 51.34 50.86 50.47 49.95 49.63 49.46 49.38 48.99 48.76 48.50;...
       52.95 52.54 51.93 51.36 50.74 50.57 50.15 49.94 49.63 49.47 49.22;...
       53.64 53.25 52.86 52.13 51.56 51.04 51.03 50.66 50.23 50.06 49.89];
To_pvt1 = [62.57 58.67 56.36 55.08 52.5 52 51.5 50.93 50.63 50.48 50.32];

%% System Specifications
Ta = Ta+273;
T_in = T_in+273;
L_rd = 1; % module length (m)
W_rd = .65; % module width (m)
A_rd = L_rd*W_rd; % module area (m^2)
effi_c = .14; % PV cell efficiency at STC
taw_c=.95; % PV tansmittance
alpha_c =.85; % PV absorptivity
beta_c =.83; % from table 2 (paper: Hybrid Photovoltaic Thermal PVT Solar Systems Simulation via Simulink/Matlab)
alpha_p = .8; % absrober absorptivity
taw_PET = .88; % from table 2 (paper: Hybrid Photovoltaic Thermal PVT Solar Systems Simulation via Simulink/Matlab)
E_p = 0.95; % abrorber emissivity
E_g = .87; % glass emissivity
taw_glass = 0.9; % glass tansmittance
N =1; % numer of glass covers
Vw = 1; % wind speed
spacing = .02215; % the space between the abrorber tubes (m)
Do = 0.0127; % outter diameter (m)
Di = .01189; % inner diameter (m)
cond_copper = 401; % thermal conductivity of the abrorber
thick_copper = 0.002; % thickness of the absorber plate
Cp= 4190; % water heat capacity (J/(kg.k))
hpf = 100; % from table 2 (paper: Hybrid Photovoltaic Thermal PVT Solar Systems Simulation via Simulink/Matlab)
hfi = 333; % from table 2 (paper: Hybrid Photovoltaic Thermal PVT Solar Systems Simulation via Simulink/Matlab)
k_ins = .045; % from table 2 (paper:Performance analysis of photovoltaic thermal (PVT) water collectors)
thick_ins_back = .05;
thick_ins_edge = .025; % from table 2 (paper:Performance analysis of photovoltaic thermal (PVT) water collectors)
thick_collecter = (50+1.5+25+2.5)/1000;
sb= 5.67*10^-8; % stefan-boltz man constant

%% PVT performance
I = II.*cosd(tilt); % insolation on tilted surface
P = 2*L_rd+2*W_rd; % module perimeter (m)
Ue = (k_ins/thick_ins_edge)*P*thick_collecter/A_rd; %eqn 11
Utc_a = 2.8+3.*Vw; %eqn 25
alpha_taw_1 = taw_c.*(alpha_c-effi_c).*beta_c; %eqn 24
alpha_taw_2 = alpha_p.*(1-beta_c).*taw_PET.^2; %eqn 27
hw = 8.6.*Vw.^.6./1.14.^.4; % form book : eqn 3.28
for ii = 1:length(II)
    hcp = (50.*flow_rate+7.95).*(I(ii)./900)-(T_in./373).*.15; % eqn 26
    Ul1 = (Utc_a.*hcp)./(Utc_a+hcp); %eqn 28
    PF1 = Ul1./Utc_a; %eqn 29
    Tp = ((alpha_taw_2.*I(ii) + PF1.*alpha_taw_1.*I(ii) + Ul1.*Ta + hpf.*294)./(hpf+Ul1)); %eqn 19
    Tc = ((alpha_taw_1.*I(ii) + Utc_a.*Ta + hcp.*Tp)./(Utc_a+hcp)); %eqn 18
    effi_elec_pvt = effi_c.*(1-.0045.*(Tc-273-25)); %eqn 21
    f = (1+.089.*hw-.1166.*hw.*E_p).*(1+.07866.*N); %eqn 15
    e = .043.*(1-100./(Tp));%eqn 16
    C =520.*(1-.000051.*tilt.^2-(945.774767.*flow_rate+0.031365.*(T_in-273)));%eqn 14
    UL = real(1./((N)./((C./(Tp.*((Tp-Ta)./(N+f)).^e))+(1./hw))) + (sb.*(Tp+Ta).*(Tp.^2+Ta.^2))./((1./(E_p+.00591.*N.*hw))+((2.*N+f+.133.*E_p)./taw_PET)-N))+Ue; %eqn 13
    M = sqrt(UL./(cond_copper.*thick_copper)); %eqn 8
    F = tanh(M.*(spacing-Do)./2)./(M.*(spacing-Do)./2);%eqn 7
    F_prime = (1./UL)./(spacing.*((1./(UL.*(Do+F.*(spacing-Do))))+(1./(pi.*Di.*hfi))));%eqn 6
    FR = flow_rate.*Cp./(A_rd.*UL).*(1-exp(-(A_rd.*UL.*F_prime)./(flow_rate.*Cp)));%eqn 5
    Qu_pvt = FR.*A_rd.*(I(ii).*1.*taw_c.*alpha_c-UL.*(T_in-Ta));%eqn 4
    Tc2(ii,:)=Tc-273;
    To_pvt2(ii,:) = Qu_pvt./(flow_rate.*Cp)+T_in-273;%eqn 3
end
To_pvt2 = To_pvt2(end,:);

%% plot results
figure
hold on
ax3=gca;
ax3.FontName='Times';
ax3.FontSize = 14;
ax3.FontWeight = 'bold';
ax3.XLim = [0 .041+.011];
ax3.YLim = [0 100];
ax3.YColor = 'k';
xlabel(ax3,'Mass flow rate [kg/sec]','fontsize',14,'fontweight','bold','FontName', 'Times')
ylabel(ax3,'PV cell temperature [^{\circ}C]','fontsize',14,'fontweight','bold','FontName', 'Times')
plot1= line(flow_rate,Tc2(4,:),'Color','r','DisplayName','simulation','linewidth',2,'LineStyle','','Marker','d');
plot11= line(flow_rate,Tc1(4,:),'Color','b','DisplayName','experimental','linewidth',2,'LineStyle','','Marker','s');
legend
Tc3 = Tc1(4,:);
Tc4 = Tc2(4,:);
error = abs(Tc3-Tc4)./Tc3.*100;
data=[flow_rate' T_in'-273 Tc3' Tc4' error'];

figure
uit= uitable;
uit.Data = data;
uit.ColumnName = {'mass flow rate [kg/sec]';'Inlet temp. [C]';'PV temp. [C], Exp.';'PV temp. [C], Sim.';'Error [%]'} ;
uit.RowName = {};
uit.Position = [70 100 480 250];

figure
hold on
ax4=gca;
ax4.FontName='Times';
ax4.FontSize = 14;
ax4.FontWeight = 'bold';
ax4.XLim = [0 .041+.011];
ax4.YLim = [0 100];
xlabel(ax4,'Mass flow rate [kg/sec]','fontsize',14,'fontweight','bold','FontName', 'Times')
ylabel('Outlet fluid temperature [^{\circ}C]','FontName', 'Times')
plot2= line(flow_rate,To_pvt2,'Color','r','DisplayName','simulation','linewidth',2,'LineStyle','','Marker','d');
plot22= line(flow_rate,To_pvt1,'Color','b','DisplayName','experimental','linewidth',2,'LineStyle',':','Marker','s');
legend
error = abs(To_pvt2-To_pvt1)./To_pvt1.*100;
data=[flow_rate' T_in'-273 To_pvt1' To_pvt2' error'];

figure
uit= uitable;
uit.Data = data;
uit.ColumnName = {'mass flow rate [kg/sec]';'Inlet temp. [C]';'Outlet temp. [C], Exp.';'Outlet temp. [C], Sim.';'Error [%]'} ;
uit.RowName = {};
uit.Position = [50 100 500 250];

figure
hold on
ax5=gca;
ax5.FontName='Times';
ax5.FontSize = 14;
ax5.FontWeight = 'bold';
ax5.XLim = [400 900];
ax5.YLim = [0 100];
ax5.Box ='off';
xlabel(ax5,'Solar radiation [W/m^{2}]','fontsize',14,'fontweight','bold','FontName', 'Times')
ylabel('PV cell temperature [^{\circ}C]','FontName', 'Times')
plot2= line(I,Tc2(:,end),'Color','r','DisplayName','simulation','linewidth',2,'LineStyle','','Marker','d');
plot22= line(I,Tc1(:,end),'Color','b','DisplayName','experimental','linewidth',2,'LineStyle',':','Marker','s' );
Tc3 = Tc1(:,end);
Tc4 = Tc2(:,end);
T_in =[39 39 39 39];
error = abs(Tc3-Tc4)./Tc3.*100;
data=[II' T_in' Tc3 Tc4 error];

figure
uit= uitable;
uit.Data = data;
uit.ColumnName = {'Solar radiation [W/m^2]';'Inlet temp. [C]';'PV temp. [C], Exp.';'PV temp. [C], Sim.';'Error [%]'} ;
uit.RowName = {};
uit.Position = [70 200 480 100];
