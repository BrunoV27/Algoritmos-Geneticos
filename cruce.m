function P1=cruce(P,mejores,Ntr,Npob,cant_ramales,N)
k=randperm(Ntr-cant_ramales-2,2)+ones(1,2);      %dos valores aleatorios entre 2 y 9, son los puntos medios entre cada gen del cromosoma, donde se van a hacer elos cortes
                                %corte es un valor cte para todas las descendencias
H=zeros(Npob/2,Ntr);            %matriz que contiene a las descendencias
P1=zeros(size(P));
reemplazables=zeros(1,Npob/2);  %cromosomas que seran reemplazados

u=0; %contador
for g=1:Npob            %Halla los reemplazables
    if ~any(mejores==g)
        u=u+1;
        reemplazables(u)=g;
    end
end
for i=1:2:length(mejores) %Reazlizacion del cruce en dos puntos
    for j=1:Ntr
        if j<=k(1)
            H(i,j)=P(mejores(i),j);     %primera parte del hijo 1
            H(i+1,j)=P(mejores(i+1),j); %primera parte del hijo 2
        elseif j>k(1) && j<=k(2)
            H(i,j)=P(mejores(i+1),j);   %segunda parte del hijo 1
            H(i+1,j)=P(mejores(i),j);   %segunda parte del hijo 2
        else
            H(i,j)=P(mejores(i),j);     %tercera parte del hijo 1
            H(i+1,j)=P(mejores(i+1),j); %tercera parte del hijo 2
        end
    end
end

u=0; %contador
for i=1:Npob    %Reemplazo por elitismo
    if any(reemplazables==i) %seleciona a los reemplazables para verificar si se cambian
        u=u+1;
        if ~any(ismember(P,H(u,:),'rows')) && sum(H(u,:))<=N+1   %Compara todas las filas de P con el hijo H(u,:), si al menos uno es igual el resultado de any es 1 y con ~ invertimos
            P1(i,:)=H(u,:);
        else
            P1(i,:)=P(i,:);     %si el hijo no cumple los dos requisitos anteriores, se mantiene el "reemplazable"
        end
    else
        P1(i,:)=P(i,:);         
    end
end
end