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

function [pos, vec, force, fnorm, energie, f] = reg_fourier_TFM(grid_mat, u, E, s, pix_durch_my, zdepth, cluster_size, i_max, j_max, L)

    V = 2*(1+s)/E;
    z = zdepth/pix_durch_my; 
    
    X = i_max*cluster_size/2;
    Y = j_max*cluster_size/2; 
    if z == 0
        g0x = pi.^(-1).*V.*((-1).*Y.*log((-1).*X+sqrt(X.^2+Y.^2))+Y.*log( ...
        X+sqrt(X.^2+Y.^2))+((-1)+s).*X.*(log((-1).*Y+sqrt(X.^2+Y.^2) ...
        )+(-1).*log(Y+sqrt(X.^2+Y.^2))));
    
        g0y = pi.^(-1).*V.*(((-1)+s).*Y.*(log((-1).*X+sqrt(X.^2+Y.^2))+( ...
        -1).*log(X+sqrt(X.^2+Y.^2)))+X.*((-1).*log((-1).*Y+sqrt( ...
        X.^2+Y.^2))+log(Y+sqrt(X.^2+Y.^2))));
    else
        g0x = pi.^(-1).*V.*(((-1)+2.*s).*z.*atan(X.^(-1).*Y)+(-2).*z.* ...
        atan(X.*Y.*z.^(-1).*(X.^2+Y.^2+z.^2).^(-1/2))+z.*atan(X.^( ...
        -1).*Y.*z.*(X.^2+Y.^2+z.^2).^(-1/2))+(-2).*s.*z.*atan(X.^( ...
        -1).*Y.*z.*(X.^2+Y.^2+z.^2).^(-1/2))+(-1).*Y.*log((-1).*X+ ...
        sqrt(X.^2+Y.^2+z.^2))+Y.*log(X+sqrt(X.^2+Y.^2+z.^2))+(-1).* ...
        X.*log((-1).*Y+sqrt(X.^2+Y.^2+z.^2))+s.*X.*log((-1).*Y+sqrt( ...
        X.^2+Y.^2+z.^2))+(-1).*((-1)+s).*X.*log(Y+sqrt(X.^2+Y.^2+ ...
        z.^2)));
    
        g0y = (-1).*pi.^(-1).*V.*(((-1)+2.*s).*z.*atan(X.^(-1).*Y)+(3+(-2) ...
        .*s).*z.*atan(X.*Y.*z.^(-1).*(X.^2+Y.^2+z.^2).^(-1/2))+z.* ...
        atan(X.^(-1).*Y.*z.*(X.^2+Y.^2+z.^2).^(-1/2))+(-2).*s.*z.* ...
        atan(X.^(-1).*Y.*z.*(X.^2+Y.^2+z.^2).^(-1/2))+Y.*log((-1).* ...
        X+sqrt(X.^2+Y.^2+z.^2))+(-1).*s.*Y.*log((-1).*X+sqrt(X.^2+ ...
        Y.^2+z.^2))+((-1)+s).*Y.*log(X+sqrt(X.^2+Y.^2+z.^2))+X.*log( ...
        (-1).*Y+sqrt(X.^2+Y.^2+z.^2))+(-1).*X.*log(Y+sqrt(X.^2+Y.^2+ ...
        z.^2)));
    end

    kx_vec = 2*pi/i_max/cluster_size.*[0:(i_max/2) (-(i_max/2-1):-1)];
    ky_vec = 2*pi/j_max/cluster_size.*[0:(j_max/2) (-(j_max/2-1):-1)];
    
    kx = repmat(kx_vec',1,j_max);
    ky = repmat(ky_vec,i_max,1);
    
    kx(1,1) = 1;
    ky(1,1) = 1;
    
   Ginv_xx =exp(sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).^(-1/2).*V.*(exp( ...
      2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).*L+V.^2).^(-1).*(4.* ...
      ((-1)+s).*V.^2.*((-1)+s+sqrt(kx.^2+ky.^2).*z)+(kx.^2+ky.^2) ...
      .*(4.*exp(2.*sqrt(kx.^2+ky.^2).*z).*L+V.^2.*z.^2)).^(-1).*(( ...
      -2).*exp(2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).*L.*((-2).* ...
      ky.^2+kx.^2.*((-2)+2.*s+sqrt(kx.^2+ky.^2).*z))+V.^2.*( ...
      kx.^2.*(4+(-4).*s+(-2).*sqrt(kx.^2+ky.^2).*z+ky.^2.*z.^2)+ ...
      ky.^2.*(4+4.*((-2)+s).*s+(-4).*sqrt(kx.^2+ky.^2).*z+4.*sqrt( ...
      kx.^2+ky.^2).*s.*z+ky.^2.*z.^2)));
    Ginv_yy = exp(sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).^(-1/2).*V.*(exp( ...
      2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).*L+V.^2).^(-1).*(4.* ...
      ((-1)+s).*V.^2.*((-1)+s+sqrt(kx.^2+ky.^2).*z)+(kx.^2+ky.^2) ...
      .*(4.*exp(2.*sqrt(kx.^2+ky.^2).*z).*L+V.^2.*z.^2)).^(-1).*( ...
      2.*exp(2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).*L.*(2.* ...
      kx.^2+(-1).*ky.^2.*((-2)+2.*s+sqrt(kx.^2+ky.^2).*z))+V.^2.*( ...
      kx.^4.*z.^2+(-2).*ky.^2.*((-2)+2.*s+sqrt(kx.^2+ky.^2).*z)+ ...
      kx.^2.*(4+4.*((-2)+s).*s+(-4).*sqrt(kx.^2+ky.^2).*z+4.*sqrt( ...
      kx.^2+ky.^2).*s.*z+ky.^2.*z.^2)));
    Ginv_xy = (-1).*exp(sqrt(kx.^2+ky.^2).*z).*kx.*ky.*(kx.^2+ky.^2).^( ...
      -1/2).*V.*(exp(2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2).*L+ ...
      V.^2).^(-1).*(2.*exp(2.*sqrt(kx.^2+ky.^2).*z).*(kx.^2+ky.^2) ...
      .*L.*(2.*s+sqrt(kx.^2+ky.^2).*z)+V.^2.*(4.*((-1)+s).*s+(-2) ...
      .*sqrt(kx.^2+ky.^2).*z+4.*sqrt(kx.^2+ky.^2).*s.*z+(kx.^2+ ...
      ky.^2).*z.^2)).*(4.*((-1)+s).*V.^2.*((-1)+s+sqrt(kx.^2+ ...
      ky.^2).*z)+(kx.^2+ky.^2).*(4.*exp(2.*sqrt(kx.^2+ky.^2).*z).* ...
      L+V.^2.*z.^2)).^(-1);

    Ginv_xx(1,1) = 1/g0x;
    Ginv_yy(1,1) = 1/g0y;
    Ginv_xy(1,1) = 0;

    Ginv_xy(i_max/2+1,:) = 0;
    Ginv_xy(:,j_max/2+1) = 0;

    Ftu(:,:,1) = fft2(u(:,:,1));
    Ftu(:,:,2) = fft2(u(:,:,2));

    Ftf(:,:,1) = Ginv_xx.*Ftu(:,:,1) + Ginv_xy.*Ftu(:,:,2);
    Ftf(:,:,2) = Ginv_xy.*Ftu(:,:,1) + Ginv_yy.*Ftu(:,:,2);

    f(:,:,1) = ifft2(Ftf(:,:,1),'symmetric');
    f(:,:,2) = ifft2(Ftf(:,:,2),'symmetric');
    
    if ~isempty(grid_mat)
        try
            pos(:,1) = reshape(grid_mat(:,:,1),i_max*j_max,1);
            pos(:,2) = reshape(grid_mat(:,:,2),i_max*j_max,1);
        catch
            pos(:,1) = reshape(grid_mat(:,:,1),size(grid_mat(:,:,1),1)*size(grid_mat(:,:,1),2),1);
            pos(:,2) = reshape(grid_mat(:,:,2),size(grid_mat(:,:,2),1)*size(grid_mat(:,:,2),2),1);
        end
    else
       pos = [];
    end
        
    try
        vec(:,1) = reshape(u(:,:,1),i_max*j_max,1);
        vec(:,2) = reshape(u(:,:,2),i_max*j_max,1);
    catch
        vec(:,1) = reshape(u(:,:,1),size(u(:,:,1),1) * size(u(:,:,1),2),1);
        vec(:,2) = reshape(u(:,:,2),size(u(:,:,2),1) * size(u(:,:,2),2),1);
    end

    try
        force(:,1) = reshape(f(:,:,1),i_max*j_max,1);
        force(:,2) = reshape(f(:,:,2),i_max*j_max,1);     
    catch
        force(:,1) = reshape(f(:,:,1),size(f(:,:,1), 1) * size(f(:,:,1), 2),1);
        force(:,2) = reshape(f(:,:,2),size(f(:,:,2), 1) * size(f(:,:,2), 2),1);     
    end
    
    fnorm = (force(:,1).^2 + force(:,2).^2).^0.5;
    
end