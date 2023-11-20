function P=poblacion_aleatoria(Npob,Ntr,N,cant_ramales)
P=zeros(Npob,Ntr);
for i=1:Npob    %recorre por todos los cromosomas
    U=zeros(1,Ntr); %Nuevo cromosoma vacio
    r=randi(N); %cantidad aleatoria de recoectadores entre 1 y N (es un escalar)
    p=randperm(Ntr-cant_ramales-1,r)+ones(1,r); %genera un vector de r terminos, con valores del 2 al 10 que no se pueden repetir
    U(1,[1,p])=1;   %siempre en la cabecera hay un reconectador
   
    while any(ismember(P,U(1,:),'rows'))
        U=zeros(1,Ntr); %Nuevo cromosoma vacio
        r=randi(N); %cantidad aleatoria de recoectadores entre 1 y N (es un escalar)
        p=randperm(Ntr-cant_ramales-1,r)+ones(1,r); %genera un vector de r terminos, con valores del 2 al 10 que no se pueden repetir
        U(1,[1,p])=1;   %siempre en la cabecera hay un reconectador
    end
    P(i,:)=U;
end
end
