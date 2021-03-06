% Copyright (C) 2010 - 2019, Sabass Lab
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your option) 
% any later version. This program is distributed in the hope that it will be 
% useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details. You should have received a copy of the 
% GNU General Public License along with this program.
% If not, see <http://www.gnu.org/licenses/>.
% Modified by Waddah Moghram on 2020-05-08..10 to overcome very huge matrix sizes by using "sparse()" function

function [lambda_2, evidencep, evidence_one, FigHandleRegParam]  = optimal_lambda(beta1,fuu1,Fux1,Fuy1,E1,s1,cluster_size1,i_max1, j_max1,X1, ShowOutput)
    start = tic;
    if nargin < 10
        ShowOutput = false;
%         figHandleRegParam = [];
    end
    
    global beta fuu Fux Fuy E s cluster_size i_max j_max C_a X aa BX_a constant
    beta = beta1;
    fuu = fuu1;
    Fux = Fux1;
    Fuy = Fuy1;
    E =E1;
    s = s1;
    cluster_size =cluster_size1;
    i_max = i_max1;
    j_max = j_max1;
    X=X1;

    aa = size(X1); 
    c = ones(aa(2),1);
    C = diag(sparse(c));
    XX = sparse(X)*sparse(X);
    BX_a = beta*sparse(XX)/aa(1)*2;
    C_a = C/aa(2)*2;
    constant = aa(1)*log(beta)-aa(1)*log(2*pi);

    %%% Golden section search method. Reg Param Search limits (alpha1 and alpha2)
    alpha1 =1e-8; 
    alpha2 =1e8; 

    alpha_opt = fminbnd(@logevidence,alpha1,alpha2);

    plot_alpha = [alpha_opt*0.2:alpha_opt*0.12:alpha_opt*2];                        % plot alpha range can be changed 
    a = size(plot_alpha);
    lambda_p = plot_alpha./beta;
    for i = 1:a(2)
        evidence(i) = -logevidence(plot_alpha(i));
    end

    evidencep = [lambda_p;evidence];
    evidence_one = -logevidence(alpha_opt);
    lambda_2 = alpha_opt/beta;
    

    if ShowOutput
        disp(['(optimal_lambda.m): Optimized Bayesian regularization parameter value: ' num2str(lambda_2)])
        FigHandleRegParam = figure('color', 'w');
        hold on
        plot(evidencep(1,:), evidencep(2,:),'b-');
        xlabel('\lambda_2E^2');
        ylabel('Log(Evidence)');
        plot(lambda_2,evidence_one, 'ro','MarkerSize',10);
        ps_t=[lambda_2, evidence_one];
        strValues = num2str(ps_t(1),'%.5g');
        text(ps_t(1), 1*ps_t(2),['\lambda_2E^2=', strValues],'FontSize',10,'VerticalAlignment','bottom');
        hold off;
        fprintf('\tReg_corner Bayesian L2 (BL2)   = %10.8g. ', lambda_2);         
        fprintf('\t\tDowntime = %g seconds. \n', toc(start));
    else
        FigHandleRegParam = [];
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% calculating log evidence function 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function evidence_value= logevidence(alpha)
        
global beta fuu Fux Fuy E s cluster_size i_max j_max C_a  X aa BX_a constant

    LL = alpha/beta;
    [Ftfx, Ftfy] = BL2_force_updated(Fux,Fuy,LL,E,s,cluster_size,i_max, j_max);
    fxx = reshape(Ftfx,i_max*j_max,1);    
    fyy = reshape(Ftfy,i_max*j_max,1);
    f(1:2:size(fxx)*2,1) = fxx;
    f(2:2:size(fyy)*2,1) = fyy;
   
    A = alpha * sparse(C_a) + BX_a;
    L = chol(sparse(A));
    logdetA = 2*sum(log(diag(L)));
  
    Xf_u = X*f-fuu;
    
    Ftux= Xf_u(1:2:end);
    Ftuy= Xf_u(2:2:end);
    ff = sum(sum(Ftfx.*conj(Ftfx) + Ftfy.*conj(Ftfy)))/(0.5*aa(2));
    uu = sum(sum(Ftux.*conj(Ftux) + Ftuy.*conj(Ftuy)))/(0.5*aa(1));
    
    evidence_value = -0.5*(-alpha*ff-beta*uu ...
                     -logdetA +aa(2)*log(alpha)+constant);
end