classdef mfsbasis < handle & basis
% MFSBASIS - create a fundamental solutions (MFS) basis set
%
%  b = MFSBASIS(Z, tau, N, k, opts) creates an MFS basis using charge points
%   at Z(t + i.tau) where t are equally distributed in [0,2pi], Z is a given
%   2pi-periodic analytic function, and tau is the distance off the curve.
%   N is the number of charge points, and k is wavenumber. opts may contain:
%   opts.real: if true use Y_0, otherwise use H_0, as fundamental solution.
%
%  b = MFSBASIS(y, [], [], k, opts) where y is a row vector of charge points
%   allows the user to choose the charge points, from which N is determined.
%
%  b = MFSBASIS() creates MFS basis without any charge pts.
%
%  There should be other input formats for MFSBASIS!
%
% To do: other location methods, inferface to mfsloc.m code from analytic_mfs
  properties
    Z                     % function handle for charge curve
    tau                   % imaginary distance
    t                     % row vec of parameter values in [0,2pi]
    y                     % row vec of charge points (C-#s)
    realflag              % if true, use real part only, ie Y_0
    %locmeth              % charge point location method
  end
  
  methods
    function b = mfsbasis(Z, tau, N, k, opts) % ............... constructor
      if nargin<5, opts = []; end
      if ~isfield(opts, 'real'), opts.real = 0; end
      b.realflag = opts.real;
      if ~isempty(k), b.k = k; end
      if isnumeric(Z)                         % Z contains y list of MFS pts
        b.y = reshape(Z, [1 N]);
        b.N = numel(b.y); b.Nf = b.N;
      elseif ~isempty(Z)                      % Z is a function handle
        b.N = N; b.Nf = N;
        b.Z = Z; b.tau = tau;
        b.t = 2*pi*(1:N)/N;                   % create row vec
        b.y = Z(b.t + 1i*tau);
      end
    end
    
    function [A B C] = eval(b, p)
    % EVAL - evaluate MFS basis values, and maybe derivatives, at set of points
    %
    % Code adapted from /home/alex/bdry/inclus/evalbasis.m
      derivs = nargout-1;              % derivs = 1 direc, derivs = 2 both x & y
      N = b.N; M = numel(p.x); k = b.k;
      d = repmat(p.x, [1 N]) - repmat(b.y, [M 1]); % displacement matrix, C#s
      r = abs(d);
      if derivs==1                     % want directional deriv
        ny = repmat(p.nx, [1 N]);      % identical cols given by bdry normals
        cosphi = real(conj(ny).*d) ./ r;      % dot prod <normal, displacement>
        clear d ny
        B = utils.fundsol_deriv(r, -cosphi, k); % (target)-normal deriv, NB sign
        clear cosphi
        if b.realflag, B = real(B); end         % keeps only the Y-0 part
      elseif derivs==2                          % want x,y-derivs
        dor = d./r;                             % contains x as re, y as im
        clear d
        [B radderivs] = utils.fundsol_deriv(r, -real(dor), k); % x deriv 
        C = utils.fundsol_deriv(r, -imag(dor), k, radderivs); % y reuse rad part
        clear radderivs dor
        if b.realflag, B = real(B); C = real(C); end % keeps only the Y-0 part
      end
      A = utils.fundsol(r, k);
      if b.realflag, A = real(A); end           % keeps only the Y-0 part    
    end
    
    function showgeom(bas) % ....................... crude show MFS pts, etc
      plot(real(bas.y), imag(bas.y), 'r+');
    end % func
        
  end % methods
end
