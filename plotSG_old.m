function plotSG(fileNames, initTime)


x=[];
y=[];
for i=1:length(fileNames)
    a = importdata([fileNames{i} '\SG.fig']);
    x = [x a.children.children(1).properties.XData];
    y = [y a.children.children(1).properties.YData];
end

y = y';
x = x';
[pathstr, name, ext, versn] = fileparts(fileNames{1});
name = [name ext];
% x = x*1e-6;
x = (x-min(x))*1e-6;
y = y/100;
if nargin == 2
    y = y(x>initTime);
    x = x(x>initTime);
    x = x-initTime;
end

f = figure;
plot(x, y, 'Marker', 'o', 'LineWidth',2, 'LineStyle', 'none', 'DisplayName', name);

% --- Create fit
% fo_ = fitoptions('method','NonlinearLeastSquares','Lower',[0 0 0],'Upper',[Inf   1 Inf]);
fo_ = fitoptions('method','NonlinearLeastSquares', 'Robust', 'Bisquare','Lower',[0 0 0],'Upper',[Inf   1 Inf]);
ok_ = isfinite(x) & isfinite(y);
if ~all( ok_ )
    warning( 'GenerateMFile:IgnoringNansAndInfs', ...
        'Ignoring NaNs and Infs in data' );
end
st_ = [1.4 0.1 1];
set(fo_,'Startpoint',st_);
ft_ = fittype('(-2+f0*(1+3/2*b+b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2))+exp(g*x*sqrt((3/2*b)^2+2*3/2*b*(-1+b)+(1+b)^2))*(2-f0*(1+3/2*b+b)+f0*sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2))) / (-1+(-1+2*f0)*3/2*b-b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2)+exp(g*x*sqrt((3/2*b)^2+2*3/2*b*(-1+b)+(1+b)^2))*(1+3/2*b-2*f0*3/2*b+b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2)))',...
     'dependent',{'y'},'independent',{'x'},...
     'coefficients',{'b', 'f0', 'g'});
 
%  ft_ = fittype('(-2+0.07*(1+3/2*b+b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2))+exp(g*(x+f0)*sqrt((3/2*b)^2+2*3/2*b*(-1+b)+(1+b)^2))*(2-0.07*(1+3/2*b+b)+0.07*sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2))) / (-1+(-1+2*0.07)*3/2*b-b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2)+exp(g*(x+f0)*sqrt((3/2*b)^2+2*3/2*b*(-1+b)+(1+b)^2))*(1+3/2*b-2*0.07*3/2*b+b+sqrt((-1+3/2*b)^2+2*(1+3/2*b)*b+b^2)))',...
%      'dependent',{'y'},'independent',{'x'},...
%      'coefficients',{'b', 'f0', 'g'});

% Fit this model using new data
cf = fit(x(ok_),y(ok_),ft_,fo_);
conf = confint(cf);
fInf = 2 / (1+2.5*cf.b + sqrt(-6*cf.b + (1+2.5*cf.b)^2));
dfInf = 8 / ( -2*(2+sqrt(4+cf.b*(25*cf.b-4))) + cf.b*(4-25*cf.b+sqrt(4+cf.b*(25*cf.b-4))));

hold on
p = plot(cf, ['fit: ' name],  0.95);
set(p, 'LineWidth', 2);

hold off
legend(name, ['fit: ' name]);

text(x(2),mean(get(gca, 'YLim')), ...
    {'Coefficients:'; ...
    ['f_0 = ' num2str(cf.f0) ' +/- ' num2str(max(conf(:, 2))-cf.f0)]; ...
    ['\gamma = ' num2str(cf.g) ' +/- ' num2str(max(conf(:, 3))-cf.g)]; ...
    ['\beta = ' num2str(cf.b) ' +/- ' num2str( max(conf(:, 1))-cf.b)]; ... 
    ['     Saturation = ' num2str(fInf) '+/- ' num2str(abs(dfInf)*(max(conf(:, 1))-cf.b))]});
xlabel('time [s]');
ylabel('m_F1 part');

saveas(f, [fileNames{1} '\SG-fit_' name '.fig']);
saveas(f, [fileNames{1} '\SG-fit_' name '.emf']);

% alpha = 0.05;
% t = tinv(1-alpha/2,length(y)-3);
% se = (conf(:, 2)-conf(:,1)) ./ (2*t)
