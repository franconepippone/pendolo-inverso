function ...
    showMatrix(A,varargin)
% The function shows the matrix in the command window in orderly fashion
% 
% Inputs:
%   A: a matrix
%   numPrecision: floating-point precision to print (optional, default: 3)

%% 
% Any number has the first integer digit and the decimal digits. 
% The negative sign occupies an additional digit. 
% The integer digits after the first also require additional space. 

%%
% Thus, each element requires the following additional space:
AS = double(floor(A) < 0) + floor(log10(abs(double(fix(A)))+1));

%%
% We add the following number of blank spaces to allign the elemnts:
MC = max(AS,[],1).*ones(size(A)) - AS;

if nargin == 1
    numPrecision = 3;
elseif nargin == 2
    numPrecision = round(varargin{1});
end

%% Show the matrix on screen
for i = 1 : size(A,1)
    s = blanks(MC(i,1));
    if size(A,2) > 1
        fprintf(['    [' s '%.*f '],numPrecision,A(i,1))
        for j = 2 : size(A,2)-1
            s = blanks(MC(i,j));
            fprintf([s '%.*f '],numPrecision,A(i,j))
        end
        s = blanks(MC(i,end));
        fprintf([s '%.*f]\n'],numPrecision,A(i,end))
    else
        fprintf(['    [' s '%.*f]\n'],numPrecision,A(i,1))
    end
end
