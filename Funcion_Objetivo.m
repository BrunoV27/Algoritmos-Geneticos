function [FO,ENS,A,B,C,D,d]=Funcion_Objetivo(precio_un,Ce,nodos_con_reconectador,Npob,Li,Ui,pesos_tramos,DEP,FMIK,grafo1,Ntr,cant_ramales)

tramos_importantes=find(pesos_tramos); %ubica los tramos importantes
pesos_tramos(tramos_importantes)=0;    %Eliminamos ese tramo para asignar el/los siguientes en donde si protegen el tramo
for tr=1:length(tramos_importantes)
    auxiliar=successors(grafo1,tramos_importantes(tr)); %Tramos inmediato posterior troncal y derivaciones
    indices=auxiliar <= Ntr-cant_ramales;               %Solo los troncales
    auxiliar=auxiliar(indices);
    pesos_tramos(auxiliar)=1;
end

ENS=zeros(1,Npob); %creamos un vector para cargar 
 for k=1:Npob   
        ENS(k)=dot(Li,Ui(:,:,k));%realiza el producto escalar de Li*Ui
 end
 
a=1;
b=0;    % se supone que se quiere recuperar en 10 años la inversión inicial
c=0.03*ENS; % es el 3% de la CENS
if Ntr==39 %Para ITG3
    d=10^3;
else
    d=10^4; %para ITG 8, ITG 11, ITG 12
end

FO=zeros(1,Npob);
A=zeros(1,Npob);
B=FMIK*d;   %Ya que no consideramos el precio del reco, utilizamos para FIMK que no altera la FO
C=zeros(1,Npob);
D=zeros(1,Npob);
for i=1:Npob
    %k=sum(nodos_con_reconectador(i,:))-1;     %Descontamos el precio de 1 ya que corresponde al interruptor de cabecera
   
    A(i) = a*ENS(i);                                                  %Ce = Costo de ENS $/kWh.
    %B(i) = b*precio_un*k;                                            %precio de instalacion llave telecomandada
    C(i) = -c(i)*sum(nodos_con_reconectador(i,:).*pesos_tramos');     %Reduce en un porcentaje la FO cuando tenemos un tramo importante
    D(i) = d*DEP(i);                                                  %coeficiente de Duracion Equivalente de Potencia
    
    FO(i) = A(i) + C(i) + D(i); %+B(i)
end
end