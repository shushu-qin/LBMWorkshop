clear all
clc
tic
% Developing Poiseuille flow 

% Lattice parameters
weights=[4/9 1/9 1/9 1/9 1/9 1/36 1/36 1/36 1/36];
cx=[0 1 0 -1 0 1 -1 -1 1];
cy=[0 0 1 0 -1 1 1 -1 -1];

% Numerical parameters
NX=22;  % Number of grids points along x
NY=22;  % Number of grid points along y
NPOP=9; % Number of populations used in velocity space discretization
NSTEPS=2000;    % Number of time steps/iterations


% Simulation parameters
y_bottom=1;  % location of bottom wall
y_top=NY;  % location of top wall
Re=10;  % Reynolds number
omega=0.9;   % Relaxation frequency
kvisc=1/3*(1/omega-0.5); % Kinematic viscosity
umax=Re*kvisc/((y_top-y_bottom)) ;% umax=0.001; % Mach number (can be understood as a CFL number)


% Macroscopic parameters
rho=ones(NX,NY);
ux=zeros(NX,NY);
uy=zeros(NX,NY);

forcex=8.*umax*kvisc./((y_top-y_bottom).^2);
forcey=0;

% Analytical solution
y_plot=y_bottom:y_top;
ux_analy=-1/(2*kvisc).*forcex.*(y_plot-y_bottom).*(y_plot-y_top);
ux_in=1/12*(y_bottom^2-2*y_bottom*y_top+y_top^2)*forcex/kvisc;



% Initialize populations with rho=1 and (ux,uy)=(0,0)
feq=zeros(NPOP);
f1=zeros(NPOP,NX,NY);
f2=zeros(NPOP,NX,NY);
forcepop=zeros(NPOP);
for y=1:NY
    for x=1:NX
        dense=rho(x,y);
        vx=ux(x,y);
        vy=uy(x,y);
        for k=1:NPOP
            feq(k)=weights(k)*(dense+(3*(vx*cx(k)+vy*cy(k)) ...
                +9/2*(cx(k)*vx+cy(k)*vy)^2-3/2*(vx^2+vy^2)));
            f1(k,x,y)=feq(k);
            f2(k,x,y)=feq(k);
        end
    end
end

% Main algorithm
for counter=1:NSTEPS

    % Macroscopic parameters computed through velocity moments of
    % populations f1
    for y=1:NY
        for x=1:NX

            dense=0;
            vx=0;
            vy=0;
            for k=1:NPOP
                dense=dense+f1(k,x,y);
                vx=vx+cx(k)*f1(k,x,y);
                vy=vy+cy(k)*f1(k,x,y);
            end

            rho(x,y)=dense;
            ux(x,y)=vx;
            uy(x,y)=vy;


            for k=1:NPOP

                % Compute the populations equilibrium value
                feq(k)=weights(k).*(dense+3*(vx*cx(k)+vy*cy(k)) ...
                    +9/2*((cx(k)*cx(k)-1/3)*vx*vx+2*cx(k)*cy(k)*vx*vy+(cy(k)*cy(k)-1/3)*vy*vy));


                % Collision step
                f1(k,x,y)=f1(k,x,y)*(1-omega)+feq(k)*omega;

                % Streaming step
                newx=1+mod(x-1+cx(k)+NX,NX);
                newy=1+mod(y-1+cy(k)+NY,NY);
                f2(k,newx,newy)=f1(k,x,y);
            end
        end
    end


    % Zou He Boundary Conditions

    x=1; % inlet
    for y=2:NY-1

        ux(x,y)=ux_in;
        uy(x,y)=0;
        rho(x,y)=ux(x,y)+(f2(1,x,y)+f2(3,x,y)+f2(5,x,y)+2*(f2(4,x,y)+f2(7,x,y)+f2(8,x,y)));

        f2(2,x,y)=f2(4,x,y)+2/3*ux(x,y);
        f2(6,x,y)=f2(8,x,y)+1/6*ux(x,y)+0.5*(f2(5,x,y)-f2(3,x,y))+1/2*uy(x,y);
        f2(9,x,y)=f2(7,x,y)+1/6*ux(x,y)-0.5*(f2(5,x,y)-f2(3,x,y))-1/2*uy(x,y);
    end

    x=NX; % outlet
    for y=2:NY-1

        ux(x,y)=ux(x-1,y);  %Extrapolation (1st order)
        uy(x,y)=0;
        rho(x,y)=-ux(x,y)+(f2(1,x,y)+f2(3,x,y)+f2(5,x,y)+2*(f2(2,x,y)+f2(6,x,y)+f2(9,x,y)));

        f2(4,x,y)=f2(2,x,y)-2/3*ux(x,y);
        f2(8,x,y)=f2(6,x,y)-1/6*ux(x,y)-0.5*(f2(5,x,y)-f2(3,x,y))-1/2*uy(x,y);
        f2(7,x,y)=f2(9,x,y)-1/6*ux(x,y)+0.5*(f2(5,x,y)-f2(3,x,y))+1/2*uy(x,y);

    end

    y=1; %bottom wall
    for x=2:NX-1
        ux(x,y)=0;
        uy(x,y)=0;
        rho(x,y)=uy(x,y)+(f2(1,x,y)+f2(2,x,y)+f2(4,x,y)+2*(f2(5,x,y)+...
            f2(8,x,y)+f2(9,x,y)));


        f2(3,x,y)=f2(5,x,y)+2/3*uy(x,y);
        f2(6,x,y)=f2(8,x,y)+1/6*uy(x,y)+0.5*(f2(4,x,y)-f2(2,x,y))+1/2.*ux(x,y);
        f2(7,x,y)=f2(9,x,y)+1/6*uy(x,y)-0.5*(f2(4,x,y)-f2(2,x,y))-1/2.*ux(x,y);

    end

    y=NY; % Top wall
    for x=2:NX-1

        ux(x,y)=0;
        uy(x,y)=0;
        rho(x,y)=-uy(x,y)+(f2(1,x,y)+f2(2,x,y)+f2(4,x,y)+2*(f2(3,x,y)+...
            f2(6,x,y)+f2(7,x,y)));


        f2(5,x,y)=f2(3,x,y)-2/3*uy(x,y);
        f2(8,x,y)=f2(6,x,y)-1/6*uy(x,y)+0.5*(f2(2,x,y,1)-f2(4,x,y))-1/2*ux(x,y);
        f2(9,x,y)=f2(7,x,y)-1/6*uy(x,y)-0.5*(f2(2,x,y)-f2(4,x,y))+1/2*ux(x,y);


    end

    % Corners
    %==================================================================
    %Bottom left corner
    x=1; y=1;
    rho(x,y)=rho(x,y+1);  %Extrapolation (1st order)
    ux(x,y)=0;
    uy(x,y)=0;
    f2(2,x,y)=f2(4,x,y)+2/3*ux(x,y);
    f2(3,x,y)=f2(5,x,y)+2/3*uy(x,y);
    f2(6,x,y)=f2(8,x,y)+1/6*(ux(x,y)+uy(x,y));
    f2(7,x,y)=1/12*(-ux(x,y)+uy(x,y));
    f2(9,x,y)=1/12*(ux(x,y)-uy(x,y));
    f2(1,x,y)=0;
    f2(1,x,y)=rho(x,y)-sum(f2(:,x,y));

    %Top left corner
    x=1; y=NY;
    rho(x,y)=rho(x,y-1);  %Extrapolation (1st order)
    ux(x,y)=0;
    uy(x,y)=0;
    f2(2,x,y)=f2(4,x,y)+2/3*ux(x,y);
    f2(5,x,y)=f2(3,x,y)-2/3*uy(x,y);
    f2(9,x,y)=f2(7,x,y)+1/6*(ux(x,y)-uy(x,y));
    f2(6,x,y)=1/12*(ux(x,y)+uy(x,y));
    f2(8,x,y)=-1/12*(ux(x,y)+uy(x,y));
    f2(1,x,y)=0;
    f2(1,x,y)=rho(x,y)-sum(f2(:,x,y));

    %Bottom right corner
    x=NX; y=1;
    rho(x,y)=rho(x,y+1);  %Extrapolation (1st order)
    ux(x,y)=0;
    uy(x,y)=0;
    f2(4,x,y)=f2(2,x,y)-2/3*ux(x,y);
    f2(3,x,y)=f2(5,x,y)+2/3*uy(x,y);
    f2(7,x,y)=f2(9,x,y)+1/6*(-ux(x,y)+uy(x,y));
    f2(6,x,y)=1/12*(ux(x,y)+uy(x,y));
    f2(8,x,y)=-1/12*(ux(x,y)+uy(x,y));
    f2(1,x,y)=0;
    f2(1,x,y)=rho(x,y)-sum(f2(:,x,y));

    %Top right corner
    x=NX; y=NY;
    rho(x,y)=rho(x,y-1);  %Extrapolation (1st order)
    ux(x,y)=0;
    uy(x,y)=0;
    f2(4,x,y)=f2(2,x,y)-2/3*ux(x,y);
    f2(5,x,y)=f2(3,x,y)-2/3*uy(x,y);
    f2(8,x,y)=f2(6,x,y)-1/6*(ux(x,y)+uy(x,y));
    f2(7,x,y)=1/12*(-ux(x,y)+uy(x,y));
    f2(9,x,y)=1/12*(ux(x,y)-uy(x,y));
    f2(1,x,y)=0;
    f2(1,x,y)=rho(x,y)-sum(f2(:,x,y));

    % Assign new state f1, i.e. f(t+1) to previous state f2, i.e. f(t)
    f1=f2;
end

ux_plot=ux;



% % Compare LBM and Analytical solution velocity profiles
% figure('color',[1 1 1])
% hold on
% plot(y_plot./(y_top),ux_analy./umax,'ko--');
% xlabel('y/y_{top}');
% ylabel('u/umax');
% plot(y_plot./(y_top),ux_plot(round(NX),:)./umax,'rs-.');
% legend('ux analy','ux LBM');
% axis  tight
% box on


% Calculation of L2 error
sum_num=0;
sum_denom=0;
x=NX;
for y=1:NY

    sum_num=sum_num+(ux_plot(x,y)-ux_analy(y)).^2;
    sum_denom=sum_denom+ux_analy(y).^2;
end

error=sqrt((sum_num)/(sum_denom));

disp(['L2 relative error = ',num2str(error)]);

toc % Stop time counter

