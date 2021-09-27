%{
    This program (regularized fourier transform traction force
    reconstruction) was produced at the University of Heidelberg, BIOMS
    group of Ulrich Schwarz. It calculates traction from a gel displacement
    field.

    Benedikt Sabass 13-10-2008

    Copyright (C) 2019, Danuser Lab - UTSouthwestern 

    This file is part of TFM_Package.

    TFM_Package is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TFM_Package is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with TFM_Package.  If not, see <http://www.gnu.org/licenses/>.

%% Updated by Waddah Moghram on 2019-11-17:
    1. to allow for odd-numbered grid.
    NOTE: the scaling is not used unless it is 3D TFM (not in this version)
    , or for the calculations of strain energy.

%}

%-----------------------------------------------------------------------------------------------        
function  [pos, vec, force, fnorm, energie, f] = reg_fourier_TFM_odd(grid_mat, u, E, s, pix_durch_my, cluster_size, i_max, j_max, L, Rx, Ry)
%{
     added by Achim:
    Input : grid_mat, u, cluster_size have to be in the same units, namely
            pixels. If they are given in different units e.g. meters, then a
            different scaling factor for the elastic energy has to be
            applied! The force value remains, however, unaffected, see below.

    Output: The output force is actually a surface stress with the same units
            as the input E! In particular, the unit of the output force is
            independent of the units of the input grid_mat,u and cluster_size
            The reason for this is essentially that the elastic stress is
            only dependent on the non-dimensional strain which is given by
            spatial derivatives of the displacements, that is du/dx. If u and
            dx (essentially cluster_size) are in the same units, then the
            resulting force has the same dimension as the input E.

    updated by Sangyoon Han for usage for L1 regularization

    Updated by Waddah Moghram on 2019-11-20. No need for this function anymore. 
        The updated version of reg_fourier_TFM.m can deal with both odd- and even-numbered grid lengths
%}

%% ---------------- Modified by Waddah Moghram on 2019-06-17 to pad arrays with 0's
% Modified by Waddah Moghram to allow the use of odd-numbers array
%     u(1,:,:) = 0;
%     u(end,:,:) = 0; 
%     u(:,1) = 0;
%     u(:,end) = 0;
%% ------------------------------------------------------


%    nN_pro_pix_fakt = 1/(10^3 * pix_durch_my^2);
%    nN_pro_my_fakt = 1/(10^3);
    
    V = 2*(1+s)/E;
    
    if mod(i_max, 2) 
        kx_vec = [-floor(i_max/2):floor(i_max/2)];
    else
        kx_vec = 2*pi/i_max/cluster_size.*[0:(i_max/2-1) (-i_max/2:-1)]; 
    end
    if mod(i_max, 2) 
        ky_vec = [-floor(j_max/2):floor(j_max/2)];
    else
        ky_vec = 2*pi/j_max/cluster_size.*[0:(j_max/2-1) (-j_max/2:-1)];
    end
    kx = repmat(kx_vec',1,j_max);
    ky = repmat(ky_vec,i_max,1);
    
    if nargin<10
        Rx = ones(size(kx));
        Ry = ones(size(ky));
    end

    kx(1,1) = 1;
    ky(1,1) = 1;
    
    X = i_max*cluster_size/2;
    Y = j_max*cluster_size/2; 
   
    g0x = pi.^(-1).*V.*((-1).*Y.*log((-1).*X+sqrt(X.^2+Y.^2))+Y.*log( ...
      X+sqrt(X.^2+Y.^2))+((-1)+s).*X.*(log((-1).*Y+sqrt(X.^2+Y.^2) ...
      )+(-1).*log(Y+sqrt(X.^2+Y.^2))));
    g0y = pi.^(-1).*V.*(((-1)+s).*Y.*(log((-1).*X+sqrt(X.^2+Y.^2))+( ...
      -1).*log(X+sqrt(X.^2+Y.^2)))+X.*((-1).*log((-1).*Y+sqrt( ...
      X.^2+Y.^2))+log(Y+sqrt(X.^2+Y.^2))));
    
    Ginv_xx =(kx.^2+ky.^2).^(-1/2).*V.*(kx.^2.*L.*Rx+ky.^2.*L.*Ry+V.^2).^(-1).*(kx.^2.* ...
              L.*Rx+ky.^2.*L.*Ry+((-1)+s).^2.*V.^2).^(-1).*(kx.^4.*(L.*Rx+(-1).*L.*s.*Rx)+ ...
              kx.^2.*((-1).*ky.^2.*L.*Ry.*((-2)+s)+(-1).*((-1)+s).*V.^2)+ky.^2.*( ...
              ky.^2.*L.*Ry+((-1)+s).^2.*V.^2));
    Ginv_yy = (kx.^2+ky.^2).^(-1/2).*V.*(kx.^2.*L+ky.^2.*L.*Ry+V.^2).^(-1).*(kx.^2.* ...
              L.*Rx+ky.^2.*L.*Ry+((-1)+s).^2.*V.^2).^(-1).*(kx.^4.*L+(-1).*ky.^2.*((-1)+ ...
              s).*(ky.^2.*L.*Rx+V.^2)+kx.^2.*((-1).*ky.^2.*L.*Ry.*((-2)+s)+((-1)+s).^2.* ...
              V.^2));
    Ginv_xy = (-1).*kx.*ky.*(kx.^2+ky.^2).^(-1/2).*s.*V.*(kx.^2.*L.*Rx+ky.^2.*L.*Ry+ ...
              V.^2).^(-1).*(kx.^2.*L.*Rx+ky.^2.*L.*Ry+((-1)+s).*V.^2).*(kx.^2.*L.*Rx+ky.^2.* ...
              L.*Ry+((-1)+s).^2.*V.^2).^(-1);

    Ginv_xx(1,1) = 1/g0x;
    Ginv_yy(1,1) = 1/g0y;
    Ginv_xy(1,1) = 0;

    if mod(i_max, 2)
        Ginv_xy(floor(i_max/2+1),:) = 0;
    else
        Ginv_xy(i_max/2+1,:) = 0;
    end
    if mod(j_max,2)
        Ginv_xy(:,floor(j_max/2+1)) = 0;    
    else
        Ginv_xy(:,j_max/2+1) = 0;
    end
    Ftu(:,:,1) = fft2(u(:,:,1));
    Ftu(:,:,2) = fft2(u(:,:,2));

    Ftf(:,:,1) = Ginv_xx.*Ftu(:,:,1) + Ginv_xy.*Ftu(:,:,2);
    Ftf(:,:,2) = Ginv_xy.*Ftu(:,:,1) + Ginv_yy.*Ftu(:,:,2);

    f(:,:,1) = ifft2(Ftf(:,:,1), 'symmetric');
    f(:,:,2) = ifft2(Ftf(:,:,2), 'symmetric');
    
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
    energie = 1/2*sum(sum(u(2:end-1,2:end-1,1).*f(2:end-1,2:end-1,1) + u(2:end-1,2:end-1,2).*f(2:end-1,2:end-1,2)))*(cluster_size)^2*pix_durch_my^3/10^6; 
end