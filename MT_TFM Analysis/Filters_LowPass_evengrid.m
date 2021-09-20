%{
    emailed by Dr. Selby on 2019-11-21. 
%}
%% Calculate Butterworth filter for the displacement data (in Fourier space).
% Here, U(i) represents the displacement data matrix that contains both an
% extended randomized boundary and zero padding
% i=1 for x displacements, i=2 for y displacements,size [nr, nr] 
% This is effectively a low-pass filter.

nr=200; %nr=max(size(U(1)));
qmax=70;
bw=3;

% Get distance from of a grid point from the centre of the array
y = repmat((1:nr)'-nr/2-0.5,1,nr);
x=y';
q=sqrt(x.^2+y.^2);

% Make the filter
qmskbw=1./(1.+(q./qmax).^(bw));
%Shifts 4 quadrants
qmskbw=ifftshift(qmskbw);

%% Calculate Exponential filter for the displacement data (in Fourier space).
% Here, U(i) represents the displacement data matrix that contains both an
% extended randomized boundary and zero padding
% i=1 for x displacements, i=2 for y displacements,size [nr, nr] 
% This is effectively a low-pass filter.

nr=200; %nr=max(size(U(1)));
qmax=70;
elp=2;

% Get distance from of an image point from the center of the array
y=repmat((1:nr)'-nr/2-0.5,1,nr);
x=y';
q=sqrt(x.^2+y.^2);

% Make the filter
qmskelp=exp(-(q./qmax).^elp);
%Shifts 4 quadrants
qmskelp=ifftshift(qmskelp);

%% Calculate Hann window

% Make 1d Hann windows
w_c=0.5*(1-cos(2*pi*(0:nr-1)/(nr-1)));
w_r=0.5*(1-cos(2*pi*(0:nr-1)/(nr-1)));

% Mesh Hann windows together to form 2D Hann window
[wnx,wny]=meshgrid(w_c,w_r);
wn=wnx.*wny;

%% Filter displacements in Fourier space, transform back to spatial domain, apply Hann window
% After completing this process, the displacement field is ready to be
% passed to the FTTC solution routine

utmp(1).u=real(ifft2(qmsk.*fft2(U(1))));  
utmp(1).u=utmp(1).u.*wn; 

utmp(2).u=real(ifft2(qmsk.*fft2(U(2))));  
utmp(3).u=utmp(2).u.*wn; 
   