function ENS_acoples=ens_acoplamientos(cant_mejores_FO,Li,Ui_acoples)
ENS_acoples=zeros(1,cant_mejores_FO,3);

for k=1:cant_mejores_FO
    for m=1:3
        ENS_acoples(1,k,m)=dot(Li,Ui_acoples(:,:,k,m));%realiza el producto escalar de Li*Ui
    end
end
end