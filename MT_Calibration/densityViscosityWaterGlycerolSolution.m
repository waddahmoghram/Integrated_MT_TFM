function [rho_s, mu_s] = densityViscosityWaterGlycerolSolution(w_g, T)
    %% Calculation of density of aqueous glycerol solutions.
    %{
    % rho_s = rho_GlySol(T,w_g)
    
    % rho_GlySol calculates the density of aqueous glycerol solutions based on
    measured data of [1] and [2]. As [1] only covers temperatures in the range
    15-30°C, the accuracy of <0.07% can only be proven for these temperatures.
    However, it is assumed that the calculation also gives a good approximation 
    of the densitiy for temperatures in the range 0-100°C.
    
        [1] L. Bosart and A. Snoddy, Industrial & Engineering Chemistry 20, 
            1377 (1928).
        [2] P. Linstrom and W. Mallard, NIST standard reference
            database (2005).
        [3] N.S. Cheng, Industrial & engineering chemistry research 47(9),
            3285–3288 (2008)
    
    % Input arguments
    
        w_g     weight fraction of glycerol in solution      
                [0.00-1.00]
        T       Temperature in  °C                           
                [0-100] (<0.07% accuracy for 15-30)
    
    % Output arguments
    
        rho_s  density of aqueous glycerol solution in kg/m^3
        mu_s   dynamic viscosity of aqueous glycerol solution in Ns/m^2
    
    % Other used variables
    
        a,b,c,A,alpha   coefficients for calculations
        rho_w           density of water in kg/m^3
        rho_g           density of glycerol in kg/m^3
        contraction     volume contraction of solution
        mu_w            dynamic viscosity of water in Ns/m^2
        mu_g            dynamic viscosity of glycerol in Ns/m^2
    
    Authors: Andreas Volk, Chris Westbrook 21. November 2017
    andreas.volk[at]unibw.de, c.d.westbrook[at]reading.ac.uk
    Modified by Waddah Moghram, PhD Student in Biomedical Engineering, on 1/24/2018
    %}
    
    %%  error checking
    if ~isnumeric(T) || max(T<0) || max(T>100)
        error('T must be in the range 0-100')
    end

    if ~isnumeric(w_g) || max(w_g<0) || max(w_g>1)
        error('w_g must be in the range 0-1')
    end

    %% contraction (distorted sine approximation fitted to data of [1])
    c = 1.78E-6*T.^2-1.82E-4*T+1.41E-2;
    contraction=1+(c.*sin((w_g).^1.31.*pi).^0.81);

    %% density of pure water (fitted to data of [2])
    rho_w = 1000 .* (1 - abs((T-3.98)./615) .^1.71); 

    %% density of pure glycerol (fitted to data of [1])
    rho_g = 1273 - T * 0.612; 

    %% density of specific w/w solution glycerol
    rho_s = contraction .* (rho_w+(rho_g-rho_w) ./(1 + rho_g./rho_w.*(1./w_g-1)));

    %% empirical formulas for dynamic viscosities of water and glycerol [3]
    mu_w = 0.001 *1.790 *exp((-1230-T)*T/(36100+360*T));  %Ns/m^2, [3] equation (21)
    mu_g = 0.001 *12100 *exp((-1233+T)*T/(9900+70*T));    %Ns/m^2, [3] equation (22)

    %% empirical formulas for dynamic viscosities of water-glycerol mixtures [3]
    a = 0.705-0.0017*T;                                 %[3] equation (12)
    b = (4.9+0.036*T)*a^2.5;                            %[3] equation (13)
    alpha = 1 -w_g +(a*b*w_g*(1-w_g))/(a*w_g+b*(1-w_g));  %[3] equation (11)
    A = log(mu_w/mu_g);                                 %Note this is NATURAL LOG (ln), not base 10.
    mu_s = mu_g * exp(A*alpha);                           %Ns/m^2, [3] equation (6)

    % Added by WIM
    fprintf('Density of glycerol is %8.5f kg/m^3, or %8.5f g/cm^3 \n', rho_s,rho_s/1000);
    fprintf('Viscosity of glycerol is %8.5f N.s/m^2 or Pa.s \n' , mu_s);
end