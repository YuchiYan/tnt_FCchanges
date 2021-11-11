function R = DO(X,Y,C,P)
%% Data Organization
% 
% - Z.K.X. 2018/08/16
%----------------------------------------------------------------------------------------------%
%% Input
%-- X: independent variable (subjects * variates matrix)
%-- Y: dependent variable (subjects * 1 or subjects * variates matrix)
%-- C: control variable (subjects * variates matrix)
%-- P: parameters
%      [1] label (cell/string)
%                one column of cell array labels 
%      [2] outlier
%                   <1> tool (double)
%                             {1} 0 - no execute outlier detection (default)
%                             {2} 1 - execute outlier detection via Robust Correlation Toolbox 
%                                 (https://sourceforge.net/projects/robustcorrtool/)
%                             {3} 2 - execute outlier detection via MATLAB built-in function
%                   <2> method (string)
%                             /-------------     tool = 1     ----------/
%                             {1} 'boxplot' - relies on the interquartile range
%                             {2} 'MAD' - relies on the median of absolute distances
%                             {3} 'S-outlier' - relies on the median of absolute distances
%                             {4} 'All' - the 3 methods above will be computed (default)
%                             /-------------     tool = 2     ----------/
%                             {1} 'median'  
%                             {2} 'mean' (default)  
%                             {3} 'quartiles'  
%                             {4} 'grubbs'              
%                             {5} 'gesd' 
%                             (https://ww2.mathworks.cn/help/matlab/ref/isoutlier.html)
%                   <3> parameter (double)
%                             /-------------     tool = 1     ----------/
%                             {1} 1 - do univariate outliner detection
%                             ����Ƚϣ�����˭��˭��˭С
%                             {2} 2 - do bivariate outliner detection ˫��Ƚ�
%      [3] regress (double)
%                           {1} 0 - no execute regressing out covariates (default)
%                           {2} 1 - execute regressing out covariates
%      [4] normalize
%                   <1> method (string or [])
%                       {1} [] - no execute normalization (default)
%                       {2} 'rescale' 
%                       (http://ww2.mathworks.cn/help/matlab/ref/rescale.html)
%                       {3} 'standard' / 'scaling' ('StatisticalNormaliz.m')
%                   <2> parameter 
%                       {1} (http://ww2.mathworks.cn/help/matlab/ref/rescale.html)
%      [5] group (double)
%                percentage of grouping boundaries (default = 0.27)
%----------------------------------------------------------------------------------------------%
%% Output
%-- label: label of variates 
%-- outlier: 0/1 (1 means outliers)
%-- X: preprocessed X 
%-- Y: preprocessed Y
%-- order: 0/1/-1 (-1 means low group; 1 means high group)
%----------------------------------------------------------------------------------------------%
%% Default Setting 
%  nargin�������ж�������������ĺ����������Ϳ�����Բ�ͬ�����ִ�в�ͬ�Ĺ��ܡ�ͨ�������������趨һЩĬ��ֵ
if (nargin < 2)  %���ֻ����һ�������������ȫΪ1
	Y = ones(size(X,1),1);
end

if (nargin < 3)   %���ֻ��������������Э����Ϊ��
	C = [];
end

if (nargin < 4) | isempty(P)   %���ֻ��������������������X��Y��C�����ܼ���ֵ̽��
    P.label = [];
    P.outlier.tool = 0;
    P.regress = 0;
    P.normalize.method = [];
    P.group = 0.27;
else
    a = fieldnames(P);         %���в��������� fieldnames���ؽṹ������֣� ��������Ĵ��붼��ȥʶ����û��������������û�о���Ĭ�ϲ�����
    if isempty(find(strcmp(a,'label')))
        P.label = [];
    end
    if isempty(find(strcmp(a,'outlier')))
        P.outlier.tool = 0;
    elseif length(fieldnames(P.outlier)) == 1
        if P.outlier.tool == 1
            P.outlier.method = []; P.outlier.parameter = []; 
        elseif P.outlier.tool == 2
            P.outlier.method = 'mean'; P.outlier.parameter = []; 
        end
    elseif length(fieldnames(P.outlier)) == 2
        P.outlier.parameter = []; 
    end
    if isempty(find(strcmp(a,'regress')))
        P.regress = 0;
    end
    if isempty(find(strcmp(a,'normalize'))) 
        P.normalize.method = [];
    elseif length(fieldnames(P.normalize)) == 1
        if strcmp(P.normalize.method,'rescale')
            P.normalize.parameter = [0 1];
        end
    end
    if isempty(find(strcmp(a,'group')))
        P.group = 0.37; 
    end         
end

%% Feature Labeling
if isempty(P.label)
    for i = 1:size(X,2)
        R.label{i,1} = num2str(i);
    end
end

%% Outlier Detection
if P.outlier.tool == 1   %Dependency�����б��˵Ľű�
    [xx,y] = outlier_xy(X,Y,P.outlier.method,P.outlier.parameter);
    x = X; TF_x = zeros(size(X,1),size(X,2)); TF_x(isnan(xx)) = 1;
    TF_y = zeros(size(Y,1),size(Y,2)); TF_y(isnan(y)) = 1;
elseif P.outlier.tool == 2   %��Matlab�Խ��ĺ���
    if isempty(P.outlier.method)
        P.outlier.method = 'mean';
    end
    if isempty(P.outlier.parameter)   
        TF_x = isoutlier(X,P.outlier.method,1);  %����isoutlier
        TF_y = isoutlier(Y,P.outlier.method,1);
    else
        TF_x = isoutlier(X,P.outlier.method,1,'ThresholdFactor',P.outlier.parameter);
        TF_y = isoutlier(Y,P.outlier.method,1,'ThresholdFactor',P.outlier.parameter);
    end
    x = X; y = Y; y(TF_y == 1) = nan;
elseif P.outlier.tool == 0
    x = X; y = Y;
    TF_x = zeros(size(X,1),size(X,2)); TF_y = TF_x;
end

k = sum(y,2); f = find(isnan(y)); x(f,:) = []; y(f,:) = []; 
c = C; 
if ~isempty(c)
    c(f,:) = [];
end
R.outlier.X = TF_x; R.outlier.Y = TF_y;

%% Regressing Out Covariates
if P.regress == 1
  [x,y] = residual_xy(x,y,c);
end

%% Data Normalization / Scaling
if strcmp(P.normalize.method,'rescale')  %����rescale����������ķ�Χ������rescale(A),���ŵ�[0 1]����
    for i = 1:size(x,2)
        x(:,i) = rescale(x(:,i),P.normalize.parameter(1),P.normalize.parameter(2));
    end
    for i = 1:size(y,2)
        y(:,i) = rescale(y(:,i),P.normalize.parameter(1),P.normalize.parameter(2));
    end
elseif strcmp(P.normalize.method,'standard') | strcmp(P.normalize.method,'scaling')   
    x = StatisticalNormaliz(x,P.normalize.method);
    y = StatisticalNormaliz(y,P.normalize.method);
end

R.X = x; R.Y = y;

%% Dividing into High And Low Groups Based on Y
if size(y,2) == 1
    [a,b] = sort(R.Y);   %sort��Ԫ�ؽ�������
    k = round(P.group*length(y));   %round��Ԫ�ؽ�����������Ϊ���������ȿ��Ե��ڡ�
    low = [1:k]; high = [length(y)-k+1:length(y)];
    R.order = zeros(length(y),1);
    R.order(b(low)) = -1;
    R.order(b(high)) = 1;
end
